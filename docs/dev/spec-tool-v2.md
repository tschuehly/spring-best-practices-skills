# jvm-skills — Technical Specification

## Overview

**jvm-skills** is an open-source ecosystem for bootstrapping curated, opinionated best-practice skills into JVM projects
for AI coding tools. It lives at **github.com/jvm-skills/jvm-skills** as a monorepo containing the orchestrator (CLI,
registry, templates) and categorized skill content.

The tool auto-detects a project's technology stack from build files and assembles composed skills (base +
language/database overlays) into the user's AI tool format. v1 targets Claude Code; the architecture supports compiling
to Cursor, Copilot, Windsurf, Aider, and others in future versions.

The tool follows a **deterministic-first philosophy**: a shell script handles parsing, fetching, and file generation for
the happy path (new project, no existing AI config). Claude is only invoked when file-level conflicts require human
judgment.

---

## Core Principles

1. **Strongly opinionated.** Skills state "do X, don't do Y." If you disagree, edit your local copy.
2. **Tooling first, skills second.** v1 proves the distribution model works with 1-2 reference skills. The skill catalog
   grows over time.
3. **Incubator model.** Community skills start in the jvm-skills monorepo. When a tool maker (e.g., Lukas Eder for jOOQ,
   casid for JTE) adopts a skill, it graduates to their repo and the registry points there.
4. **Generate once, then hands-off.** The tool never overwrites files it previously generated. Users own their local
   copies. A separate `jvm-skills update` command handles explicit updates. The changes are given to the AI Agent to
   merge them.
5. **Commit everything.** All generated AI config content is committed to git so the team shares the same AI context.
6. **Compose, don't duplicate.** Skills are composed of base + overlays (language, database).

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  curl one-liner (bootstrap)                              │
│  Downloads: install.sh → runs jvm-skills init            │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│  Shell Script — Init (deterministic)                     │
│                                                          │
│  1. Parse build.gradle.kts / pom.xml (grep/regex)        │
│  2. Fetch registry.yml (dimensions) from GitHub          │
│  3. Walk skills/ tree, read each skill.yaml              │
│  4. Match detected deps → skills (base + overlays)       │
│  5. Present checklist, user confirms                     │
│  6. Fetch skill content (local dirs or external repos)   │
│  7. Assemble base + overlays into skill directories      │
│  8. Generate all files from templates                    │
│  9. If file conflicts → hand off to Claude               │
└────────────────────┬─────────────────────────────────────┘
                     │ (conflict path only)
                     ▼
