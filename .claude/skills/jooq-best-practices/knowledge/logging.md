# Logging & Diagnostics

## Pattern: R2DBC LoggingConnection for reactive SQL logging
**Source**: [jOOQ's R2DBC LoggingConnection to log all SQL statements](https://blog.jooq.org/jooqs-r2dbc-loggingconnection-to-log-all-sql-statements) (2023-01-17)
**Since**: jOOQ 3.18

Use `LoggingConnection` to wrap an R2DBC `Connection` and log all SQL statements at DEBUG level. Works as a proxy — intercepts `createStatement()`, `execute()`, `add()`, and `close()` calls.

Useful when the R2DBC driver doesn't provide its own DEBUG logging. Can also be used standalone (without jOOQ as query builder) by copying the source.

JDBC equivalent (`LoggingConnection` for JDBC) has existed longer — same concept, different SPI.

---

## Pattern: DiagnosticsConnection for N+1 query detection
**Source**: [Using jOOQ's DiagnosticsConnection to detect N+1 Queries](https://blog.jooq.org/using-jooqs-diagnosticsconnection-to-detect-n1-queries) (2022-01-11)

Wrap a JDBC connection (or DataSource) with jOOQ's `DiagnosticsConnection` to detect repeated SQL statements at runtime — the hallmark of N+1 problems. Framework-agnostic: works with jOOQ, Hibernate, JdbcTemplate, or raw JDBC.

The diagnostics listener fires after the **first repetition** of any normalised statement within a transaction, assuming that repeating the same query is generally unnecessary.

```java
// Per-connection setup
DSLContext ctx = DSL.using(connection);
ctx.configuration().set(new DefaultDiagnosticsListener() {
    @Override
    public void repeatedStatements(DiagnosticsContext c) {
        System.out.println("Repeated: " + c.normalisedStatement());
    }
});
Connection diagConn = ctx.diagnosticsConnection();
// Pass diagConn to any framework (JPA, Spring JDBC, etc.)
```

For broader coverage, use `DiagnosticsDataSource` to wrap an entire `DataSource`.

**Best practice**: Enable in dev/test environments — there is some overhead. Pair with the N+1 avoidance patterns in [anti-patterns.md](anti-patterns.md).

---
