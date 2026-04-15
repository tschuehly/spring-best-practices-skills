# Learn Claude Code

A hands-on companion to the Spring I/O 2026 talk *Claude Code for Spring Developers* by Thomas Schilling ([Let's connect](https://www.linkedin.com/in/tschuehly/)).

You already heard the pitch. This file turns it into practice.

## How to use this file

1. Open Claude Code in a real Spring project (the one you actually want to improve).
2. Start a session and say:

   > Read `learn.md` and act as my Claude Code tutor.

3. Claude will greet you and offer two modes:
   - **Walkthrough** — step through seven short chapters, with exercises each.
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

8. Reference the PhotoQuest stories from the talk when they illustrate a
   point — the 8-bug vibe coding baseline, the missing REVEAL state, the
   A4 vs A6 card layout, the 171-line spec from /interview, the Jackson 2
   ForbiddenImport, the /frontend-design skill drifting out of context.
   These are concrete anchors the learner already knows.

9. Your north star: by the end of the session, the learner has shipped one
   real change to their project using Claude Code, has a CLAUDE.md that
   earned every line, and knows which chapter to revisit next week.

Begin by greeting the learner and offering the two modes.
```

---

# The Curriculum

## Chapter 1 — Setup & the Agentic Loop

**Goal:** Get Claude Code running in your project. Understand the loop. Make one small, real change.

### Why this matters

Claude Code is an agentic coding tool. It operates in a loop:

**Read → Plan → Act → Observe → Repeat.**

You describe what you want. Claude reads your code, makes a plan, edits files, runs commands, checks the results — and keeps going. The loop stops in three ways:

- Claude decides the task is done (sometimes that's true, sometimes it's not).
- You press Escape to interrupt.
- Claude hits a permission prompt and waits for your OK.

Every run is non-deterministic. The same prompt can produce different results each time. That's normal. You learn to work with it.

### Install

```bash
# CLI (primary interface)
npm i -g @anthropic-ai/claude-code

# Or use the JetBrains / VS Code plugin
# Or the desktop app, web app, smartphone app
```

The terminal CLI is where the newest features land first. I spend most of my time there.

### Pick your brain

Claude ships multiple models. Match the model to the task:

| Model  | Best for                                   |
|--------|--------------------------------------------|
| Sonnet | Fast iteration, simple fixes, subagents    |
| Opus   | Architecture, refactors, planning, debugging |
| Haiku  | Quick lookups, headless scripts            |

`/effort low | medium | high | max` controls how deep Claude thinks. My default is Opus with medium effort.

### The safety net

- **Escape** — interrupt whenever Claude goes the wrong direction.
- **`/rewind`** — revert file changes, keep your context window. Experimentation is free.
- **`/branch`** — fork a session to try a different approach without losing context.

These three commands are what make the non-determinism workable. You're never stuck.

### Delegate without losing focus

Heavy research burns through your context window. A subagent runs in its own context — only the summary comes back to you.

> "Use a subagent to analyze how the SSE notification system works in this project, then summarize the findings."

In the PhotoQuest demo: 49 tool calls, 84k tokens of code read, 90 seconds. The main context window stayed clean — only the summary landed there.

### The vibe coding baseline

The first PhotoQuest iteration was pure vibe coding. One prompt, no CLAUDE.md, no skills, no plan. Claude wrote 2000+ lines. Result:

- Zero tests written.
- Eight bugs found by manual testing.
- The entire REVEAL game state silently skipped — the prompt mentioned it, but without a spec, it drifted out of context.

Code alone isn't enough. Claude needs knowledge, skills, and a plan. Chapters 2-7 add each one.

### Exercise

Pick one small, real annoyance in your project:
- A missing validation on a request DTO.
- A `TODO` comment that's been there for months.
- A flaky test you've been ignoring.

Ask Claude to fix it. Watch the loop. Interrupt if it drifts. Use `/rewind` if the diff is wrong. Ship the change.

### Debrief

Where did Claude guess wrong? What convention did it miss? What file did it fail to find?

Write those down. They are the raw material for Chapter 2.

---

## Chapter 2 — CLAUDE.md: Every Session Is Day One

**Goal:** Onboard Claude to your project the way you onboard a new developer.

### Why this matters

A new developer onboards once. Claude onboards **every session**. Context is how you onboard.

You don't hand a new hire the repo and say "good luck." You give them documentation, walk them through the architecture, explain the domain, show them the workflow. `CLAUDE.md` does that — every session, automatically.

The failure mode if you skip this: Claude hardcoded a six-up card layout for PhotoQuest. Reality: one card per A6 page. That fact lived in my head. Never written down. The agent only knows what's in context. You can't blame Claude for missing what you never told it.

### Start with five lines

Don't write a giant file on day one. Start minimal:

```markdown
# Project: <your project name>

## Commands
- Build: ./gradlew compileKotlin compileTestKotlin
- Test: ./gradlew test

## Critical rules
- Verify before done: run tests before marking a task complete.
- No in-memory state for dedup or guards — use DB checks. See AdvisoryLock.kt.
```

Five lines. That's it. Then use Claude and observe what goes wrong.

### Iterate by friction

The loop:

1. Start with five lines.
2. Use Claude Code.
3. Undesired behavior → add a rule.
4. Repeat.

Every rule must earn its place through a **real failure**. If you can't name the failure, you don't need the rule.

### Three rules that earned their place

From the actual PhotoQuest CLAUDE.md, after months of this cycle:

```markdown
- Compile after .kt changes:
  ./gradlew compileKotlin compileTestKotlin
```

Fast feedback lets Claude self-correct. The build runs in seconds. Errors become the next turn's input.

```markdown
- Verify before done: never mark a task complete without
  proving it works (run tests, demonstrate correctness)
```

This rule exists because Claude used to declare victory too early. The vibe-coding baseline is exactly this failure.

```markdown
- Multi-instance safe: no in-memory state for dedup/guards;
  use DB checks. AdvisoryLock.kt for distributed consensus
```

An architecture rule Claude cannot deduce from the code. Notice the **pointer**: `AdvisoryLock.kt`. The rule doesn't explain advisory locks. It points at the file that shows the pattern. CLAUDE.md stays short; the knowledge stays accurate.

### Path-scoped rules

When CLAUDE.md grows past 200 lines, move detail into `.claude/rules/`:

```
.claude/rules/
├── kotlin-conventions.md    → src/main/kotlin/**
├── viewcomponent.md         → src/main/kotlin/page/**
├── tailwind-daisyui.md      → src/**/*.html
├── testing.md               → src/test/**
└── payment.md               → src/**/payment/**
```

Each file has a `paths` field in the frontmatter. It loads **only when Claude touches matching paths**. Package-by-feature maps perfectly: auth rules load for the auth package, payment for payment, testing for tests. Claude sees only what's relevant.

### The memory hierarchy

| Layer          | What lives here                     | When it loads          |
|----------------|-------------------------------------|------------------------|
| CLAUDE.md      | Most important rules, commands      | Every session          |
| .claude/rules/ | Path-specific conventions           | When touching paths    |
| Auto-memory    | Personal notes, not in git          | Every session (local)  |

I disable auto-memory. I want everything trackable in git — the whole team benefits from the rules I earned.

### Context management

- `/context` — see where your tokens are going. Debug a bloated CLAUDE.md this way.
- `/compact` — manual compression. I don't use it. Fresh sessions beat compressed ones.
- Why: performance degrades as context fills. Resuming a stale session re-reads everything uncached. One resume can cost more than the whole session before it.

Wrap up sessions manually. Track state in a markdown plan file (`what's done, what's next, key decisions`). Tell Claude to write a continuation prompt. Next session: paste the prompt, pull the plan file into context, fresh attention.

### Exercises

**Quick (15 min):** Write your five-line CLAUDE.md. Commit it.

**Deeper (1 hour):** Run Claude on a real feature. When it guesses wrong, stop. Add the rule that would have prevented the guess. Re-run. Write down every rule you added — that's your friction log.

### Common pitfalls

- **Writing rules before failures.** Every rule without a failure story is noise in the context.
- **Explaining concepts instead of pointing at files.** Point at `AdvisoryLock.kt`; don't write a primer on advisory locks.
- **CLAUDE.md > 500 lines.** Move detail to `.claude/rules/` with path scopes.
- **Including company-confidential info.** CLAUDE.md is checked into git. Treat it like code.

---

## Chapter 3 — Workflows: Match the Approach to the Problem

**Goal:** Learn when to use which workflow. Not every task needs a nine-phase plan.

### Why this matters

A bug fix doesn't need a spec. A complex feature doesn't survive vibe coding. The task decides which tool you reach for.

Five levels. Start at 1. Move up only when the scope demands it.

### Level 1: Human in the Loop

Describe, watch, redirect. Real-time collaboration. You stay in control.

**When to use:** Bug fixes, small features, anything you can verify visually or with a quick test.

**Why start here:** You need this phase to build intuition for how the agent thinks. Jump straight to autonomous agents and you won't understand the failures.

### Level 2: Plan Mode

Claude explores, proposes an approach, you review before any code gets written.

- Shift+Tab to enter plan mode manually.
- Claude often self-invokes plan mode for larger tasks.

**When to use:** Scope is bigger than a single function. You're exploring and prototyping. Requirements are fuzzy and you want to see Claude's proposal first.

**Limit:** You're reacting to Claude's proposal. If the requirements only exist in your head and Claude keeps guessing wrong, move to Level 3.

### Level 3: Spec-Driven Development

You drive the design before any code exists. Claude interviews you like a product manager.

The `/interview` skill (we'll write skills in Chapter 4) does this well. Real output from PhotoQuest: 8 rounds of questions, 20+ explicit design decisions, a 171-line spec.

Example of what the interview catches that you'd miss:

> **Claude:** "You want reactions stored in the database, but the budget tracked client-side via a cookie?"

That question made me think again. I switched to database enforcement before a single line of code was written.

**When to use:** The "what" isn't obvious. Only the "why" is. The feature needs decisions, not just code.

### Review the spec

The interview is the first half. You still review the spec.

Add inline comments (I use `%` as a marker):

```markdown
## Reactions
Each guest gets 3 ❤️ + 3 😂 + 3 😮
% confirm this is the correct cookie name
% can we prompt user to enable fullscreen?
```

Claude reads the file, researches the codebase, answers the questions or proposes changes. In one real session: Claude suggested 10 changes. I asked "explain why each is necessary." Eight were hallucinated urgency. I kept two.

You're still the engineer. Understand each decision. Ask "what's the simplest approach?" Reason about tradeoffs together.

### Level 4: Plan File + The Drift Problem

Convert the spec into a phased plan. Each phase is small, testable, independently shippable.

**The drift problem:** Cross-cutting skills drop out of context as the session grows.

Real example from PhotoQuest iteration 4:

| Skill                | P1  | P2  | P3  | P4  | P5  | P6  | P7  |
|----------------------|-----|-----|-----|-----|-----|-----|-----|
| `/frontend-design`   | ✓   | ✗   | ✗   | ✗   | ✗   | ✗   | ✗   |
| `agent-browser`      | ✓   | ✓   | ✓   | ✗   | ✗   | ✗   | ✗   |
| `/simplify`          | ✗   | ✗   | ✗   | ✗   | ✗   | ✗   | ✗   |

Even though the plan said "use these skills every phase," the agent forgot. The context window buried the checklist. `/simplify` was never used once.

### Level 5: The Ralph Loop

Named after Ralph Wiggum from *The Simpsons* — he doesn't stop, does the same thing over and over, and that's exactly what you want here.

A fresh agent per phase. The plan file is the entire prompt. No drift.

Simplest version — a bash loop:

```bash
while read phase; do
  claude -p "$(cat plan.md)" --resume-phase "$phase"
done < phases.txt
```

> "The day shift is thinking, the night shift is Claude implementing."
> — Matt Pocock

**When to use:** Long autonomous runs. You trust the plan. You trust the hooks (Chapter 5) to catch drift. You want to review the result tomorrow morning, not babysit the keyboard.

**Do not skip here.** Level 5 only works once Chapters 2, 4, and 5 are in place. Without hooks, Ralph amplifies your mistakes at 60 tests per hour.

### Iteration, not perfection

The PhotoQuest `/interview` skill improved across iterations:

- **Iteration 2:** 7 phases, 17 tests, feature was **unreachable** — no nav link. Spec described what the feature does, not how the user gets there.
- **Iteration 3:** Dead-end screens. Users could enter states they couldn't exit.
- **Iteration 4:** 26 user stories, zero missing entry points.

Each iteration I added to the skill: mandatory topics, state transitions, terminal states, user stories first. Same friction loop as CLAUDE.md. Observe failure, improve the skill, repeat.

### Exercises

**Quick (30 min):** Pick your next real feature. Ask Claude to interview you before writing any code. Answer at least 5 rounds of questions. Review the spec. Push back on at least one decision.

**Deeper (half day):** Take the spec → write a phased plan → execute phase by phase → compare against a version you vibe-coded. Count tests, count bugs, count design decisions surfaced.

### Common pitfalls

- **Spec'ing a trivial task.** A one-line bug fix doesn't need an interview. Match the level to the scope.
- **Accepting the first spec.** If it has no question marks in your margin comments, you didn't review it hard enough.
- **Trusting Ralph before you have hooks.** Autonomy amplifies whatever workflow you already have — good and bad.

---

## Chapter 4 — Skills: The Documentation You Should Have Written

**Goal:** Capture the knowledge that currently lives in your senior dev's head.

### Why this matters

If a senior dev wrote down how they approach architecture, git flow, and domain knowledge — that's a skill. Working with an agent forces you to write it down. The agent can't learn from watching. Only from files in the filesystem.

Once written down, new human developers benefit too.

### CLAUDE.md vs Skills

|                  | CLAUDE.md                        | Skill                                       |
|------------------|----------------------------------|---------------------------------------------|
| **Loads**        | Once at session start            | Descriptions at start, body when invoked    |
| **Best for**     | "Always do X" rules              | Reference docs, repeatable workflows        |
| **Context cost** | Always present, drifts attention | Fresh context at the moment of action       |

Keep CLAUDE.md lean with always-on rules. Move detailed knowledge into skills. Skills inject fresh context at the moment of action — they don't fade as the conversation grows.

### A skill is just a markdown file

Full contents of `.claude/skills/commit/SKILL.md` — the one that changed my git history forever:

```markdown
---
name: commit
description: Group uncommitted changes into feature commits.
---
1. Run `git status` and `git diff` to understand all changes
2. Group changed files by logical feature
3. Stage and commit each group with action-oriented message
4. Repeat until all changes are committed
```

Eight lines. Now every change set gets grouped by logical feature with a proper message. And commit messages matter more now — because the agent reads git history too. Claude can quickly find how features evolved and when bugs were introduced.

### Anatomy

- **Frontmatter `name`** — the slash command (`/commit`).
- **Frontmatter `description`** — loaded at session start. This is how Claude decides when to invoke the skill on its own.
- **Body** — your instructions. Steps, constraints, patterns. Load only when invoked.

### Four skills worth building first

| Skill         | What it does                                                       |
|---------------|--------------------------------------------------------------------|
| `/interview`  | AI interviews you before implementation. Output: a spec file.      |
| `/tdd-task`   | Strict TDD. RED → GREEN → REFACTOR. Tracked with TodoWrite.        |
| `/test`       | Run tests, report failures only. Keeps context clean.              |
| `/commit`     | Feature commits, not debugging noise.                              |

These are the disciplines I used to do inconsistently. I skipped tests when rushed. I wrote lazy commit messages to move on. The agent doesn't get rushed. Same discipline every time. That discipline compounds — 1,700+ sessions later, git history is clean and every feature starts with a spec.

### The spec is the highest-leverage artifact

> "If an AI generates code from a spec, the spec is now the highest-leverage artifact for catching errors."
> — Thoughtworks, Deer Valley 2026

Think about your last big feature. 80% of the work happened before any code — talking to stakeholders, making design decisions. If the agent generates code from the spec, that's where errors get caught or sneak in. Invest in the spec.

### Skills evolve with friction

The `/interview` skill was 8 lines in iteration 2:

```markdown
Interview me relentlessly about every aspect.
Use AskUserQuestion tool to ask about anything.
Explore the codebase for code questions.
Write the spec to a file.
```

By iteration 4 it had mandatory topics — because iteration 2 missed nav links and iteration 3 had dead-end screens:

```markdown
## Mandatory interview topics
- Entry points
- User journey start-to-finish
- Edge cases
- State transitions
- Terminal states & dead ends

## Output format
Spec MUST end with User Stories.
Navigation stories come FIRST.
```

The skill grew specific because I hit specific failures. Same friction loop as CLAUDE.md.

### Where to get skills

- **[jvmskills.com](https://jvmskills.com)** — curated JVM ecosystem skills. Expert-authored or reviewed. Each one teaches something Claude doesn't know on its own.
- **Your own `.claude/skills/`** — commit these to git. The team benefits.

### Exercises

**Quick (15 min):** Install the `/commit` skill from jvmskills.com. Use it on your next batch of uncommitted changes. Compare against how you'd normally commit.

**Deeper (1 hour):** Pick one workflow you do manually and inconsistently (test running, PR review, migration checklist). Write a skill for it. Use it tomorrow. Iterate it next week.

### Common pitfalls

- **Skills that repeat training data.** "Use constructor injection" — Claude knows that. Skills should teach what Claude **doesn't** know: your project, your team, your conventions.
- **Long descriptions that are vague.** The description is the trigger. Write it so Claude knows exactly when to invoke.
- **Skills that drift.** Same friction loop as CLAUDE.md — observe failures, improve the skill.

---

## Chapter 5 — Hooks: The Rules That Actually Stick

**Goal:** Turn the rules that matter into guaranteed behavior.

### Why this matters

Claude Code is non-deterministic. Skills and CLAUDE.md can be skipped. Hooks can't — they're wired into the lifecycle. Every tool call from the agent invokes a hook. That's how you turn optional conventions into guaranteed behavior.

Constraints compound. CLAUDE.md rules compound across sessions but can be ignored. Hooks compound **and** they're enforced. Every time.

### Lifecycle events

```
SessionStart → PreToolUse → (tool runs) → PostToolUse → SessionEnd
```

Four hook types:

| Type      | What it does                                      |
|-----------|---------------------------------------------------|
| `command` | Shell script. Most common.                        |
| `http`    | POST to a URL.                                    |
| `prompt`  | Single-turn LLM eval.                             |
| `agent`   | Multi-turn subagent with tool access.             |

### Three patterns that pay for themselves

**1. Pre Tool Use: Hard blocks**

Dangerous commands should never run. Exit code 2 = hard block. Claude cannot proceed.

```bash
# .claude/hooks/git-guardrails.sh
DANGEROUS_PATTERNS=(
  "git push" "git reset --hard"
  "git clean -fd" "git branch -D"
  "git checkout \." "git restore \."
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches '$pattern'" >&2
    exit 2
  fi
done
```

Claude sees `BLOCKED` with a clear reason and adapts the plan.

**2. Pre Tool Use: Convention enforcement**

Not just safety — workflows too. The `/test` skill parses failures and reports only what matters. But if Claude reaches for `./gradlew test` directly, the context fills up with stack traces.

```bash
TEST_PATTERNS=(
  "gradlew test " "gradlew test$"
  "gradlew.*--tests"
)
for pattern in "${TEST_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE -- "$pattern"; then
    deny "Use the /test skill instead"
  fi
done
```

Output when Claude tries to run Gradle directly:

```
⏺ Bash(git stash && ./gradlew test --tests "*LoginTest")
  ⎿  BLOCKED: Use the /test skill instead of
     running gradlew test directly
```

Claude reads the block reason and switches to the skill.

**3. Post Tool Use: The self-correction loop**

The biggest unlock. Run your static analysis after every edit. Failures feed back into Claude's next turn.

Real story from PhotoQuest: Claude wanted to serialize participants to JSON and reached for Jackson 2's `ObjectMapper`. Fine in Boot 3. In Spring Boot 4, Jackson 2 doesn't exist — the app failed to start. Claude then fell back to string concatenation. Not what we want.

The fix — a Detekt (Kotlin's Checkstyle equivalent) rule:

```yaml
# detekt.yml
ForbiddenImport:
  imports:
    - value: 'com.fasterxml.jackson.databind.ObjectMapper'
      reason: 'Use tools.jackson.databind.json.JsonMapper instead (Jackson 3)'
```

Hook Detekt to PostToolUse on `Edit|Write`. Claude imports the wrong ObjectMapper, Detekt catches it, Claude fixes it **in the same turn**. No human needed. That mistake can never happen again.

### Anything you can put in a hook, put in a hook

Skills drift out of context. CLAUDE.md gets buried. **Hooks fire every time.** If you can express a rule as a script, a lint rule, or a check — put it in a hook.

Checklist of things worth automating:
- Formatter after every edit (ktlint, prettier, gofmt).
- Linter (Detekt, ESLint, Checkstyle).
- Compile check after `.kt` / `.java` edits.
- Commit gate — block commits when lint or compile fails.
- Uncommitted-work warning at `SessionEnd`.
- Secret scanner — block pushes of API keys.

### Exercises

**Quick (30 min):** Add a `PostToolUse` hook matching `Edit|Write` that runs your linter on the edited file. Watch Claude self-correct on the next violation.

**Deeper (2 hours):** Add a `PreToolUse` hook for your most dangerous command (`terraform destroy`, `rm -rf`, a production database drop). Test it by asking Claude to do exactly that thing. Verify the block fires.

### Common pitfalls

- **Noisy hooks.** A hook that echoes on every success pollutes Claude's context. Stay quiet unless there's a problem.
- **Hooks that can't fail fast.** A PostToolUse hook that takes 30 seconds tanks your iteration speed. Keep them under 5 seconds or run them async.
- **Blocking without explaining.** Always echo a clear reason to stderr. The block is useless if Claude can't adapt.

---

## Chapter 6 — MCP: Beyond the Terminal

**Goal:** Give Claude your tools, not just your filesystem.

### Why this matters

Hooks handle what Claude does **inside** the codebase. MCP handles everything **outside** — your IDE, your issue tracker, your error monitor, your docs.

MCP (Model Context Protocol) is the open standard for connecting AI to applications. Without it, Claude is limited to shell commands and files on disk. With it, Claude talks to your IDE, Linear, Sentry, your custom internal tools — at runtime.

### Useful servers for Spring devs

| Server              | What it gives you                                                |
|---------------------|------------------------------------------------------------------|
| **JetBrains MCP**   | Reformat, rename, run configurations — IDE actions as API calls  |
| **Linear / Jira**   | Read tickets, update status, pick up the next task               |
| **Sentry**          | Investigate production errors without copying stack traces       |
| **JavaDoc Central** | Up-to-date library docs, resolved from Maven coordinates         |
| **Spring AI**       | MCP server starter — build your own for internal tools           |
| **MCP Steroid**     | Full IntelliJ API: debugger, refactorings, inspections, screenshots |

### Agent Developer Experience

The tools you use every day are now available to the agent. Compare:

**Without MCP:**
- Reformat with `sed`
- Fix imports by hand
- Start the app via Gradle

**With IntelliJ MCP:**
- `reformat_file`
- Auto import optimization
- `execute_run_configuration`

The IDE becomes an API the agent calls. That's Agent Developer Experience. The long-term thesis: the agent is the user, not the developer. Design tools for agents first.

### Wire it up in CLAUDE.md

Claude discovers MCP tools automatically — but the model was trained on Bash and sed. Those are the defaults. A CLAUDE.md rule redirects:

```markdown
## MCP preferences
- Use mcp__jetbrains__reformat_file for formatting after editing
- Use mcp__jetbrains__execute_run_configuration to start the app
- Use mcp__linear for any issue-related task
```

One line per tool. Now Claude picks MCP every time.

### Wrap complex flows in a skill

MCP calls are primitives. Real workflows need sequencing. My `/restart` skill:

```markdown
---
name: restart
description: Restart the Spring Boot application and verify startup.
---
1. Stop old app:    restart-app.sh stop
2. Start via MCP:   mcp__jetbrains__execute_run_configuration
3. Wait for ready:  restart-app.sh wait
4. Check errors:    post-bash-log-check.sh
```

Four steps, every time. The agent can re-run the whole sequence itself.

### Build your own MCP server

Spring AI has an MCP server starter. If your team has an internal tool the agent should reach — a feature-flag system, a deploy dashboard, a custom admin — wrap it in an MCP server. Every agent, every session, every developer now has access.

### Exercises

**Quick (20 min):** Install the JetBrains MCP server. Ask Claude to rename a symbol across your project. Watch it use the IDE's refactoring instead of sed.

**Deeper (half day):** Connect your issue tracker (Linear, Jira, GitHub Issues). Ask Claude to read a ticket, ask clarifying questions, and open a PR that resolves it.

### Common pitfalls

- **Assuming Claude will pick MCP.** Default reflex is Bash. Write the rule.
- **Installing every MCP server.** Each one costs tokens in every session. Install only what you use.
- **Not logging MCP traffic.** When something goes wrong, you want to see the calls.

---

## Chapter 7 — Tips & Tools

**Goal:** The small tools that make the workflow stick day to day.

### Sandbox

`/sandbox` fences the filesystem and network at the OS level — Seatbelt on macOS, Bubblewrap on Linux. Writes are locked to your project directory. Network is locked to approved domains (mine allows only Maven Central, Gradle, and GitHub).

This is the single biggest reason I let Claude run long autonomous loops without watching every command. Auto-allow kills permission prompts without sacrificing safety.

Docker sandboxes go further. Each agent runs in a dedicated microVM. Disposable — delete and respawn in seconds. Survives a rogue agent.

### Voice input

[**handy.computer**](https://handy.computer) — open source, runs locally, no usage limits.

Why voice:
- **Faster than typing** — especially for planning, reviews, brainstorming.
- **Claude extracts the intent** from rambling speech. Go back, reconsider, contradict yourself — the agent handles it.
- **Speaking exposes your reasoning.** When I type I'm lazy. When I speak I think out loud. Claude sees the reasoning chain, not the polished prompt.

Try it for a day. Most developers don't go back.

### Parallel agents with Worktrunk

When you want to run multiple agents in parallel, each one needs its own environment. Worktrunk automates the whole stack:

| Component  | What Worktrunk provisions              |
|------------|-----------------------------------------|
| branch     | New git branch                          |
| worktree   | Isolated working directory              |
| Postgres   | Dedicated instance (deterministic port) |
| LocalStack | Dedicated S3 + email                    |
| IntelliJ   | Opens on the branch                     |
| Claude     | Runs in this shell                      |

Three agents on three features. Zero conflicts. When done, one command squashes, rebases, and tears everything down.

Solo dev with one feature at a time? You don't need this yet. Note it for when you do.

### Clean history with `/rebase-commit`

Human-in-the-loop sessions produce commit noise — "fix compile," "fix again," "revert," "retry." The `/rebase-commit` skill rebases unpushed commits into clean feature commits.

Real numbers: **46 debugging commits → 10 feature commits**. Each commit contains a feature and its tests. Reviewers see features, not noise.

### Fresh sessions beat long ones

I don't use `/compact`. I even disable auto-compact. Why:

- Even with a million tokens, performance degrades past a threshold.
- Resuming a stale session re-reads everything uncached. The prompt cache expires in 5 minutes. One resume can cost more than the whole session before it.

Instead:
1. Track state in a markdown plan file.
2. Wrap up sessions manually when they get long.
3. Tell Claude to summarize progress and write a continuation prompt.
4. Next session: paste the prompt, pull the plan file into context, fresh attention.

### Get a second opinion

Different models have different blind spots. On one real PhotoQuest review:

| Claude found                              | Codex found                             |
|-------------------------------------------|-----------------------------------------|
| Timer hangs if beamer tab closes          | Manager controls exposed to guests      |
| Guest never redirected on finish          | Script injection in lobby guest list    |
| Race condition in budget check            | Race condition in budget check          |

Claude went deep on correctness and concurrency. Codex went deep on authorization. One overlap. Everything else different.

Run a second agent (Codex, Gemini, whichever you have access to) before shipping risky changes. Different tools, different blind spots. Still review every line yourself.

### Exercises

**Quick (15 min):** Enable `/sandbox`. Run a long task. Notice how many permission prompts you don't see.

**Quick (1 day):** Install handy.computer. Use voice for a full day of prompts. Compare the shape of your prompts before and after.

**Deeper (one feature):** Ship a feature via the Ralph loop overnight. Run `/rebase-commit` in the morning. Review the result. Did the hooks catch everything?

### Common pitfalls

- **Voice without a reviewing loop.** Rambling prompts need a review pass before they become specs.
- **Worktrunk on a solo project with one task.** Overkill. Use a single branch.
- **Skipping sandbox to "move faster."** The sandbox is what makes autonomous loops safe enough to leave running.

---

## Where to go from here

### Your first week

- **Day 1:** Five-line CLAUDE.md. Run Claude on one real annoyance. Start a friction log.
- **Day 2:** Install `/commit` and `/test` from jvmskills.com. Use them.
- **Day 3:** Add one PostToolUse hook for your linter.
- **Day 4:** Run `/interview` on your next feature. Review the spec.
- **Day 5:** Install one MCP server (start with JetBrains or your issue tracker).
- **Weekend:** Read back the friction log. Promote the best three entries into CLAUDE.md rules or new skills.

### Build the loop that compounds

- Every time Claude guesses wrong → a line in the friction log.
- Every recurring friction → a new rule, skill, or hook.
- Every rule, skill, or hook → committed to git so the team benefits.

Session 100 benefits from every rule added in sessions 1 through 99. That's compounding engineering.

### Further reading

- **[Claude Code docs](https://code.claude.com/docs)** — ground truth for every feature.
- **[Anthropic skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)** — reread every few skills.
- **[jvmskills.com](https://jvmskills.com)** — curated JVM skills, evals, benchmarks.
- **Matt Pocock on the Ralph loop** — [aihero.dev](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum).
- **[Spring I/O 2026 talk slides](https://jvmskills.com/spring-io-2026/slides/)** — the talk you just heard.

### Stay current

The tooling moves fast. What worked four weeks ago may be outdated. What's best in four months is anyone's guess. Keep a small experiment running. Compare what ships. Discard what doesn't compound.

If you're not using Claude Code for your development in 2026, you are seriously missing out.

— Thomas