┌──────────────────────────────────────────────────────────┐
│  Claude Code (interactive conflict resolution)           │
│                                                          │
│  - Existing CLAUDE.md? Merge or replace?                 │
│  - Existing skills? Keep, update, or replace?            │
│  - Resolve via /jvm-init slash command                   │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  Shell Script — Update (deterministic + AI handoff)      │
│                                                          │
│  1. Read .claude/skill-sources.yml                       │
│  2. Check GitHub API for newer versions                  │
│  3. Download old upstream (pinned SHA) + new upstream     │
│  4. Compare local files vs old upstream (3-way diff)     │
│  5. Clean updates (no local edits) → apply directly      │
│  6. Dirty updates → write context to pending-updates/    │
│  7. Hand off to AI agent via /jvm-update slash command   │
└──────────────────────────────────────────────────────────┘
```

### What the tool is NOT

- **Not a Gradle/Maven plugin.** No build tool coupling, no JVM dependency for the tool itself, no plugin portal
  publishing.
- **Not an AI-powered parser.** Dependency detection is deterministic shell script (grep/regex), not LLM inference.
- **Not a new skill format.** Uses Claude's existing SKILL.md format as canonical. Other tool formats are compiled from
  it.

---

## Monorepo Structure

Everything lives in one repo: **github.com/jvm-skills/jvm-skills**

Each skill directory contains a `skill.yaml` manifest declaring its own activation rules, overlays, and metadata.

```
jvm-skills/
├── install.sh                              # Bootstrap script (curl target)
├── jvm-skills                              # Main CLI shell script
├── registry.yml                            # Global overlay dimensions config
│
├── orchestrator/                           # Shared infrastructure
│   ├── templates/                          # Templates for generated files
│   │   ├── CLAUDE.md.tmpl
│   │   ├── agents/
│   │   │   ├── spring-reviewer.md.tmpl
│   │   │   ├── jooq-reviewer.md.tmpl
│   │   │   └── ...
│   │   └── commands/
│   │       ├── jvm-init.md
│   │       └── jvm-update.md
│   └── compound/                           # Forked from EveryInc/compound-engineering-plugin
│       ├── commands/
│       │   ├── plan.md
│       │   ├── work.md
│       │   ├── review.md
│       │   └── compound.md
│       └── agents/
│           └── ... (generic compound agents)
│
├── skills/                                 # All skill content, organized by category
│   ├── database/
│   │   ├── jooq/
│   │   │   ├── skill.yaml                  # Activation rules, overlay list
│   │   │   ├── SKILL.md                    # Base jOOQ skill (language-agnostic patterns)
│   │   │   ├── knowledge/
│   │   │   │   ├── anti-patterns.md
│   │   │   │   ├── multiset.md
│   │   │   │   └── ...
│   │   │   └── overlays/
│   │   │       ├── kotlin.md               # Kotlin-specific jOOQ patterns
│   │   │       ├── java.md                 # Java-specific jOOQ patterns
│   │   │       ├── postgres.md             # PostgreSQL-specific jOOQ patterns
│   │   │       └── mysql.md                # MySQL-specific jOOQ patterns
│   │   ├── jpa/
│   │   │   ├── skill.yaml
│   │   │   ├── SKILL.md
│   │   │   └── overlays/
│   │   │       ├── kotlin.md
│   │   │       └── java.md
│   │   ├── flyway/
│   │   │   ├── skill.yaml
│   │   │   └── SKILL.md                    # No overlays
│   │   ├── postgres/
│   │   │   ├── skill.yaml
│   │   │   └── SKILL.md                    # PostgreSQL table design (standalone)
│   │   └── postgres/timescale/design-tables/
│   │       └── skill.yaml                  # External: points to timescale/pg-aiguide
│   │
│   ├── spring/
│   │   ├── core/
│   │   │   ├── skill.yaml
│   │   │   ├── SKILL.md                    # Core Spring Boot conventions
│   │   │   └── overlays/
│   │   │       ├── kotlin.md
│   │   │       └── java.md
│   │   └── security/
│   │       ├── skill.yaml
│   │       └── SKILL.md
│   │
│   ├── frontend/
│   │   ├── jte/
│   │   │   ├── skill.yaml
│   │   │   ├── SKILL.md
│   │   │   └── overlays/
│   │   │       ├── kotlin.md
│   │   │       └── java.md
│   │   └── daisyui/
│   │       ├── skill.yaml
│   │       ├── SKILL.md
│   │       └── components.md
│   │
│   └── architecture/
│       ├── patterns/
│       │   ├── skill.yaml
│       │   └── SKILL.md
│       └── testing/
│           ├── skill.yaml
│           └── SKILL.md
│
├── docs/
│   └── dev/
│       ├── initial-plan.md
│       └── spec.md                         # This file
│
├── CONTRIBUTING.md
├── README.md
└── LICENSE
```

---

## Terminology

| Term          | Definition                                                                 |
|---------------|----------------------------------------------------------------------------|
| **Skill**     | Base content — the core best-practice guidance (e.g., `SKILL.md`)          |
| **Overlay**   | Language or database variant layered on top of a skill (e.g., `kotlin.md`) |
| **Variant**   | The assembled output installed in the user's project (base + overlays)     |
| **Component** | Cross-cutting concern shared across multiple skills — *deferred to v2*     |

The orchestrator discovers skills by walking the `skills/` tree and reading each `skill.yaml`.
---

## Skill Composition Model

### Base + Overlays

Instead of maintaining separate full skills per language/database variant, skills compose from layers:

```
Base skill (SKILL.md)          — Universal patterns (language/database-agnostic)
  + Language overlay (kotlin.md) — Language-specific idioms and conventions
  + Database overlay (postgres.md) — Database-specific patterns and gotchas
```

**Overlay dimensions (v1): language and database only.** Other concerns (testing, security, architecture) are separate
standalone skills, not overlays.

### How composition works

When the orchestrator detects jOOQ + Kotlin + PostgreSQL:

1. Fetches `skills/database/jooq/` (entire directory)
2. Installs the base `SKILL.md` as the main skill file
3. Installs applicable overlays (`kotlin.md`, `postgres.md`) as knowledge files referenced from the base
4. Non-applicable overlays (`java.md`, `mysql.md`) are NOT installed

**Installed output in user's project:**

```
.claude/skills/jooq/
├── SKILL.md                    # Base skill (references overlays below)
├── knowledge/
│   ├── anti-patterns.md        # From base knowledge/
│   ├── multiset.md
│   ├── fetching-mapping.md
│   ├── kotlin.md               # From overlays/ — language-specific
│   └── postgres.md             # From overlays/ — database-specific
```

The base `SKILL.md` is generated/assembled to reference the active overlays:

```markdown
---
name: jooq
description: Comprehensive jOOQ DSL best practices. Use when writing
  jOOQ queries, mapping results, handling transactions, or designing
  repository layers.
