---
title: "Five Rounds, One Feature: What Happens When You Add Context to AI Coding"
slug: five-rounds-one-feature
date: 2026-03-28
draft: true
author: Thomas Schilling
description: "I built the same Spring Boot feature 5 times with increasing AI context. Zero tests to 47. Eight fundamental bugs to zero. A 30-cycle compile loop that vanished. Here's what I learned."
skills:
  - database/jooq-best-practices
  - framework/spring-boot-skill
  - testing/test-gradle
tags:
  - experiment
  - context-engineering
  - spring-boot
  - ai-coding
---

I ran an experiment. I built the same Spring Boot feature five times — a photo ranking game for weddings where guests vote on photos from their phones while a beamer displays live results. Same codebase, same AI assistant, same feature prompt. The only variable: how much context I gave the AI.

## The Feature

A "Foto-Ranking Spiel" with four phases: **LOBBY** (guests join via QR code) → **REACTING** (guests browse photos, react with emoji) → **REVEAL** (beamer shows winners with ceremony) → **FINISHED** (final results). Real-time updates via SSE, reaction budgets per emoji type, concurrent-safe voting.

Not a toy example — it touches jOOQ queries, SSE controllers, ViewComponents, Alpine.js interactivity, Playwright E2E tests, and database migrations.

## Round 1: Vibe Coding (Zero Context)

No `CLAUDE.md`. No `/interview` skill to surface design decisions. No `/test` skill to enforce testing. No `/design-postgres-table` skill for schema guidance. Just Claude Code and a feature description.

Claude explored the codebase, wrote a 141-line plan, and started coding. Everything looked normal — until the compile errors hit.

### The Compile Error Loop

Without any project context file, the only durable state was the files on disk. When Claude's context window got compressed during the long session, it forgot its own fixes:

```
⏺ Now Phase 4 - Beamer view components...
⏺ [writes/fixes code]
⏺ Two compile errors. Let me fix them.
⏺ [fixes errors]
⏺ Bash(./gradlew compileKotlin)
  ⎿  Error: Exit code 1
[context compressed — Claude forgets the fix]
⏺ Now Phase 4 - Beamer view components...
```

This repeated **30+ times** over 30 minutes. The same phase, the same errors, the same forgotten fixes. A spec file or CLAUDE.md would have survived the compression — but there was nothing on disk to anchor the context.

### The Result

After 115 minutes of firefighting, the code worked — barely. Here's what it produced.

**A 3-state machine instead of 4.** The migration defined only three states — the REVEAL phase didn't exist:

```sql
CREATE TYPE game_status AS ENUM ('LOBBY', 'PLAYING', 'RESULTS');
```

The game jumps straight from voting to final results. No dramatic reveal, no ceremony. A fundamental requirement was missed because Claude guessed the game flow instead of asking about it.

**A race condition in budget enforcement.** The `addReaction` method checks the budget count and inserts in two separate queries — no lock between them:

```kotlin
fun addReaction(gameId: Long, guestId: Long, submissionId: Long,
                reactionType: ReactionType): Boolean {
    val currentCount = sql.fetchCount(
        GAME_REACTION,
        GAME_REACTION.GAME_ID.eq(gameId)
            .and(GAME_REACTION.GUEST_ID.eq(guestId))
            .and(GAME_REACTION.REACTION_TYPE.eq(reactionType))
    )
    if (currentCount >= REACTION_BUDGET_PER_TYPE) return false

    val inserted = sql.insertInto(GAME_REACTION)
        .set(GAME_REACTION.GAME_ID, gameId)
        .set(GAME_REACTION.GUEST_ID, guestId)
        .set(GAME_REACTION.SUBMISSION_ID, submissionId)
        .set(GAME_REACTION.REACTION_TYPE, reactionType)
        .onConflictDoNothing()
        .execute()
    return inserted > 0
}
```

Two concurrent requests can both pass the `fetchCount` check before either inserts — exceeding the budget. The project's `CLAUDE.md` explicitly requires `AdvisoryLock` for distributed consensus — but without that file, Claude had no way to know.

