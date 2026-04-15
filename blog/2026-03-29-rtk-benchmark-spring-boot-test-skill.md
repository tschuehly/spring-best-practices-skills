---
title: "I Benchmarked RTK on Spring Boot — Then Built a Skill That Does It Better"
slug: rtk-benchmark-spring-boot-test-skill
date: 2026-03-29
author: Thomas Schilling
description: "RTK saves 74% on failing Spring Boot test output. A custom /test skill that parses JUnit XML saves 99.4%. Benchmark results and the skill that replaced generic compression."
skills:
  - testing/test-gradle
tags:
  - benchmark
  - testing
  - spring-boot
  - skills
draft: true
---

[RTK](https://github.com/nicholasgasior/rtk) (Rust Token Killer) is a CLI proxy that compresses tool output before it hits your AI coding agent's context window. It claims 60-90% savings on common dev operations. I tested it on [PhotoQuest](https://photoquest.wedding/), a Spring Boot + Kotlin project with 557 tests, Testcontainers, Playwright E2E, and all the verbose logging the JVM ecosystem brings.

## The Setup

PhotoQuest's test suite spans unit tests, integration tests (Testcontainers + PostgreSQL), and Playwright browser tests. I introduced 3 bugs to produce 10 failures, then compared raw Gradle output, RTK-filtered output, and the project's `/test` skill output.

## Passing Tests: RTK Is Perfect

| Command | Raw Output | RTK Output | Savings |
|---------|-----------|------------|---------|
| `./gradlew test` | 933KB / 7,642 lines | 48 bytes / 1 line | ~100% |

RTK replaces ~233K tokens of Spring Boot startup, Testcontainer init, and Flyway migrations with `[ok] Command completed successfully (no errors)`. Hard to argue with that.

For `ls`, `grep`, and other standard operations, RTK delivers similar 51-99% savings.

## Failing Tests: The Gap Opens

When tests fail — where you actually need the output — RTK still passes through 1,750 lines:

| Command | Raw Output | RTK Output | Savings |
|---------|-----------|------------|---------|
| `./gradlew test` (failing) | 933KB / 7,642 lines | 245KB / 1,750 lines | 74% |

Those 1,750 lines include Spring Boot startup logs, Testcontainer/Postgres initialization, Docker provider output, Flyway migrations, and JVM warnings. The 10 lines Claude needs are buried in the noise. 74% compression still leaves ~61K tokens — more than many models can usefully process from a single tool call.

## Compile Errors: RTK Removes the Wrong Things

RTK's `err` mode strips the actual error locations:

```
# Raw output (36 lines)
e: .../JoinController.kt:60:47 Unresolved reference 'GUEST'.
e: .../JoinController.kt:61:14 Unresolved reference 'onConflictDoNothing'.
> Task :compileKotlin FAILED

# RTK err output (9 lines)
> Task :compileKotlin FAILED
Execution failed for task ':compileKotlin'.
> Compilation error. See log for more details
BUILD FAILED in 1s
```

Claude knows the build failed but not where or why. Raw output is more useful here.

## The Skill Approach: Parse, Don't Compress

Gradle already produces structured data. Every test run writes JUnit XML to `build/test-results/test/`. These files contain which tests failed, the assertion messages, and relevant stack frames. No Spring logs. No Docker output.

The `/test` skill from jvm-skills skips Gradle's console output entirely and parses these XML files:

```bash
#!/usr/bin/env bash
set -uo pipefail

RESULTS_DIR="build/test-results/test"

# Redirect all console noise to a file
./gradlew test -Pplaywright.headless=true "$@" > build/gradle-test-out.txt 2>&1
TEST_EXIT=$?

if [ "$TEST_EXIT" -eq 0 ]; then
  echo "All tests passed."
  exit 0
fi

# Parse JUnit XML — skip files with no failures
for xml_file in "$RESULTS_DIR"/TEST-*.xml; do
  if grep -q 'failures="0"' "$xml_file" \
     && grep -q 'errors="0"' "$xml_file"; then
    continue
  fi

  # AWK extracts classname, test name, failure message (max 500 chars),
  # and stack frames from the project package (filtering framework noise)
  awk '...' "$xml_file"
done
```

The AWK parser keeps only stack frames containing the project's package name. Framework internals, Spring proxy chains, Testcontainer setup — not compressed, not summarized. Gone.

Output for the same 10 failures:

```
## Failed Tests

### CacheServiceTest > isZipUpToDate false when no cached count FAILED
org.opentest4j.AssertionFailedError:
Expecting value to be false but was true
  at de.tschuehly.photoquest.core.file.CacheServiceTest.kt:187
---
### CacheServiceTest > isZipUpToDate true when counts match FAILED
org.opentest4j.AssertionFailedError:
Expecting value to be true but was false
  at de.tschuehly.photoquest.core.file.CacheServiceTest.kt:164
---
### ImageProcessingUtilsTest > readImage orientation 5 normalizes to landscape FAILED
java.lang.AssertionError:
Expecting actual: 1200 to be greater than: 1800
  at de.tschuehly.photoquest.core.file.ImageProcessingUtilsTest.kt:69
---
### JoinFlowPlaywrightTest > Should auto-login new user via invite link FAILED
expected: MANAGER but was: VIEWER
[SCREENSHOT] playwright/web/page/join/JoinFlowPlaywrightTest/...png
  at de.tschuehly.photoquest.web.page.join.JoinFlowPlaywrightTest.kt:79
---

Summary: 10 test failure(s)
```

62 lines. 6KB. The Playwright failures are larger because they include screenshot paths for visual debugging, but that's useful context, not noise.

## The Numbers Side by Side

| Approach | Output Size | Tokens (~4 chars/token) | Compression |
|----------|-----------|------------------------|-------------|
| Raw Gradle | 933KB / 7,642 lines | ~233K | — |
| RTK `err` | 245KB / 1,750 lines | ~61K | 74% |
| `/test` skill | 6KB / 62 lines | ~1,500 | 99.4% |

## The Skill Does More Than Parse

The output format is the smaller part. After parsing failures, the `/test` skill:

1. **Groups failures by exception type.** 4 tests failing with the same `AssertionFailedError` get treated as one bug, not four.
2. **Launches parallel subagents.** Each exception group gets its own agent that reads the test code, traces to production code, finds the root cause, and fixes it.
3. **Verifies each fix** by running the affected tests.
4. **Re-runs the full suite** to catch regressions.

One `/test` invocation finds multiple bugs, fixes them in parallel, and confirms everything passes. Token compression can't do that.

## When RTK Still Makes Sense

RTK works well for ecosystems it was built for — Rust, TypeScript, Node. Even in JVM projects, `rtk ls` and `rtk grep` deliver real savings with no downsides. And for passing tests, `[ok]` beats 914KB every time.

But for the operations that consume the most tokens and require the most precision — test failures, build errors, diagnostic output — the JVM ecosystem is too verbose and too structured for generic regex filtering. JUnit XML, Gradle's output format, Spring Boot's log structure all have parseable formats. A skill can exploit that structure where a generic compressor can't.

Don't compress your agent's input. Curate it.

The `/test` skill is available in the [jvm-skills](https://github.com/jvm-skills/jvm-skills) registry as `testing/test-gradle`.
