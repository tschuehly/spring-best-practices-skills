---
title: "Spring I/O 2026 Takeaways — Every Tool, Skill, and Workflow From My Talk"
slug: spring-io-2026
date: 2026-04-13
draft: true
author: Thomas Schilling
description: "If you just saw my Claude Code for Spring Developers talk, this post has everything I showed — the CLAUDE.md template, skills, hooks, MCP servers, TaskCreate TDD pattern, Worktrunk, and the full toolbelt."
skills:
  - testing/test-gradle
  - framework/restart-spring-boot
  - framework/spring-boot-skill
  - database/jooq-best-practices
  - workflow/interview
  - workflow/spec
  - testing/tdd-task
  - web/frontend-design
  - tool/agent-browser
tags:
  - spring-io
  - claude-code
  - spring-boot
  - ai-coding
  - conference-talk
---

Thanks for coming to [Claude Code for Spring Developers](https://2026.springio.net/sessions/claude-code-for-spring-developers/) at Spring I/O 2026. This post collects every tool, skill, workflow, and link I showed on stage so you can go home and try them on your own codebase.

> **TODO post-talk:** add session recording link, photo, and any audience Q&A worth pinning.

## CLAUDE.md — The Root of Everything

The file Claude reads before every session. Mine for PhotoQuest lives in the repo:

- [PhotoQuest/CLAUDE.md](https://github.com/tschuehly/PhotoQuest/blob/main/CLAUDE.md) — full file, Spring Boot 4 + Kotlin 2.3 + jOOQ
- [Orchestrator/CLAUDE.md](https://github.com/tschuehly/Orchestrator/blob/main/CLAUDE.md) — cross-project rules (the four-repo setup)

> **TODO:** excerpt the 3 sections I highlighted on stage (package-by-feature, build commands, the "don't use `it` for Claude" rule).

## Skills I Use Every Day

Every skill below has a SKILL.md you can drop into `.claude/skills/` and start using today.

**Workflow**

- [interview](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/interview/SKILL.md) — turn a vague idea into a spec by getting interviewed
- [spec](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/spec/SKILL.md) — write the requirements doc Claude will implement against
- [commit](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/commit/SKILL.md) + [rebase-commit](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/rebase-commit/SKILL.md)

**Testing**

- [test-gradle](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/test-gradle/SKILL.md) — run tests headless, return only failing output
- [tdd-task](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/tdd-task/SKILL.md) — the RED → GREEN → REFACTOR pattern with TaskCreate
- [coverage-kover-gradle](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/coverage-kover-gradle/SKILL.md)
- [ui-review](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/ui-review/SKILL.md)

**Framework**

- [restart-spring-boot](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/restart-spring-boot/SKILL.md) — IntelliJ run config + wait-for-ready
- [jooq-best-practices](https://github.com/tschuehly/jvm-skills/blob/main/.claude/skills/jooq-best-practices/SKILL.md)

**External (not jvm-skills, but I use them)**

- [frontend-design](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md) — Anthropic's design system skill
- [agent-browser](https://github.com/vercel-labs/agent-browser) — Vercel Labs browser automation for agents

Full curated list: the [jvm-skills registry](https://github.com/tschuehly/jvm-skills).

> **TODO:** pick the 3 skills I demoed live and mark them; the rest go in a collapsed "Also useful" section.

## Hooks — Closing the Loop

The thing CLAUDE.md can't do: enforce standards on every tool call, even when Claude forgets.

- PreToolUse / PostToolUse / SessionStart — what I used on stage
- [Hooks docs](https://docs.claude.com/en/docs/claude-code/hooks)

> **TODO:** paste the PhotoQuest `.claude/settings.local.json` hook example from the slide. Also the Kotlin error-scan hook.

## MCP — Connect External Tools

Model Context Protocol lets Claude talk to your IDE, database, monitoring, docs.

What I have connected in PhotoQuest:

- **JetBrains MCP** — [JetBrains/mcpjetbrains](https://github.com/JetBrains/mcpjetbrains) — inspections, run configs, symbol search
- **Context7** — [upstash/context7](https://github.com/upstash/context7) — up-to-date docs for HTMX, Tailwind, Alpine.js
- **Sentry MCP** — [sentry.io](https://sentry.io) — search issues from Claude Code
- **Claude in Chrome** — [nichochar/claude-in-chrome](https://github.com/nichochar/claude-in-chrome)
- **jvm-diagnostics-mcp** — [brunoborges/jvm-diagnostics-mcp](https://github.com/brunoborges/jvm-diagnostics-mcp)

## TaskCreate — From Checklist to Contract

The single biggest workflow upgrade since the talk I gave last year. Replace flat markdown checklists with `TaskCreate("…")` — every task becomes tracked state in the UI instead of prose Claude can lie about.

> **TODO:** copy the 7.9 slide's before/after table here. 5 integration bugs → 1 bug, 60 tests. Link the demo recording when the session video lands.

## Worktrunk — Parallel Agents, Zero Conflicts

One branch = one fully isolated dev environment. New git branch, new worktree, new Postgres DB, new LocalStack, new IntelliJ window, own Claude session.

- [worktrunk on GitHub](https://github.com/max-sixty/worktrunk)
- The three-agent demo from the talk showed this scaling to three concurrent Claude sessions with no merge conflicts.

> **TODO:** paste the annotated chain from slide 8.4 (branch → worktree → Postgres → LocalStack → IntelliJ → Claude).

## My Full Toolbelt

Everything in my setup, beyond the headline items above.

**One small favour**

I'm currently looking for what comes next — senior backend or full-stack roles (Spring Boot, Kotlin, Java), remote or Stuttgart area. If you know a team that values building great products, or you'd just like to help, a repost of [my LinkedIn post](https://www.linkedin.com/feed/update/urn:li:activity:7449345368086990848/) means a lot.

**Plugins**

- [double-shot-latte](https://github.com/obra/double-shot-latte) — auto-continues Claude when it stops early
- [claude-notifications-go](https://github.com/777genius/claude-notifications-go) — desktop notifications
- [code-simplifier](https://github.com/anthropics/claude-plugins-official) — review-and-simplify pass on recent changes
- [review-loop](https://github.com/tschuehly/claude-review-loop) — independent code review with a second model
- [linear](https://github.com/anthropics/claude-plugins-official) — Linear issue integration

**Skill ecosystems worth browsing**

- [Playbooks.com](https://playbooks.com)
- [skills.sh](https://skills.sh) (Vercel Labs)
- [Tessl](https://tessl.io)

**Patterns I borrow from**

- [Superpowers](https://github.com/obra/superpowers) — TDD-first, subagent-per-task
- [Compound Engineering Plugin](https://github.com/EveryInc/compound-engineering-plugin)

## Reading List

> **TODO:** pull the exact papers/blogs I cited on stage. Starting list:
>
> - Anthropic hooks docs
> - Anthropic agent skills docs
> - MCP spec
> - The Ralph Wiggum workflow post that named the pattern

## Questions?

> **TODO:** Twitter/LinkedIn/email, post-talk.

Thanks again for coming. If you try one of these on a real Spring codebase and it breaks in an interesting way, I want to hear about it.