**Wrong exception handling.** Custom exceptions extended `RuntimeException` instead of the project's `PhotoQuestException` base class, bypassing the centralized error handling. The `CLAUDE.md` documents this convention, but Round 1 had no `CLAUDE.md`.

**And zero tests.** Not a single test file. No integration tests, no E2E tests, nothing. Without the `/test` skill — which runs the test suite, parses failures, and launches subagents to fix them — Claude never attempted to write tests at all.

## Round 2: Interview + Skills

Same feature. But this time: a `CLAUDE.md` documenting project conventions, the `/interview` skill, the `/design-postgres-table` skill, and the `/test` skill.

### Which Skills Fixed What

The **`/interview` skill** asked 20+ design questions across 8 rounds before any code was written — game lifecycle, beamer UX, phone experience, budget rules, edge cases. This is what surfaced the 4-state machine. Round 1's Claude guessed `LOBBY → PLAYING → RESULTS`. Round 2's Claude asked "how many phases?" and got the correct `LOBBY → VOTING → REVEAL → FINISHED`.

The **`CLAUDE.md`** rule — *"Multi-instance safe: use `AdvisoryLock.kt` for distributed consensus"* — told Claude to use `AdvisoryLock` for session creation. Round 1 had no lock at all. The same file documented `PhotoQuestException` as the exception base class, so Round 2 used the correct hierarchy.

The **`/design-postgres-table` skill** guided the schema: `CHECK` constraints on timer duration, partial unique indexes for active sessions, soft-delete via `deleted_at`. Round 1's schema had none of these.

The **`/test` skill** enforced testing — it runs the suite, parses JUnit XML for failures, and launches subagents to fix each one. Round 1 had zero tests. Round 2 produced 37.

### The Implementation

The implementation session took 28 minutes. **First compile: BUILD SUCCESSFUL.** No compile loop. No context amnesia — the spec file survived context compression because it existed as a file on disk, not just in conversation memory.

Claude even self-corrected during coding: it tried to use `S3_FILE.PRESIGNED_URL` which doesn't exist, caught the mistake by searching the jOOQ generated code, and fixed it to `DOWNLOAD_URL` — all without any user input.

- **13 bugs** — all UX polish (button sizing, animation timing), not fundamental
- **37 tests** (24 integration + 13 E2E with Playwright)
- **4-state machine** — correct and complete
- **AdvisoryLock** for session creation — multi-instance safe
- Clean 4-class decomposition: Service, ReactionService, Repository, NotificationService
- Sealed class `RevealStep` with `CategoryTitle` and `PhotoReveal` variants

## Round 3: Live Skill Creation + TDD

Round 3 added a twist: I created the `/spec-to-plan` skill *live during the session* — a skill that converts a feature spec into a phased TDD implementation plan.

The skill went through 4 refinement rounds before it produced the right output format. Then I used it to generate an 8-phase vertical-slice plan and implemented with TDD discipline.

### The Honest Reality

Even with full context, the AI skipped writing tests first 3 times despite the `/fix` skill explicitly requiring TDD RED/GREEN steps. Each time, I corrected it. The corrections compounded — by the later phases, TDD discipline held.

- **8 bugs** — a mix of fundamental and polish
- **23 tests** (20 integration + 3 E2E)
- **29 commits** — small, focused increments
- 2.5 hours total implementation

The key lesson: skills don't make the AI perfect. They make the *corrections* permanent. Every mistake became a skill improvement for the next session.

## Round 4: Pure Planning

Round 4 had zero implementation. The entire session was pre-code planning.

The `/interview` skill — refined from Round 2 — now asked **30 contextual questions across 12 rounds**. Not generic questions: Claude explored the codebase first (49 tool uses) and asked things like "The dock is visible to BOTH managers and guests — should the ranking game link only appear for managers?" It understood the existing code well enough to ask the right questions.

The output: a 258-line spec with 26 user stories and a 232-line TDD implementation plan.

