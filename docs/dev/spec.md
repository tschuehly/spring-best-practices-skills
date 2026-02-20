# spring-skills — Technical Specification

## Overview

**spring-skills** is an open-source tool that auto-detects a Spring project's technology stack from build files and bootstraps curated, opinionated best-practice skills for Claude Code. It is **not** a Gradle/Maven plugin — it's a lightweight shell script + Claude Code slash commands, distributed via a `curl` one-liner.

The tool follows a deterministic-first philosophy: a shell script handles parsing, fetching, and file generation for the happy path (empty project). Claude is only invoked when file-level conflicts require human judgment.

---

## Core Principles

1. **Strongly opinionated.** Skills state "do X, don't do Y." If you disagree, edit your local copy.
2. **Tooling first, skills second.** v1 proves the distribution model works with 1-2 reference skills. The skill catalog grows over time.
3. **Incubator model.** Community skills start in the spring-skills repo. When a tool maker (e.g., Lukas Eder for jOOQ, casid for JTE) adopts a skill, it moves to their repo and the registry points there.
4. **Generate once, then hands-off.** The tool never overwrites files it previously generated. Users own their local copies. A separate `/spring-update` command handles explicit updates.
5. **Commit everything.** All generated `.claude/` content is committed to git so the team shares the same AI context.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  curl one-liner (bootstrap)                             │
│  Downloads: install.sh → runs spring-skills init        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Shell Script (deterministic)                           │
│                                                         │
│  1. Parse build.gradle.kts / pom.xml (grep/regex)       │
│  2. Fetch registry.yml from GitHub                      │
│  3. Match detected deps → skills                        │
│  4. Present checklist, user confirms                    │
│  5. Fetch skill directories from GitHub                 │
│  6. Generate all files from templates                   │
│  7. If file conflicts → hand off to Claude              │
└────────────────────┬────────────────────────────────────┘
                     │ (conflict path only)
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Claude Code (interactive conflict resolution)          │
│                                                         │
│  - Existing CLAUDE.md? Merge or replace?                │
│  - Existing skills? Keep, update, or replace?           │
│  - Resolve via /spring-init slash command                │
└─────────────────────────────────────────────────────────┘
```

### What the tool is NOT

- **Not a Gradle plugin.** No build tool coupling, no JVM dependency for the tool itself, no plugin portal publishing.
- **Not multi-AI-tool.** Claude Code only. No .cursorrules or .windsurfrules generation.
- **Not an AI-powered parser.** Dependency detection is deterministic shell script (grep/regex), not LLM inference.

---

## Bootstrap Flow

### One-liner install

```bash
curl -fsSL https://raw.githubusercontent.com/tschuehly/spring-skills/main/install.sh | sh
```

This script:
1. Downloads the `spring-skills` shell script to a temporary location
2. Downloads the `/spring-init` and `/spring-update` Claude Code command files
3. Runs `spring-skills init` immediately (smart bootstrap — the user goes through setup in one step)

### What `spring-skills init` does

```
$ spring-skills init

Scanning build.gradle.kts...

Detected stack:
  Language:     Kotlin (kotlin-jvm 2.0.0)
  Spring Boot:  3.3.0
  Database:     PostgreSQL
  Data access:  jOOQ
  Templates:    JTE
  Migrations:   Flyway

Fetching skill registry...

Available skills for your stack:
  [x] jooq-best-practices-kotlin   (bundled — tschuehly/spring-skills)
  [x] design-postgres-tables       (expert — timescale/pg-aiguide)
  [x] spring-flyway                (bundled — tschuehly/spring-skills)
  [x] spring-jte-kotlin            (bundled — tschuehly/spring-skills)
  [x] spring-style                 (bundled — always active)
  [ ] spring-security              (bundled — tschuehly/spring-skills)

Enable compound engineering? (Y/n)
  This will add review agents and workflow commands
  (forked from compound-engineering-plugin)

Confirm selection? (Y/n)

Fetching skills...
  ✓ jooq-best-practices-kotlin   @ v1.2.0 (sha: abc1234)
  ✓ design-postgres-tables       @ v2.0.1 (sha: def5678)
  ✓ spring-flyway                @ v1.0.0 (sha: ghi9012)
  ✓ spring-jte-kotlin            @ v1.0.0 (sha: jkl3456)
  ✓ spring-style                 @ v1.0.0 (sha: mno7890)