---

# jOOQ Best Practices

## Knowledge base

- [anti-patterns.md](knowledge/anti-patterns.md) — Common jOOQ mistakes
- [multiset.md](knowledge/multiset.md) — Nested collections with MULTISET
- [fetching-mapping.md](knowledge/fetching-mapping.md) — Result mapping patterns
- [kotlin.md](knowledge/kotlin.md) — Kotlin-specific jOOQ patterns
- [postgres.md](knowledge/postgres.md) — PostgreSQL-specific jOOQ patterns

## Core rules (always apply)

...
```

### Overlay format

Overlays are plain markdown files, same as knowledge files:

```markdown
# jOOQ — Kotlin Patterns

## Kotlin data class mapping

- Map jOOQ records to Kotlin data classes, not Java beans
- Use `record.into(MyDataClass::class.java)` for simple mapping
- Use `record.map { MyDataClass(it.FIELD1, it.FIELD2) }` for custom mapping
  ...

## Extension functions

- Define DSL extensions for common query patterns
  ...
```

Overlays are knowledge files with a specific role — no special frontmatter.

---

## Skill Discovery

### Per-skill `skill.yaml` manifests

Each skill directory contains a `skill.yaml` that declares its activation rules, overlays, and metadata. The
orchestrator discovers skills by walking the `skills/` tree and reading each `skill.yaml`.

**Example: internal skill with overlays**

```yaml
# skills/database/jooq/skill.yaml
name: jooq
description: "jOOQ DSL best practices"
activatesOn:
  - "org.jooq:jooq"
overlays:
  language: [ kotlin, java ]
  database: [ postgres, mysql ]
```

**Example: standalone skill (no overlays)**

```yaml
# skills/database/flyway/skill.yaml
name: flyway
description: "Flyway migration best practices"
activatesOn:
  - "org.flywaydb:flyway-core"
```

**Example: always-active skill**

```yaml
# skills/spring/core/skill.yaml
name: spring-core
description: "Core Spring Boot conventions and patterns"
activatesOn:
  - always
overlays:
  language: [ kotlin, java ]
```

### `skill.yaml` format reference

| Field         | Required | Description                                                            |
|---------------|----------|------------------------------------------------------------------------|
| `name`        | yes      | Unique skill identifier                                                |
| `description` | yes      | One-line description shown during init                                 |
| `activatesOn` | yes      | List of dependency coordinates that trigger this skill, or `[always]`  |
| `overlays`    | no       | Map of dimension → supported values (e.g., `language: [kotlin, java]`) |
| `repo`        | no       | If present, marks this as an external skill. Value: `owner/repo`       |
| `path`        | no       | Path within external repo (required when `repo` is set)                |
| `ref`         | no       | Git ref to pin external content to (required when `repo` is set)       |
| `maintainer`  | no       | Organization or person maintaining an external skill                   |

### External skills as empty directories

External skills live in the same directory tree as internal skills — empty folders with only a `skill.yaml` that
points to the external repo. The external organization doesn't need to do anything.

```
skills/database/postgres/timescale/design-tables/
└── skill.yaml     # No SKILL.md — content lives in external repo
```

```yaml
# skills/database/postgres/timescale/design-tables/skill.yaml
name: timescale-design-tables
description: "Expert PostgreSQL table design from Timescale"
repo: timescale/pg-aiguide           # marks this as external
path: skills/design-postgres-tables  # path within that repo
ref: v2.0.1
activatesOn:
  - "org.postgresql:postgresql"
maintainer: Timescale
```

**Key benefit:** The entire skill catalog (internal + external) is visible by walking the `skills/` tree. The
orchestrator treats all `skill.yaml` files the same — if `repo:` is present, fetch from there; if not, content is local.

### `registry.yml` — dimensions only

`registry.yml` contains global overlay dimensions configuration. All skill definitions live in per-directory
`skill.yaml` files.

```yaml
# registry.yml — global overlay dimensions
version: 1

# Global overlay dimensions — orchestrator uses these to detect project context
# All skills are discovered via skill.yaml files.
dimensions:
  language:
    detect_from: plugin_block    # kotlin("jvm") → kotlin, else java
    values: [ kotlin, java ]
  database:
    detect_from: driver_dependency
    values:
      postgres: [ "org.postgresql:postgresql" ]
      mysql: [ "com.mysql:mysql-connector-j" ]
