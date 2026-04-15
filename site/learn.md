# Learn Claude Code

A hands-on companion to the Spring I/O 2026 talk *Claude Code for Spring Developers* by Thomas Schilling ([Let's connect](https://www.linkedin.com/in/tschuehly/)).

You already heard the pitch. This file turns it into practice.

## How to use this file

1. Open Claude Code in a real Spring project (the one you actually want to improve).
2. Start a session and say:

   > Read `learn.md` and act as my Claude Code tutor.

3. Claude will greet you and offer two modes:
   - **Walkthrough** — step through seven short chapters, with one exercise each.
   - **Q&A** — ask anything. Jump into a chapter when you're ready.

You can switch modes anytime. Interrupt. Skip ahead. Ask "why."

---

## Tutor prompt (for Claude)

```
You are the user's interactive Claude Code tutor. This file, learn.md, is your
curriculum. Your job is to teach a Spring developer how to use Claude Code
effectively in their own project.

Rules of engagement:

1. Greet the learner. Ask if they want the walkthrough or free-form Q&A. Accept
   either. Let them switch anytime.

2. In walkthrough mode, go one chapter at a time (1 → 7). For each chapter:
   a. Summarize the idea in 3-5 sentences.
   b. Point at the concrete bits of their project where it applies. Read files
      if needed. Look at their build tool, package structure, existing docs.
   c. Propose the exercise. Wait for the learner to try it. Offer to do it
      together, not for them.
   d. Debrief: what worked, what friction came up, what rule should they add
      to CLAUDE.md as a result.
   e. Ask "ready for the next chapter?" before moving on.

3. Always answer off-topic questions. Do not force the learner back to the
   curriculum. They heard the talk. They know the shape.

4. Be concrete. When the learner asks "how do I write a skill?", open their
   `.claude/skills/` directory (create it if missing), and write one with them
   based on a real friction point in their project.

5. Do not dump. One idea per turn. Short paragraphs. Ask before writing long
   examples.

6. When the learner hits a real bug, a real convention violation, or a real
   missing piece of context — pause the walkthrough and use it. That is the
   best teaching moment. Add the rule, write the skill, install the hook.

7. Stay honest. If the learner's project does not need a feature (e.g. they
   are solo, worktrees are overkill), say so. Match tools to their situation.

8. Your north star: by the end of the session, the learner has shipped one
   real change to their project using Claude Code, has a CLAUDE.md that
   earned every line, and knows which chapter to revisit next week.

Begin by greeting the learner and offering the two modes.
```

---

# The Curriculum

## Chapter 1 — Setup

**Goal:** Get Claude Code running in your project and make one small, real change.

- Install Claude Code (`npm i -g @anthropic-ai/claude-code`), or use the JetBrains/VS Code plugin.
- `cd` into your Spring project. Run `claude`.
- Pick one small annoyance — a missing validation, a README fix, a flaky test.
- Let Claude run the loop: Read → Plan → Act → Observe.
- Interrupt with Escape if Claude goes the wrong way. Use `/rewind` to undo. Experimentation is free.

**Exercise:** Make one real change. Not a toy. Something you'd ship.

**Debrief:** Where did Claude guess wrong? That guess is a clue for Chapter 2.

---

## Chapter 2 — CLAUDE.md

**Goal:** Onboard Claude to your project the way you onboard a new developer.

Every session is day one for Claude. Context is how you onboard.

Start with **five lines** in `CLAUDE.md` at your project root:

- Your build command (`./gradlew compileKotlin compileTestKotlin` or `./mvnw compile test-compile`)
- Your test command
- The one architectural rule that matters most (e.g. "no in-memory state, use DB checks")
- One convention a newcomer would miss
- A pointer to a file that shows the pattern (`AdvisoryLock.kt`, not an explanation of advisory locks)

Then use Claude and **observe what goes wrong**. Every rule should earn its place through a real failure.

When `CLAUDE.md` gets long, move detail into `.claude/rules/` with path scopes:

```
.claude/rules/
├── kotlin-conventions.md   → src/main/kotlin/**
├── testing.md              → src/test/**
└── payment.md              → src/**/payment/**
```

Package-by-feature maps perfectly to path-scoped rules. Each file loads only when Claude touches matching paths.

**Exercise:** Write your five-line `CLAUDE.md`. Then run the loop from Chapter 1 again. Add one rule based on what went wrong.

---

## Chapter 3 — Workflows

**Goal:** Match the workflow to the task. Not every change needs a nine-phase plan.

Five levels, from most hands-on to most autonomous:

1. **Human in the loop** — describe, watch, redirect. Start here. Build intuition.
2. **Plan mode** — Shift+Tab or let Claude invoke it. Claude proposes, you review before any code.
3. **Spec-driven** — use `/interview` (or your own spec process). Claude asks you the questions a product manager would. Output: a 100-200 line spec. You're the engineer — review it, push back, delete what isn't needed.
4. **Plan file** — convert the spec into a phased plan. Each phase is small, testable, independently shippable.
5. **Ralph loop** — a bash loop that runs `claude -p` on one phase at a time, with a fresh context per phase. Used for long autonomous runs. The day shift is thinking. The night shift is Claude implementing.

The trap at level 4: cross-cutting skills drift out of context. The plan file says "use frontend-design", but by phase 5, Claude has forgotten. Fresh sessions per phase fix this.

**Exercise:** Pick your next real feature. Run `/interview` on it (or ask Claude to interview you). Review the spec. Push back on at least one thing.

---

## Chapter 4 — Skills

**Goal:** Capture the knowledge that currently lives in your senior dev's head.

`CLAUDE.md` is always loaded. Skills are loaded **on demand** — Claude sees the name and description at session start, pulls the body when invoked.

Use `CLAUDE.md` for always-on rules. Use skills for repeatable workflows and reference docs.

A skill is just a markdown file:

```
.claude/skills/commit/SKILL.md
---
name: commit
description: Group uncommitted changes into feature commits.
---
1. Run `git status` and `git diff` to understand all changes
2. Group changed files by logical feature
3. Stage and commit each group with an action-oriented message
4. Repeat until all changes are committed
```

Eight lines. Now every commit follows the same discipline. Skills compound — session 100 benefits from every skill you added in sessions 1-99.

Core skills worth building:
- `/interview` — Claude interviews you before implementation
- `/tdd-task` — strict Red → Green → Refactor
- `/test` — run tests, report failures only
- `/commit` — feature commits, not debugging noise

For reusable JVM skills: [jvmskills.com](https://jvmskills.com).

**Exercise:** Pick one workflow you do manually and inconsistently (commits, test runs, PR reviews). Write a skill for it. Use it tomorrow.

---

## Chapter 5 — Hooks

**Goal:** Turn the rules that matter into guaranteed behavior.

Skills and `CLAUDE.md` can be ignored. Hooks can't — they fire on every tool call.

Four lifecycle events worth knowing:
- `SessionStart` — once, when Claude opens
- `PreToolUse` — before any tool call. Exit 2 = hard block.
- `PostToolUse` — after a tool call. Feed results back to Claude.
- `SessionEnd` — on CLI close

Three patterns that pay for themselves:

1. **Guardrails (PreToolUse + Bash):** block `git push`, `git reset --hard`, `rm -rf`, anything you never want Claude to run.
2. **Convention enforcement (PreToolUse):** "Use the `/test` skill instead of raw `./gradlew test`" — keeps Claude's context clean.
3. **Self-correction loop (PostToolUse + Edit|Write):** run your linter after every edit. Detekt, Checkstyle, ktlint, ESLint. When the linter finds a forbidden import, Claude sees the error and fixes it in the same turn. That mistake can never happen again.

**Anything you can put in a hook, put in a hook.** CLAUDE.md rules drift. Hooks fire every time.

**Exercise:** Add one `PostToolUse` hook that runs your linter on edited files. Watch Claude self-correct.

---

## Chapter 6 — MCP

**Goal:** Give Claude your tools, not just your filesystem.

MCP (Model Context Protocol) is an open standard. Any tool with an MCP server becomes something Claude can call.

Useful servers for Spring devs:

| Server | What you get |
|---|---|
| **JetBrains MCP** | `reformat_file`, `rename`, `execute_run_configuration` — Claude uses IntelliJ the way you do |
| **Linear / Jira** | Read tickets, update status, pick up the next task |
| **Sentry** | Investigate production errors without copying stack traces |
| **JavaDoc Central** | Up-to-date library docs |
| **Spring AI** | Build your own MCP server for internal tools |

MCP alone isn't enough. Claude's default reflex is Bash and sed. Add a `CLAUDE.md` rule:

> Use `mcp__jetbrains__reformat_file` for formatting after editing.

For multi-step workflows, wrap MCP in a skill. A `/restart` skill that stops the app, starts via MCP, waits for readiness, and checks the logs — four steps, every time.

**Exercise:** Install the JetBrains MCP server. Ask Claude to rename a symbol across your project. Watch it use the IDE's refactoring instead of sed.

---

## Chapter 7 — Tips & Tools

**Goal:** The small tools that make the workflow stick day to day.

**Sandbox.** `/sandbox` fences filesystem and network at the OS level. Let Claude run long loops without watching every command. Docker sandboxes go further — microVM isolation, disposable.

**Voice input.** [handy.computer](https://handy.computer) — open source, local, unlimited. Voice is faster than typing. When you speak you think out loud, reconsider, ramble. Claude extracts the intent. Your reasoning chain becomes the prompt.

**Parallel agents.** Worktrunk gives each agent its own git worktree, Postgres instance, LocalStack, and IntelliJ window. Three features, three agents, zero conflicts.

**Clean history.** `/rebase-commit` takes 46 messy debugging commits and squashes them into 10 feature commits — each with its tests, independently reviewable.

**Fresh sessions beat long ones.** Performance degrades as context fills. Resuming a stale session re-reads everything uncached. Wrap up the session in a markdown file. Start fresh tomorrow.

**Get a second opinion.** Different models have different blind spots. Claude finds correctness bugs. Codex finds authorization bugs. Run both on the same branch before shipping risky changes.

**Exercise:** Pick the one tool from this chapter that maps to your biggest daily pain. Install it. Use it for a week.

---

## Where to go next

- **Keep a friction log.** Every time Claude guesses wrong, write it down. That log becomes your next CLAUDE.md rule, skill, or hook.
- **Install one skill a week.** Browse [jvmskills.com](https://jvmskills.com). Start with `/commit` and `/test`.
- **Share what works.** The best skills come from teams, not individuals. Commit your `.claude/` folder to git.
- **Stay curious.** The tooling moves fast. What worked four weeks ago may be outdated. What's best in four months is anyone's guess.

If you're not using Claude Code for your development in 2026, you are seriously missing out.

— Thomas
