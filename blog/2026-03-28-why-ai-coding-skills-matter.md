---
title: "Introducing jvm-skills: AI Coding Skills from the Engineers Who Build the JVM Ecosystem"
slug: introducing-jvm-skills
date: 2026-03-29
author: Thomas Schilling
description: "General skill directories exist, but their most popular JVM skills are surprisingly shallow. jvm-skills is a curated directory where every skill teaches the AI something it wouldn't know on its own — written by the engineers who build Spring Boot, jOOQ, and more."
skills:
  - database/jooq-best-practices
  - framework/spring-boot-skill
tags:
  - announcement
  - vision
  - ai-coding
  - skills
---

AI coding assistants are changing how we write software. Claude Code, Codex, Cursor — they can generate entire features, refactor complex code, and explain unfamiliar codebases in seconds. But there's a gap that becomes obvious the moment you work with specialized JVM libraries.

## The Context Gap

I built the same Spring Boot feature with and without skills — a photo ranking game where wedding guests vote on photos with emoji reactions. Without context, the AI defined the game as three states: `LOBBY → PLAYING → RESULTS`. It missed the REVEAL phase entirely — an entire feature requirement, gone because the AI guessed the game flow instead of asking.

With an `/interview` skill, the AI asked about game lifecycle *before writing any code*: "How many phases? What triggers each transition?" That one question surfaced the 4-state design (`LOBBY → REACTING → REVEAL → FINISHED`) and prevented the bug from ever existing. Same AI, same feature — different context.

That's just one example. Without context, the AI also shipped a race condition in budget enforcement, skipped the project's `AdvisoryLock` pattern, used the wrong exception base class, and produced zero tests. With skills: correct concurrency, proper error modeling, and 37 tests.

The AI wasn't broken. It was missing **context** — the kind that comes from years of experience working with the JVM and knowing which patterns work.

## What Are AI Coding Skills?

Skills are curated knowledge files that plug directly into your AI coding tool. They're Markdown files that live in your project (typically `.claude/skills/`) and give your AI assistant expert-level context about your specific technology stack.

A skill isn't a tutorial or a reference manual. It's a set of **opinionated best practices** — the kind of guidance a senior engineer with 3+ years on a specific technology would give you during code review.

For example, the [jOOQ Best Practices](https://github.com/jvm-skills/jvm-skills/blob/main/.claude/skills/jooq-best-practices/SKILL.md) skill teaches your AI:

- Use `MULTISET` for nested collections instead of joining and mapping manually
- Prefer `EXISTS` over `COUNT(*)` for existence checks
- Map to Kotlin data classes, not Java beans
- Use window functions instead of correlated subqueries
- Avoid common anti-patterns the jOOQ team has documented

Once installed, every query your AI writes follows these patterns. No more reviewing generated code for subtle mistakes.

## Why a JVM-Specific Directory?

General skill directories exist, but they're not focused on a specific ecosystem — and many top-installed skills are surprisingly shallow. The most popular Spring Boot skill on skills.sh has 9.8K installs and its content is "use constructor injection", "use `@Transactional`", "use `@SpringBootTest`". Things every LLM already knows without a skill.

That's why I built jvm-skills — a curated directory of expert-authored AI coding skills dedicated to the JVM ecosystem. **Every skill teaches the AI something it wouldn't know on its own.**

17 skills across 7 categories at launch, with skills from Julien Dubois, Bruno Borges, Siva Prasad Reddy K, Piotr Minkowski, Timescale, and more. Covering database design, Spring Boot scaffolding, agentic debugging, TDD workflows, frontend design, and code quality patterns.

## The Vision: Where We're Going

The registry is the starting point. Here's what we're building:

### One-liner Bootstrap

```bash
curl -fsSL jvmskills.com/install | sh
```

A CLI tool that auto-detects your stack from your build files (Gradle, Maven), picks matching skills, and installs them. Detect jOOQ + Kotlin + PostgreSQL? You get exactly the right skills — no manual setup.

### Compose, Don't Duplicate

Instead of maintaining separate skills for every language and database combination, skills compose from layers:

```
Base skill (SKILL.md)            — Universal patterns
  + Language overlay (kotlin.md) — Kotlin-specific idioms
  + Database overlay (postgres.md) — PostgreSQL-specific patterns
```

The tooling detects your stack and assembles only the overlays that apply. You get a skill tailored to your exact combination without anyone having to maintain every permutation.

### Agents That Tailor Skills to Your Codebase

Generic skills teach universal best practices — but your project has its own base classes, exception hierarchies, and naming conventions. A tailoring agent bridges that gap. After installing skills, it scans your codebase and enriches each skill with project-specific context.

Your project has an `AbstractJooqRepository<T>` that all repositories extend? The agent picks that up and tells the jOOQ skill to use it. You have a `NotFoundException` → `ConflictException` exception hierarchy? The agent tells the Spring skill to throw those instead of generic `ResponseStatusException`. Your DTOs live in `*.dto` packages with a `toDto()` extension pattern? The agent documents that convention so every generated query follows it.

The result: skills that don't just know jOOQ best practices — they know *your project's* jOOQ patterns. Same expert guidance, but with your base classes as the examples and your conventions as the rules.

### Every AI Tool

Claude Code is the first target, but the architecture supports compiling the same skill content to Cursor (`.cursorrules`), Copilot (`.github/copilot-instructions.md`), Windsurf, Aider, and Codex formats. One source of truth, every editor.

### The Incubator Model

Skills start in the jvm-skills repo where they can be reviewed and refined. When a library maintainer decides to adopt their skill, it graduates to their own repository. The registry simply points to the new location. This creates a clear path from community contribution to official, maintainer-backed guidance.

## Get Involved

**Use skills.** Browse the registry, find skills for your stack, and install them. The best feedback comes from daily use.

**Contribute skills.** If you're an expert in a JVM library, your knowledge is exactly what AI tools are missing. Fork the repo, add a YAML file for your skill, and open a PR. The bar: *"Would a senior engineer with 3+ years on this technology agree on this context?"*

**Spread the word.** The more developers who use skills, the better AI-generated JVM code becomes for everyone.

Check out the source at [github.com/jvm-skills/jvm-skills](https://github.com/jvm-skills/jvm-skills).
