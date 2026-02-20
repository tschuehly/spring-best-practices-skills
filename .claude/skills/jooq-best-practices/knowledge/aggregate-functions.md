# Aggregate Functions

## Pattern: Prefer FILTER over CASE in aggregates
**Source**: [The Performance Impact of SQL's FILTER Clause](https://blog.jooq.org/the-performance-impact-of-sqls-filter-clause) (2023-02-06)

Use `FILTER (WHERE ...)` instead of `CASE WHEN ... END` inside aggregate functions. They are semantically equivalent, but FILTER is more readable and ~8% faster on PostgreSQL (benchmarked on PG 15).

```kotlin
// Prefer: FILTER syntax
ctx.select(
    sum(FILM.LENGTH).filterWhere(FILM.RATING.eq("R")),
    sum(FILM.LENGTH).filterWhere(FILM.RATING.eq("PG"))
)

// Avoid: CASE syntax (slower on PostgreSQL, less readable)
ctx.select(
    sum(case_().when(FILM.RATING.eq("R"), FILM.LENGTH)),
    sum(case_().when(FILM.RATING.eq("PG"), FILM.LENGTH))
)
```

**Dialect note**: Native FILTER support in CockroachDB, Firebird, H2, HSQLDB, PostgreSQL, SQLite, YugabyteDB. For other databases, jOOQ automatically emulates FILTER as CASE.

---