Generating files...
  ✓ .claude/skills/jooq-best-practices-kotlin/
  ✓ .claude/skills/design-postgres-tables/
  ✓ .claude/skills/spring-flyway/
  ✓ .claude/skills/spring-jte-kotlin/
  ✓ .claude/skills/spring-style/
  ✓ .claude/skill-sources.yml
  ✓ CLAUDE.md
  ✓ .claude/agents/spring-reviewer.md
  ✓ .claude/agents/jooq-reviewer.md
  ✓ .claude/commands/spring-init.md
  ✓ .claude/commands/spring-update.md

Done. Your project is set up with 5 skills, 2 agents, and 2 commands.
Run `/review` in Claude Code to start a compound review cycle.
```

---

## Dependency Detection

### Parser: grep/regex on build files

The shell script uses grep/regex patterns to extract declared dependencies from:
- `build.gradle.kts` — `implementation("group:artifact:version")`, `implementation("group:artifact")`, Kotlin DSL variants
- `build.gradle` — Groovy DSL variants
- `pom.xml` — `<groupId>` + `<artifactId>` within `<dependency>` blocks
- `libs.versions.toml` — version catalog entries (parse `[libraries]` section)

**Detection depth: declared dependencies only.** No transitive resolution, no running Gradle/Maven. This keeps the tool fast and requires no working build.

### What gets detected

| Category | Detected From | Example Dependency |
|----------|--------------|-------------------|
| Language | Plugin block / `<packaging>` | `kotlin("jvm")`, `<packaging>jar</packaging>` |
| Spring Boot version | Plugin/parent | `org.springframework.boot` version |
| Database | Driver dependency | `org.postgresql:postgresql`, `mysql:mysql-connector-java` |
| Data access | ORM/DSL dependency | `org.jooq:jooq`, `spring-boot-starter-data-jpa` |
| Templates | View engine dependency | `gg.jte:jte-spring-boot-starter-3`, `spring-boot-starter-thymeleaf` |
| Migrations | Migration tool dependency | `org.flywaydb:flyway-core`, `org.liquibase:liquibase-core` |
| Frontend | `package.json` presence | `tailwindcss`, `daisyui`, `htmx.org` |
| Testing | Test dependencies | `org.testcontainers:*`, `spring-boot-starter-test` |

---

## Skill Registry

### Remote registry file

The dependency-to-skill mapping lives in a `registry.yml` file in the spring-skills GitHub repo. The shell script fetches this first, then uses it to determine which skills to offer.

```yaml
# registry.yml — maps dependency coordinates to skill sources
version: 1

skills:
  # Expert-maintained (external repos)
  - name: design-postgres-tables
    description: "Expert PostgreSQL table design from Timescale"
    repo: timescale/pg-aiguide
    path: skills/design-postgres-tables
    ref: v2.0.1
    activatesOn:
      - "org.postgresql:postgresql"
    maintainer: Timescale
    quality: expert

  # Bundled (incubated in spring-skills repo)
  - name: jooq-best-practices-kotlin
    description: "jOOQ DSL best practices for Kotlin + Spring"
    repo: tschuehly/spring-skills
    path: skills/jooq-best-practices-kotlin
    ref: v1.2.0
    activatesOn:
      - "org.jooq:jooq"
    language: kotlin
    maintainer: tschuehly
    quality: bundled

  - name: jooq-best-practices-java
    description: "jOOQ DSL best practices for Java + Spring"
    repo: tschuehly/spring-skills
    path: skills/jooq-best-practices-java
    ref: v1.2.0
    activatesOn:
      - "org.jooq:jooq"
    language: java
    maintainer: tschuehly
    quality: bundled

  - name: spring-style
    description: "Core Spring Boot conventions and patterns"
    repo: tschuehly/spring-skills
    path: skills/spring-style
    ref: v1.0.0
    activatesOn:
      - always  # always offered
    maintainer: tschuehly
    quality: bundled

  # ... more entries