### The Self-Improving Skill Moment

When reviewing the generated plan, I noticed it used generic test bullet points instead of explicit TDD RED/GREEN steps. The `/spec-to-plan` skill — created in Round 3 — had a gap in its template.

So I fixed the skill template itself. Not just the output — the *tool*. Every future plan generated by this skill now enforces TDD by default. This is what compounding returns on context engineering looks like.

## Round 5: Guided Autonomous Agent

Round 5 used Ralph — an autonomous agent that executed one phase at a time with a `/plan-phase` skill containing an explicit checklist. No human corrections during implementation.

Compare the same budget enforcement from Round 1. The `react` method now uses a sealed result type — no exceptions for expected outcomes:

```kotlin
sealed interface ReactResult {
    data object Success : ReactResult
    data object SessionNotReacting : ReactResult
    data object BudgetExhausted : ReactResult
    data object AlreadyReacted : ReactResult
}

@Transactional
fun react(sessionId: Long, participantId: Long,
          submissionId: Long, reactionType: ReactionType): ReactResult {
    val session = sql.selectFrom(RANKING_GAME_SESSION)
        .where(RANKING_GAME_SESSION.ID.eq(sessionId))
        .fetchOne() ?: return ReactResult.SessionNotReacting

    if (session.status != RankingGameStatus.REACTING)
        return ReactResult.SessionNotReacting

    val usedCount = sql.fetchCount(RANKING_GAME_REACTION,
        RANKING_GAME_REACTION.SESSION_ID.eq(sessionId)
            .and(RANKING_GAME_REACTION.PARTICIPANT_ID.eq(participantId))
            .and(RANKING_GAME_REACTION.REACTION_TYPE.eq(reactionType)))
    val budget = when (reactionType) {
        ReactionType.HEART -> session.budgetHeart!!
        ReactionType.FUNNY -> session.budgetFunny!!
        ReactionType.WOW -> session.budgetWow!!
    }
    if (usedCount >= budget) return ReactResult.BudgetExhausted

    val inserted = sql.insertInto(RANKING_GAME_REACTION)
        .set(RANKING_GAME_REACTION.SESSION_ID, sessionId)
        .set(RANKING_GAME_REACTION.PARTICIPANT_ID, participantId)
        .set(RANKING_GAME_REACTION.SUBMISSION_ID, submissionId)
        .set(RANKING_GAME_REACTION.REACTION_TYPE, reactionType)
        .onConflict(/* session, participant, submission, type */)
        .doNothing()
        .execute()

    return if (inserted > 0) ReactResult.Success else ReactResult.AlreadyReacted
}
```

Duplicate prevention via `ON CONFLICT DO NOTHING` + `execute()` return value. Configurable budgets per session instead of a hardcoded constant. Type-safe result instead of a bare `Boolean`.

Session creation uses `AdvisoryLock` — the `/simplify` skill caught this TOCTOU race condition during its automated review:

```kotlin
@Transactional
fun createSession(eventId: Long, ...): RankingGameSessionRecord {
    AdvisoryLock.xact(sql, eventId)  // prevents duplicate sessions across instances
    val active = getActiveSession(eventId)
    if (active != null) throw ActiveSessionExistsException()
    // ... insert
}
```

And every state transition uses `forUpdate()` row locks:

```kotlin
@Transactional
fun startGame(sessionId: Long): RankingGameSessionRecord {
    val session = sql.selectFrom(RANKING_GAME_SESSION)
        .where(RANKING_GAME_SESSION.ID.eq(sessionId))
        .forUpdate()  // row lock — no concurrent state transitions
        .fetchOne() ?: throw IllegalArgumentException("Session not found")

    if (session.status != RankingGameStatus.LOBBY) {
        throw InvalidGameStateException("LOBBY", session.status!!.literal)
    }
    session.status = RankingGameStatus.REACTING
    session.startedAt = OffsetDateTime.now()
    session.store()
    return session
}
```