```

### Discovery algorithm

1. Parse `registry.yml` to load dimension detection rules
2. Walk the `skills/` directory tree
3. For each `skill.yaml` found:
    - If `repo:` is present → external skill (fetch content from that repo at pinned ref)
    - If `repo:` is absent → internal skill (content is in the same directory)
4. Match each skill's `activatesOn` against detected project dependencies
5. For matched skills, select applicable overlays based on detected dimensions

---

## Bootstrap Flow

### One-liner install

```bash
curl -fsSL https://raw.githubusercontent.com/jvm-skills/jvm-skills/main/install.sh | sh
```

This script:

1. Downloads the `jvm-skills` shell script to a local location
2. Runs `jvm-skills init` immediately (smart bootstrap — user goes through setup in one step)

### What `jvm-skills init` does

```
$ jvm-skills init

Scanning build.gradle.kts...

Detected stack:
  Language:     Kotlin
  Framework:    Spring Boot 3.3.0
  Database:     PostgreSQL
  Data access:  jOOQ
  Templates:    JTE
  Migrations:   Flyway

Fetching registry.yml (dimensions)...
Discovering skills (walking skill.yaml files)...

Composing skills for your stack (Kotlin + PostgreSQL):

  Database:
    [x] jooq          base + kotlin overlay + postgres overlay
    [x] postgres       standalone (table design)
    [x] flyway         standalone (migrations)

  Spring:
    [x] spring-core    base + kotlin overlay

  Frontend:
    [x] jte            base + kotlin overlay

  [ ] spring-security  (not detected — add manually if needed)

Enable compound engineering? (Y/n)
  This adds review agents and /plan /work /review /compound commands

Confirm selection? (Y/n)

Fetching & assembling skills...
  ✓ jooq           base + kotlin + postgres  @ v1.0.0
  ✓ postgres                                 @ v1.0.0
  ✓ flyway                                   @ v1.0.0
  ✓ spring-core    base + kotlin             @ v1.0.0
  ✓ jte            base + kotlin             @ v1.0.0

Generating files...
  ✓ .claude/skills/jooq/
  ✓ .claude/skills/postgres/
  ✓ .claude/skills/flyway/
  ✓ .claude/skills/spring-core/
  ✓ .claude/skills/jte/
  ✓ .claude/skill-sources.yml
  ✓ CLAUDE.md
  ✓ .claude/agents/spring-reviewer.md
  ✓ .claude/agents/jooq-reviewer.md
  ✓ .claude/commands/jvm-init.md
  ✓ .claude/commands/jvm-update.md
  ✓ .claude/commands/plan.md
  ✓ .claude/commands/work.md
  ✓ .claude/commands/review.md
  ✓ .claude/commands/compound.md

Done. 5 skills, 2 agents, 6 commands installed.
```

---

## Dependency Detection

### Parser: grep/regex on build files

The shell script uses grep/regex patterns to extract declared dependencies from:

- `build.gradle.kts` — `implementation("group:artifact:version")`, `implementation("group:artifact")`, Kotlin DSL
  variants
- `build.gradle` — Groovy DSL variants
- `pom.xml` — `<groupId>` + `<artifactId>` within `<dependency>` blocks

**Detection depth: declared dependencies only.** No transitive resolution, no running Gradle/Maven. Fast, requires no
working build.

### Detection matrix

| Category            | Detected From                | Example Dependency                                                  |
|---------------------|------------------------------|---------------------------------------------------------------------|
| Language            | Plugin block / `<packaging>` | `kotlin("jvm")`, `java` plugin                                      |
| Spring Boot version | Plugin/parent                | `org.springframework.boot` version                                  |
| Database            | Driver dependency            | `org.postgresql:postgresql`, `mysql:mysql-connector-java`           |
| Data access         | ORM/DSL dependency           | `org.jooq:jooq`, `spring-boot-starter-data-jpa`                     |
| Templates           | View engine dependency       | `gg.jte:jte-spring-boot-starter-3`, `spring-boot-starter-thymeleaf` |
| Migrations          | Migration tool dependency    | `org.flywaydb:flyway-core`, `org.liquibase:liquibase-core`          |
| Frontend            | `package.json` presence      | `tailwindcss`, `daisyui`, `htmx.org`                                |
| Testing             | Test dependencies            | `org.testcontainers:*`, `spring-boot-starter-test`                  |

---

## Versioning & Fetching

### Pin to commit/tag

The `.claude/skill-sources.yml` (generated during init) records the exact ref for each installed skill and which
overlays were applied:

```yaml
# .claude/skill-sources.yml — generated by jvm-skills init
version: 1
detected:
  language: kotlin
  database: postgres
  framework: spring-boot
  framework_version: "3.3.0"