```

### Language-specific variants

Skills that have language-specific content ship as separate variants:
- `jooq-best-practices-kotlin` and `jooq-best-practices-java`
- `spring-jte-kotlin` and `spring-jte-java`

The tool detects the project language (Kotlin plugin present? → Kotlin variant. Otherwise → Java variant) and offers the correct one.

---

## Skill Format

### Plain markdown with minimal frontmatter

Skills are plain `.md` files with minimal YAML frontmatter:

```yaml
---
name: jooq-best-practices-kotlin
description: Comprehensive jOOQ DSL best practices for Kotlin.
  Use when writing jOOQ queries, mapping results, handling transactions,
  or designing repository layers.
---

# jOOQ Best Practices (Kotlin)

## Core rules (always apply)
- Use jOOQ DSL in repository classes, never raw SQL in controllers/services
- Map results to Kotlin data classes
...
```

### Skill directory structure

Each skill is a directory containing a `SKILL.md` and optional reference files:

```
skills/jooq-best-practices-kotlin/
├── SKILL.md                          # Main skill file
├── knowledge/                        # Optional deep-dive reference files
│   ├── anti-patterns.md
│   ├── multiset.md
│   └── fetching-mapping.md
└── references/                       # Optional additional references
    └── migration-codegen-loop.md
```

When fetching, the **entire skill directory** is downloaded (not just SKILL.md). This avoids needing to parse relative links.

---

## Versioning & Fetching

### Pin to commit/tag

The `skill-sources.yml` (generated during init) records the exact ref (tag or commit SHA) for each installed skill:

```yaml
# .claude/skill-sources.yml — generated by spring-skills init, user-editable
installed:
  - name: jooq-best-practices-kotlin
    repo: tschuehly/spring-skills
    path: skills/jooq-best-practices-kotlin
    ref: v1.2.0
    sha: abc1234def5678

  - name: design-postgres-tables
    repo: timescale/pg-aiguide
    path: skills/design-postgres-tables
    ref: v2.0.1
    sha: def5678ghi9012

  - name: spring-style
    repo: tschuehly/spring-skills
    path: skills/spring-style
    ref: v1.0.0
    sha: mno7890pqr1234

compound_engineering: true
detected_language: kotlin
detected_spring_version: "3.3.0"
```

### Fetch mechanism: GitHub API

The shell script uses the GitHub API (or raw.githubusercontent.com) to fetch skill directories:
1. Download the directory listing via GitHub Trees API
2. Download each file in the skill directory
3. Write to `.claude/skills/<skill-name>/`

No `git clone` needed. Works without git installed. Respects GitHub API rate limits (unauthenticated: 60 req/hr; authenticated via `GITHUB_TOKEN`: 5000 req/hr).

---

## Generated Output

### Files generated by `spring-skills init`

| File | Purpose | Template-based |
|------|---------|----------------|
| `.claude/skills/<name>/` | Skill directories fetched from GitHub | Fetched, not templated |
| `.claude/skill-sources.yml` | Records installed skills + versions | Generated from selection |
| `CLAUDE.md` | Project-level AI context referencing skills | Template (only if missing) |
| `.claude/agents/spring-reviewer.md` | Core review agent (if compound opted in) | Template |
| `.claude/agents/<tech>-reviewer.md` | Specialized review agents (if compound opted in) | Template per detected tech |
| `.claude/commands/spring-init.md` | Re-runnable init command | Copied from repo |
| `.claude/commands/spring-update.md` | Update command | Copied from repo |

### CLAUDE.md template

Only generated if CLAUDE.md does not already exist:

```markdown
# Project Guidelines

## Technology Stack
- Language: {{language}} {{version}}
- Framework: Spring Boot {{spring_version}}
- Database: {{database}}
- Data Access: {{data_access}}
- Templates: {{template_engine}}
- Migrations: {{migration_tool}}

## Active Skills
The following skills are installed in `.claude/skills/` and provide
best-practice guidance for this project's stack:

{{#each skills}}
- **{{name}}** — {{description}}
{{/each}}

## Code Conventions
<!-- Add your team's specific conventions here -->
```

### Agent templates (compound engineering)

Two-tier agent generation:

**Core agent (always generated if compound is opted in):**
- `spring-reviewer.md` — Reviews for core Spring patterns: constructor injection, @Transactional placement, controller/service split, error handling, package structure.

**Specialized agents (generated per detected technology):**
- `jooq-reviewer.md` — Reviews jOOQ usage against the installed jOOQ skill.
- `security-reviewer.md` — Reviews Spring Security config, filter chains, CSRF.
- `migration-reviewer.md` — Reviews migration naming, modified versioned migrations.
- etc.

Each agent references the installed skills:

```markdown
---
name: jooq-reviewer
description: Reviews jOOQ query patterns and repository design.
---

You are a code reviewer specializing in jOOQ with Spring Boot.

Review the code changes against the best practices defined in:
- `.claude/skills/jooq-best-practices-kotlin/SKILL.md`
- `.claude/skills/jooq-best-practices-kotlin/knowledge/anti-patterns.md`

Focus on:
- Type-safe DSL usage (no string SQL, no raw JDBC)
- Proper result mapping to data classes
- Transaction boundary correctness
- SEEK pagination over OFFSET
- EXISTS over COUNT for existence checks
...
```

---

## Compound Engineering Integration

### Fork of compound-engineering-plugin

The compound engineering workflow is based on a **fork of [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin)**. The fork:

1. **Strips Rails-specific content** — removes `dhh-rails-reviewer.md`, `kieran-rails-reviewer.md`, `schema-drift-detector.md`, `dhh-rails-style/` skill directory
2. **Keeps the workflow commands** — `/plan`, `/work`, `/review`, `/compound` (the core value of the fork)
3. **Keeps generic agents** — any non-Rails-specific review agents
4. **Adds Spring-specific agents** — generated from templates based on detected stack
5. **Stays synced with upstream** — periodically merge upstream improvements to the workflow commands

When a user opts into compound engineering during `spring-skills init`, the tool copies the workflow commands and generates Spring-specific agents that reference the installed skills.

---

## Update Flow

### `/spring-update` command

A dedicated Claude Code slash command and shell script for updating skills:

```
$ spring-skills update

Reading .claude/skill-sources.yml...

Checking for updates...
  jooq-best-practices-kotlin  v1.2.0 → v1.3.0  (new: window function patterns)
  design-postgres-tables      v2.0.1 → v2.0.1  (up to date)
  spring-style                v1.0.0 → v1.1.0  (new: ProblemDetail patterns)

Update 2 skills? (Y/n)

⚠ WARNING: This will overwrite your local copies.
  If you've made local edits, back them up first.

Updating...
  ✓ jooq-best-practices-kotlin  → v1.3.0
  ✓ spring-style                → v1.1.0

Updated .claude/skill-sources.yml with new versions.
```

The update command:
1. Reads `.claude/skill-sources.yml` for installed skills and their pinned versions
2. Checks the remote registry for newer versions
3. Shows a diff summary
4. On confirmation, re-fetches the entire skill directory, overwriting local copies
5. Updates the pinned versions in `skill-sources.yml`

---

## Conflict Resolution (Claude Handoff)

When `spring-skills init` encounters **file-level conflicts** (files that already exist and would be overwritten), it stops deterministic execution and prints instructions to use the Claude Code slash command:

```
$ spring-skills init

Scanning build.gradle.kts...
Detected: Kotlin, Spring Boot 3.3.0, PostgreSQL, jOOQ, Flyway

⚠ Conflicts detected:
  - CLAUDE.md already exists
  - .claude/skills/jooq-best-practices-kotlin/ already exists
  - .claude/agents/spring-reviewer.md already exists

Cannot proceed deterministically. Run /spring-init in Claude Code
to resolve conflicts interactively.
```

The `/spring-init` Claude Code slash command then:
1. Reads the detected dependencies (from a temp file the script wrote)
2. Reads the existing conflicting files
3. Asks the user how to handle each conflict (keep existing, replace, merge)
4. Writes the resolved files

---

## Repository Structure

```
spring-skills/                           # tschuehly/spring-skills
├── install.sh                           # Bootstrap script (curl target)
├── spring-skills                        # Main CLI shell script
├── registry.yml                         # Dependency → skill mapping
│
├── skills/                              # Bundled skills (incubator)
│   ├── spring-style/
│   │   └── SKILL.md
│   ├── jooq-best-practices-kotlin/
│   │   ├── SKILL.md
│   │   └── knowledge/
│   ├── jooq-best-practices-java/
│   │   ├── SKILL.md
│   │   └── knowledge/
│   ├── spring-jte-kotlin/
│   │   └── SKILL.md
│   ├── spring-flyway/
│   │   └── SKILL.md
│   └── ...
│
├── templates/                           # Templates for generated files
│   ├── CLAUDE.md.tmpl
│   ├── agents/
│   │   ├── spring-reviewer.md.tmpl
│   │   ├── jooq-reviewer.md.tmpl
│   │   └── ...
│   └── commands/
│       ├── spring-init.md
│       └── spring-update.md
│
├── compound/                            # Forked from EveryInc/compound-engineering-plugin
│   ├── commands/
│   │   ├── plan.md
│   │   ├── work.md
│   │   ├── review.md
│   │   └── compound.md
│   └── agents/
│       └── ... (generic compound agents)
│
├── docs/
│   └── dev/
│       ├── initial-plan.md
│       └── spec.md                      # This file
│
├── CONTRIBUTING.md
├── README.md
└── LICENSE
```

---

## Contribution Model

### Two paths

1. **Practitioners** — Submit a PR to the spring-skills repo with a new skill directory under `skills/`. The bar: "Would a senior engineer who's used this technology for 3+ years agree with every line?"

2. **Tool makers** — Create a skill in your own repo (e.g., `datageekery/jooq-aiguide`). Submit a PR to add it to `registry.yml`. The spring-skills bundled version is removed and the registry points to the expert-maintained version.

### Skill graduation

```
Contributor PR → skills/ in spring-skills repo (bundled)
                        │
                        ▼ (tool maker adopts)
                 Tool maker's repo (expert)
                        │
                        ▼
                 registry.yml updated to point there
                 bundled version removed
```

---

## v1 Scope

### v1: Tooling + reference skills

**Build:**
- `install.sh` bootstrap script
- `spring-skills` CLI (shell script): init, update subcommands
- Dependency detection (grep/regex) for Gradle Kotlin DSL + Maven POM
- `registry.yml` with initial mappings
- GitHub API fetching logic
- Template-based file generation
- Conflict detection with Claude handoff

**Ship with 1-2 polished reference skills:**
- `spring-style` (core Spring conventions — always active)
- `jooq-best-practices-kotlin` (existing, already written)
- Any other skills from the current `.claude/skills/` that are production-ready

**Compound engineering (optional):**
- Forked compound workflow commands
- `spring-reviewer.md` core agent template

### v2+: Skill catalog expansion

- More bundled skills: JTE, Flyway, Kotlin, Tailwind, DaisyUI, JPA, Thymeleaf, Liquibase
- Java variants of existing Kotlin skills
- Outreach to tool makers (Lukas Eder, casid, Wim Deblauwe, Flyway team)
- Specialized review agents
- `libs.versions.toml` parsing
- Groovy Gradle DSL support
- `package.json` frontend detection

---

## Design Decisions Log

| Decision | Chosen | Rationale |
|----------|--------|-----------|
| Runtime | Shell script + Claude slash command | No build tool coupling, zero install, works everywhere |
| Build tool integration | None (standalone) | Gradle plugin was over-engineered for what's needed |
| AI tool support | Claude Code only | Simplifies format, can use Claude-specific features |
| Detection depth | Declared deps only (grep) | Fast, no Gradle/Maven startup, no working build needed |
| Skill format | Plain markdown + YAML frontmatter | Easy for contributors, no new format to learn |
| Versioning | Pin to commit/tag | Deterministic, explicit updates |
| Fetch mechanism | GitHub API | No git dependency, simple HTTP, handles caching |
| Config location | `.claude/skill-sources.yml` | Keeps AI config together, not in build files |
| Overwrite policy | Generate once, hands-off | Respects local edits, explicit update command |
| Skill fetch scope | Entire directory | No link parsing needed, simple and complete |
| Conflict resolution | Deterministic → Claude handoff | Best of both: fast happy path, smart conflict handling |
| Opinions | Strongly opinionated | The whole point — "edit locally if you disagree" |
| Language handling | Separate variants | Perfectly targeted content per language |
| Agent granularity | Two-tier: core + specialized | Core always relevant, specialized only when needed |
| Git strategy | Commit everything | Team consistency, shared AI context |
| Contribution model | Incubator → graduation | Low barrier for contributors, path for tool makers |
| Compound engineering | Fork of EveryInc plugin | Workflow maintained upstream, Spring agents are ours |
| Bootstrap | curl one-liner | Zero dependencies, runs immediately |
| Project name | spring-skills | Simple, descriptive, matches Claude skills concept |