The **`/simplify` skill** — which runs 3 parallel Explore agents reviewing code for reuse, quality, and efficiency — caught the AdvisoryLock gap automatically. This is what skills do: they encode patterns like "always use AdvisoryLock for distributed consensus" so the AI doesn't have to remember on its own.

The **`/plan-phase` checklist** required running `/test` at the end of every phase — producing 47 tests across 8 phases. No phase could be marked complete without green tests.

### Where Skills Still Fell Short

Not everything was caught. Ralph generated QR codes by calling an external API (`api.qrserver.com`) when the codebase already had `QrCodeUtil.toSvgString()` — a local SVG generator with no external dependency. The `/simplify` skill reviews code quality, but it doesn't check "did you reinvent something that already exists." This led to adding a **"pattern recon" step** to the `/plan-phase` skill: *"Search for existing implementations of the same concept before writing new code."*

Similarly, Ralph built join URLs using the HTTP request's subdomain (which returns `null` on localhost) instead of reading it from the database like the rest of the codebase. Same root cause — no pattern recon.

The final numbers: **0 fundamental bugs, 47 tests** (35 integration + 3 migration + 1 E2E with Playwright), and deterministic tie-breaking via hash for winner calculation.

The tradeoff: a 1106-line monolithic template with a 22-property context class. More tests, but less architectural elegance than Round 2.

## The Full Comparison

| | R1: Vibe | R2: Interview | R3: TDD | R4: Planning | R5: Guided |
|---|---|---|---|---|---|
| **Skills used** | 0 | ~5 | 7 | 2 | 8+ |
| **Bugs** | 8 fundamental | 13 polish | 8 mixed | — | 0 fundamental |
| **Tests** | 0 | 37 | 23 | — | 47 |
| **Compile loops** | 30+ | 0 | 0 | — | 0 |
| **State machine** | 3-state | 4-state | 4-state | 4-state | 4-state |
| **Concurrency** | Race conditions | AdvisoryLock | No locks | No locks | AdvisoryLock + forUpdate() |
| **Duration** | 115 min | ~100 min | ~2.5 hours | ~30 min | — |
| **Quality rank** | 5th (5.0) | **1st (1.7)** | 3rd (2.8) | 4th (3.2) | 2nd (2.5) |

Quality was ranked across 6 dimensions: DB schema, service layer, controllers, ViewComponents, tests, and convention adherence.

## What I Learned

### Each skill eliminates a category of failure

The `/interview` skill eliminated missing requirements (3-state → 4-state). The `CLAUDE.md` rule about `AdvisoryLock` eliminated concurrency bugs. The `/test` skill eliminated untested code. The `/design-postgres-table` skill eliminated missing constraints and indexes. No single skill fixed everything — but together they covered every category of failure from Round 1.

### The interview is the highest-leverage investment

Round 2's `/interview` produced 20+ design decisions that prevented 8 fundamental bugs. The same skill in Round 4 (refined from earlier use) produced 30 contextual questions and 26 user stories. Pre-code planning isn't overhead — it's the fastest path to correct code.

### Skills compound across sessions

Round 3 created `/spec-to-plan`. Round 4 used it and found a gap — no TDD steps. The fix improved the skill template for all future use. Round 5's `/plan-phase` skill was missing a "pattern recon" step — the QR code bug led to adding one. Each session doesn't just build a feature — it builds the *tooling* for the next session.

### More tests doesn't mean better coverage

Round 5 had the most tests (47) but covered 9 out of 16 test scenarios. Round 2 had fewer tests (37) but covered 12 out of 16 scenarios. Breadth matters more than depth — and the interview-driven approach naturally produces broader coverage because user stories map directly to test cases.

### Good dev practices matter MORE with AI, not less

AI amplifies your approach. A disciplined workflow (interview → spec → TDD plan → implementation) produces dramatically better code. A "just let it code" approach produces dramatic bugs. Speed amplifies whatever you point it at — including mistakes.

## Try It Yourself

The skills used in these demos are available in the registry. Install them, give your AI expert context, and see the difference in your own codebase.
