# Logging & Diagnostics

## Pattern: R2DBC LoggingConnection for reactive SQL logging
**Source**: [jOOQ's R2DBC LoggingConnection to log all SQL statements](https://blog.jooq.org/jooqs-r2dbc-loggingconnection-to-log-all-sql-statements) (2023-01-17)
**Since**: jOOQ 3.18

Use `LoggingConnection` to wrap an R2DBC `Connection` and log all SQL statements at DEBUG level. Works as a proxy — intercepts `createStatement()`, `execute()`, `add()`, and `close()` calls.

Useful when the R2DBC driver doesn't provide its own DEBUG logging. Can also be used standalone (without jOOQ as query builder) by copying the source.

JDBC equivalent (`LoggingConnection` for JDBC) has existed longer — same concept, different SPI.

---