compound_engineering: true

installed:
  - name: jooq
    repo: jvm-skills/jvm-skills           # omit for monorepo default
    path: skills/database/jooq
    ref: v1.0.0
    sha: abc1234
    overlays_applied: [ kotlin, postgres ]

  - name: postgres
    path: skills/database/postgres
    ref: v1.0.0
    sha: def5678

  - name: flyway
    path: skills/database/flyway
    ref: v1.0.0
    sha: ghi9012

  - name: spring-core
    path: skills/spring/core
    ref: v1.0.0
    sha: jkl3456
    overlays_applied: [ kotlin ]

  - name: jte
    path: skills/frontend/jte
    ref: v1.0.0
    sha: mno7890
    overlays_applied: [ kotlin ]
```

### Fetch mechanism: GitHub API

1. Fetch the directory listing via GitHub Trees API
2. Download each file in the skill directory
3. Filter overlays: only download applicable ones based on detected stack
4. Assemble into user's `.claude/skills/<name>/` directory

No `git clone` needed. Respects GitHub API rate limits (unauthenticated: 60 req/hr; authenticated via `GITHUB_TOKEN`:
5000 req/hr).

---

## Generated Output

### Files generated by `jvm-skills init`

| File                                              | Purpose                                                  |
|---------------------------------------------------|----------------------------------------------------------|
| `.claude/skills/<name>/`                          | Assembled skill directories (base + applicable overlays) |
| `.claude/skill-sources.yml`                       | Records installed skills, versions, applied overlays     |
| `CLAUDE.md`                                       | Project-level AI context (only if missing)               |
| `.claude/agents/spring-reviewer.md`               | Core review agent (if compound opted in)                 |
| `.claude/agents/<tech>-reviewer.md`               | Specialized review agents (if compound opted in)         |
| `.claude/commands/jvm-init.md`                    | Re-runnable init command                                 |
| `.claude/commands/jvm-update.md`                  | Update command                                           |
| `.claude/commands/{plan,work,review,compound}.md` | Compound workflow commands (if opted in)                 |

### CLAUDE.md template

Only generated if CLAUDE.md does **not** already exist:

```markdown
# Project Guidelines

## Technology Stack

- Language: {{language}}
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

**Two-tier generation:**

Core agent (always generated if compound opted in):

- `spring-reviewer.md` — Core Spring patterns: constructor injection, @Transactional placement, controller/service
  split, error handling.

Specialized agents (generated per detected technology):

- `jooq-reviewer.md` — jOOQ usage review against installed skill.
- `security-reviewer.md` — Spring Security review.
- `migration-reviewer.md` — Migration naming and safety.

Each agent references the installed skills:

```markdown
---
name: jooq-reviewer
description: Reviews jOOQ query patterns and repository design.
---

You are a code reviewer specializing in jOOQ with Spring Boot.

Review the code changes against the best practices defined in:

- `.claude/skills/jooq/SKILL.md`
- `.claude/skills/jooq/knowledge/anti-patterns.md`
- `.claude/skills/jooq/knowledge/kotlin.md`

Focus on:

- Type-safe DSL usage (no string SQL, no raw JDBC)
- Proper result mapping to Kotlin data classes
- Transaction boundary correctness
- EXISTS over COUNT for existence checks
  ...
```

---

## Compound Engineering Integration

### Fork of compound-engineering-plugin

The compound engineering workflow is based on a **fork
of [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin)**:

1. **Strips Rails-specific content** — removes DHH reviewers, Rails-specific skills
2. **Keeps the workflow commands** — `/plan`, `/work`, `/review`, `/compound`
3. **Keeps generic agents** — any non-Rails-specific review agents
4. **Enriches with JVM agents** — generated from templates, referencing installed skills
5. **Stays synced with upstream** — periodically merge upstream improvements

When compound engineering is opted in during `jvm-skills init`, the workflow commands and JVM-specific agents are
installed.

---

## Multi-Tool Support (v2+)

### Claude Code first, compile to others later

v1 generates Claude Code format only (`.claude/skills/`, SKILL.md with YAML frontmatter).

The architecture supports future compilation targets:

| AI Tool     | Output Format                        | Compilation Strategy                        |
|-------------|--------------------------------------|---------------------------------------------|
| Claude Code | `.claude/skills/<name>/SKILL.md`     | Native — no compilation needed              |
| Cursor      | `.cursorrules`                       | Concatenate all active skills into one file |
| Copilot     | `.github/copilot-instructions.md`    | Concatenate + format for Copilot            |
| Windsurf    | `.windsurfrules`                     | Concatenate + format for Windsurf           |
| Aider       | `.aider.conf.yml` + conventions file | Extract rules into Aider format             |
| Codex       | `AGENTS.md`                          | Map agents + skills to AGENTS.md format     |

During `jvm-skills init`, the tool asks which AI tool the user uses and generates the correct format. The canonical
source is always SKILL.md; other formats are compiled from it.

**Key limitation:** Tools without skill auto-activation (everything except Claude Code) get all active skills
concatenated into one file. No conditional activation based on context.

---

## Update Flow

### `jvm-skills update` command — 3-way diff + AI agent merge

The update flow uses a 3-way diff strategy: old upstream (from pinned SHA) vs new upstream vs local version. Clean
updates (no local edits) are applied directly. Skills with local edits are handed to the AI agent for intelligent merge.

```
$ jvm-skills update

Reading .claude/skill-sources.yml...

Checking for updates...
  jooq           v1.0.0 → v1.1.0  (new: window function patterns)
  postgres       v1.0.0 → v1.0.0  (up to date)
  spring-core    v1.0.0 → v1.1.0  (new: ProblemDetail patterns)

Downloading updates to temp directory...
  ✓ jooq           v1.1.0 downloaded
  ✓ spring-core    v1.1.0 downloaded

Generating 3-way diffs...
  jooq:         local edits detected in SKILL.md, knowledge/anti-patterns.md
  spring-core:  no local edits

Applying clean updates...
  ✓ spring-core  → v1.1.0 (no local edits, applied directly)

Handing edited skills to AI agent for merge...
  → Run /jvm-update in Claude Code to merge jooq updates with your local edits

Context written to .claude/pending-updates/jooq/
  - old-upstream/    (v1.0.0 files)
  - new-upstream/    (v1.1.0 files)
  - local/           (your current files)
  - diff.patch       (3-way diff summary)
```

### How the shell script decides

1. **Check for newer versions** via GitHub API (compare pinned SHA in `skill-sources.yml` against latest tag)
2. **Download new upstream** files to a temp directory
3. **Download old upstream** files (from the pinned SHA) to a temp directory
4. **Compare local files against old upstream** — if identical, this is a clean update (user made no edits)
5. **Clean updates:** apply directly, update `skill-sources.yml`
6. **Dirty updates:** write context to `.claude/pending-updates/<skill>/` for AI agent merge

### The `/jvm-update` slash command

The `/jvm-update` slash command handles skills with local edits:

1. Reads the pending update context from `.claude/pending-updates/`
2. For each skill with local edits: reads old upstream, new upstream, and local versions
3. Intelligently merges — preserving local customizations, incorporating upstream improvements
4. Asks the user to confirm the merge result
5. Cleans up pending updates and updates `skill-sources.yml`

---

## Conflict Resolution (Claude Handoff)

When `jvm-skills init` encounters **file-level conflicts** (files that already exist), it stops and prints instructions:

```
$ jvm-skills init

Scanning build.gradle.kts...
Detected: Kotlin, Spring Boot 3.3.0, PostgreSQL, jOOQ, Flyway

⚠ Conflicts detected:
  - CLAUDE.md already exists
  - .claude/skills/jooq/ already exists
  - .claude/agents/spring-reviewer.md already exists

Cannot proceed deterministically. Run /jvm-init in Claude Code
to resolve conflicts interactively.
```

The `/jvm-init` slash command:

1. Reads detected dependencies (from a temp file the script wrote)
2. Reads existing conflicting files
3. Asks the user how to handle each conflict (keep, replace, merge)
4. Writes the resolved files

---

## Contribution Model

### Two paths

1. **Practitioners** — PR to jvm-skills monorepo with a new skill directory under the appropriate category (
   `skills/database/`, `skills/spring/`, etc.). Each new skill must include a `skill.yaml` with activation rules. The
   bar: "Would a senior engineer with 3+ years on this technology agree with every line?"

2. **Tool makers** — Maintain skill content in your own repo. PR to add an empty directory with a `skill.yaml` pointing
   to your repo. The jvm-skills `skill.yaml` handles all configuration.

### Skill graduation

