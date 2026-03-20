# Window Functions

## Pattern: Emulate DISTINCT ON with FIRST_VALUE for portability
**Source**: [Using DISTINCT ON in Non-PostgreSQL Databases](https://blog.jooq.org/using-distinct-on-in-non-postgresql-databases) (2019-09-09)

PostgreSQL's `DISTINCT ON (col)` keeps the first row per group ordered by an `ORDER BY` clause. The portable equivalent uses `FIRST_VALUE` window functions, which jOOQ supports across all modern dialects.

```kotlin
// PostgreSQL-only: DISTINCT ON
// SELECT DISTINCT ON (location) location, time, report
// FROM weather_reports ORDER BY location, time DESC

// Portable: FIRST_VALUE window function
ctx.select(
    WEATHER_REPORTS.LOCATION.`as`("location"),
    DSL.firstValue(WEATHER_REPORTS.TIME)
        .over(DSL.partitionBy(WEATHER_REPORTS.LOCATION)
                  .orderBy(WEATHER_REPORTS.TIME.desc()))
        .`as`("time"),
    DSL.firstValue(WEATHER_REPORTS.REPORT)
        .over(DSL.partitionBy(WEATHER_REPORTS.LOCATION)
                  .orderBy(WEATHER_REPORTS.TIME.desc()))
        .`as`("report")
)
.from(WEATHER_REPORTS)
.orderBy(WEATHER_REPORTS.LOCATION)
.fetch()
```

Add `DSL.selectDistinct()` on the outer query to collapse duplicate rows produced by the window functions across the full result set.

**Dialect**: PostgreSQL supports native `DISTINCT ON`; for all other databases use `FIRST_VALUE` + `DISTINCT`.
**Note**: jOOQ supports PostgreSQL's `DISTINCT ON` natively via `selectDistinct(...).on(...)` for PostgreSQL targets. Use the `FIRST_VALUE` approach when targeting multiple dialects.

---
