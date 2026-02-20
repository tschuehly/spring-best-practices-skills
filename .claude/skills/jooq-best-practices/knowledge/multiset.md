# MULTISET & Nested Collections

## Pattern: Use MULTISET for nested collections instead of N+1
**Source**: [jOOQ Official Docs — MULTISET value constructor](https://www.jooq.org/doc/3.20/manual/sql-building/column-expressions/multiset-value-constructor/) (docs)
**Since**: jOOQ 3.15

Collect correlated subquery results into nested collections in a single query. Replaces N+1 patterns.

```kotlin
dsl.select(
    AUTHOR.FIRST_NAME,
    AUTHOR.LAST_NAME,
    multiset(
        selectDistinct(BOOK.TITLE, BOOK.PUBLISHED_IN)
            .from(BOOK)
            .where(BOOK.AUTHOR_ID.eq(AUTHOR.ID))
    ).`as`("books")
).from(AUTHOR)
    .fetch()
```

Most databases emulate MULTISET via JSON/JSONB serialization under the hood.

---

## Pattern: MULTISET uses JSON arrays (not objects) internally
**Source**: [Consider using JSON arrays instead of JSON objects for serialisation](https://blog.jooq.org/consider-using-json-arrays-instead-of-json-objects-for-serialisation) (2025-08-11)

jOOQ serializes MULTISET results as arrays of arrays, not arrays of objects. Since jOOQ controls the SQL and knows column positions, it uses positional access rather than name-based lookup.

**Benefits**:
- ~80% faster for large result sets (10k rows: 2932 vs 1643 ops/s in benchmarks)
- Avoids duplicate column name conflicts (e.g., two tables both having `ID`) — JSON objects can't have duplicate keys, arrays can
- Smaller payload: no repeated key names

**Implication**: Don't try to manually parse jOOQ's internal JSON serialization — use the type-safe MULTISET API and let jOOQ handle deserialization.

---

## Pattern: Configure MULTISET emulation
**Source**: [jOOQ Official Docs — MULTISET value constructor](https://www.jooq.org/doc/3.20/manual/sql-building/column-expressions/multiset-value-constructor/) (docs)
**Since**: jOOQ 3.15

The `Settings.emulateMultiset` option controls serialization format: `DEFAULT`, `JSON`, `JSONB`, `XML`, or `NATIVE`. For PostgreSQL, `JSONB` is a good choice.

---