```
Contributor PR → skills/<category>/<name>/ with skill.yaml + SKILL.md (incubated)
                        │
                        ▼ (tool maker adopts)
                 Tool maker maintains content in their repo
                        │
                        ▼
                 SKILL.md + knowledge/ removed from jvm-skills
                 skill.yaml updated to point externally (repo: owner/repo)
```

---

## v1 Scope

### v1: Tooling + reference skills

**Orchestrator:**

- `install.sh` bootstrap script
- `jvm-skills` CLI (shell script): `init`, `update` subcommands
- Dependency detection (grep/regex) for Gradle Kotlin DSL + Maven POM
- `registry.yml` with dimension config, per-skill `skill.yaml` manifests
- GitHub API fetching + overlay assembly logic
- Template-based file generation (CLAUDE.md, agents, commands)
- Conflict detection with Claude handoff
- Claude Code output format only

**Ship with 1-2 polished reference skills (composed):**

- `spring-core` — Core Spring conventions (base + kotlin overlay)
- `jooq` — jOOQ best practices (base + kotlin overlay + postgres overlay)
- Possibly `postgres` if the existing design-postgres-tables skill is ready

**Compound engineering (optional):**

- Forked compound workflow commands (`/plan`, `/work`, `/review`, `/compound`)
- `spring-reviewer.md` core agent template

### v2+

- More skills: JTE, Flyway, Liquibase, Thymeleaf, JPA, DaisyUI, Tailwind, htmx
- Java overlays for all skills with Kotlin overlays
- MySQL overlays for database skills
- Multi-tool compilation (Cursor, Copilot, Windsurf, Aider)
- Outreach to tool makers
- Specialized review agents
- `libs.versions.toml` parsing
- Groovy Gradle DSL support
- `package.json` frontend detection
- Architecture skills (patterns, testing strategies)
- Codebase-tailored skills via AI agent (see below)

### Codebase Tailoring Agent (v2+)

Generic skills teach universal best practices, but every project has its own base classes, naming conventions, and
architectural patterns. A **tailoring agent** bridges that gap: after `jvm-skills init` installs skills, the agent scans
the codebase and enriches each skill with project-specific examples and conventions.

#### How it works

1. **Scan** — The agent analyzes the project's source tree for structural patterns: custom base classes, exception
   hierarchies, repository abstractions, naming conventions, package layout.
2. **Enrich** — For each installed skill, the agent generates a `local-context.md` knowledge file containing
   project-specific examples that complement the generic skill.
3. **Reference** — The base `SKILL.md` is updated to include the local context file in its knowledge base listing.

#### What the agent detects

| Pattern                   | Example                                                                                  | How it enriches the skill                                                |
|---------------------------|------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| Custom base entities      | `AbstractAuditableEntity` with `createdAt`, `updatedAt`, `createdBy` fields              | jOOQ/JPA skill: "All entities extend `AbstractAuditableEntity`"          |
| Exception hierarchies     | `ServiceException` → `NotFoundException`, `ConflictException`                            | Spring skill: "Throw `NotFoundException`, not generic `ResponseStatus`"  |
| Repository base classes   | `AbstractJooqRepository<T>` with common query methods                                    | jOOQ skill: "Extend `AbstractJooqRepository`, use `findById()` pattern"  |
| DTO/mapping conventions   | Records in `*.dto` package, mapping extensions in `*Mapper.kt`                           | jOOQ skill: "Place DTOs in `dto` package, mappers in `*Mapper.kt`"      |
| Test infrastructure       | `AbstractIntegrationTest` with Testcontainers setup, custom DSL assertions               | Testing skill: "Extend `AbstractIntegrationTest` for DB tests"           |
| Configuration patterns    | `@ConfigurationProperties` classes with validated fields                                 | Spring skill: "Use existing `AppProperties` pattern for new config"      |
| Security model            | Custom `UserPrincipal`, permission enums, `@HasRole` annotations                        | Security skill: "Use `UserPrincipal` from `SecurityContextHolder`"       |
| Package structure         | `feature/` packages with controller+service+repository grouping                          | Spring skill: "Follow feature-package layout, not layer-package"         |

#### Generated output

```
.claude/skills/jooq/
├── SKILL.md                    # Updated to reference local-context.md
├── knowledge/
│   ├── anti-patterns.md
│   ├── multiset.md
│   ├── kotlin.md
│   ├── postgres.md
│   └── local-context.md        # ← Generated by tailoring agent
```

Example `local-context.md`:

