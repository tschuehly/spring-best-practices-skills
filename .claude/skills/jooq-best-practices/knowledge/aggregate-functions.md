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

## Pattern: Functional dependencies in GROUP BY
**Source**: [Functional Dependencies in SQL GROUP BY](https://blog.jooq.org/functional-dependencies-in-sql-group-by) (2021-10-29)
**Since**: jOOQ 3.16 (table-level grouping)

When a primary or unique key is in the `GROUP BY` clause, columns functionally dependent on that key can be projected without listing them in `GROUP BY`. This reduces boilerplate and maintenance burden.

```kotlin
// Instead of listing every column in GROUP BY:
ctx.select(AUTHOR.ID, AUTHOR.NAME, count(BOOK.ID))
    .from(AUTHOR)
    .leftJoin(BOOK).on(BOOK.AUTHOR_ID.eq(AUTHOR.ID))
    .groupBy(AUTHOR.ID)  // NAME is functionally dependent on ID
    .fetch()

// Since jOOQ 3.16: group by table (uses primary key automatically)
ctx.select(AUTHOR.ID, AUTHOR.NAME, count(BOOK.ID))
    .from(AUTHOR)
    .leftJoin(BOOK).on(BOOK.AUTHOR_ID.eq(AUTHOR.ID))
    .groupBy(AUTHOR)  // table-level grouping
    .fetch()
```

**Dialect note**: Functional dependency recognition supported in CockroachDB, H2, HSQLDB, MariaDB, MySQL, PostgreSQL, SQLite, YugabyteDB. Other dialects (Db2, Oracle, SQL Server, Firebird) require all projected columns in GROUP BY explicitly — jOOQ handles this transparently when using table-level grouping.

---