```markdown
# jOOQ — Project-Specific Patterns

## Base repository

All repositories extend `AbstractJooqRepository<T>` which provides:
- `findById(id: UUID): T?`
- `exists(id: UUID): Boolean` (uses EXISTS, not COUNT)
- `DSLContext` injection via constructor

When creating a new repository, extend this base class:

⁠⁠⁠kotlin
class PhotoRepository(dsl: DSLContext) : AbstractJooqRepository<PhotoRecord>(dsl, PHOTO) {
    // custom queries here
}
⁠⁠⁠

## Entity mapping

All DTOs live in `*.dto` package as Kotlin data classes. Use the project's
existing `toDto()` extension pattern:

⁠⁠⁠kotlin
fun PhotoRecord.toDto() = PhotoDto(
    id = this.id,
    url = this.url,
    createdAt = this.createdAt
)
⁠⁠⁠

## Exception handling

Throw domain exceptions from `de.example.exception`:
- `NotFoundException` (maps to 404)
- `ConflictException` (maps to 409)
- `ValidationException` (maps to 422)

Never throw `ResponseStatusException` directly.
```

#### Design constraints

- **Additive only.** The agent never modifies existing skill content — it only generates `local-context.md`.
- **Regenerable.** Running `jvm-skills tailor` again overwrites `local-context.md`. Users who want to hand-edit should
  rename the file.
- **Opt-in.** Tailoring is a separate command (`jvm-skills tailor`), not part of `init`. The user decides when to run it.
- **Not committed by default.** `local-context.md` can be `.gitignore`d if teams prefer each developer to generate their
  own. Or committed if the team wants shared project context.

---

## Design Decisions Log

| Decision                | Chosen                                                            | Rationale                                                                                      |
|-------------------------|-------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Scope                   | JVM ecosystem (not Spring-only)                                   | Broader audience, skills aren't all Spring-specific                                            |
| Repo structure          | Monorepo (github.com/jvm-skills/jvm-skills)                       | Avoids boundary problems between repos. Org is for namespace.                                  |
| Skill organization      | By category (database/, spring/, frontend/, architecture/)        | Natural grouping, clear where new skills go                                                    |
| Skill composition       | Base + overlays (language, database)                              | No duplication across variants. Compose, don't copy.                                           |
| Overlay dimensions      | Language + database only                                          | Other concerns (testing, security) are standalone skills                                       |
| Overlay assembly        | Overlays become knowledge/ files referenced from base SKILL.md    | Keeps structural hierarchy, base references overlays                                           |
| Registry model          | Per-skill `skill.yaml` + minimal `registry.yml` (dimensions only) | Each dir owns its config. Contributors only touch their skill dir.                             |
| External skill contract | Empty dir with `skill.yaml` pointing to external repo             | Entire catalog visible by walking tree. Uniform discovery.                                     |
| Canonical format        | Claude's SKILL.md                                                 | Use existing format, don't invent a new one                                                    |
| AI tool support         | Claude Code v1, compile to others v2+                             | Don't overscope. Architecture supports it, implementation later.                               |
| Runtime                 | Shell script + Claude slash command                               | No build tool coupling, zero install                                                           |
| Detection depth         | Declared deps only (grep)                                         | Fast, no build required                                                                        |
| Versioning              | Pin to commit/tag                                                 | Deterministic, explicit updates                                                                |
| Fetch mechanism         | GitHub API                                                        | No git dependency, simple HTTP                                                                 |
| Config location         | `.claude/skill-sources.yml`                                       | Keeps AI config together                                                                       |
| Overwrite policy        | Generate once, hands-off                                          | Respects local edits                                                                           |
| Update flow             | 3-way diff + AI agent merge                                       | Respects local edits. AI is perfect for markdown merge. Deterministic for clean updates.       |
| Conflict resolution     | Deterministic → Claude handoff                                    | Fast happy path, smart conflict handling                                                       |
| Opinions                | Strongly opinionated                                              | The point — "edit locally if you disagree"                                                     |
| Agent granularity       | Two-tier: core + specialized                                      | Core always relevant, specialized per-tech                                                     |
| Git strategy            | Commit everything                                                 | Team consistency                                                                               |
| Contribution model      | Incubator → graduation                                            | Low barrier, path for tool makers                                                              |
| Compound engineering    | Fork of EveryInc plugin                                           | Workflow upstream, JVM agents are ours                                                         |
| Bootstrap               | curl one-liner                                                    | Zero dependencies                                                                              |
| Project name            | jvm-skills                                                        | Broader than spring-skills, matches JVM ecosystem scope                                        |
