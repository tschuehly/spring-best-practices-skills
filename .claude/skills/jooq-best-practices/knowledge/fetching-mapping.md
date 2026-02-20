# Fetching & Result Mapping

## Pattern: Use RecordMapper for custom projections
**Source**: [jOOQ Official Docs — Fetching](https://www.jooq.org/doc/3.20/manual/sql-execution/fetching/) (docs)

Use lambda-based RecordMapper for transforming query results to domain objects.

```kotlin
data class AuthorDto(val name: String, val bookCount: Int)

val authors = dsl.select(AUTHOR.FIRST_NAME, count())
    .from(AUTHOR)
    .join(BOOK).on(BOOK.AUTHOR_ID.eq(AUTHOR.ID))
    .groupBy(AUTHOR.FIRST_NAME)
    .fetch { record -> AuthorDto(record[AUTHOR.FIRST_NAME]!!, record[count()]) }
```

---

## Pattern: fetchMap / fetchGroups for indexed results
**Source**: [jOOQ Official Docs — Fetching](https://www.jooq.org/doc/3.20/manual/sql-execution/fetching/) (docs)

Use `fetchMap()` for unique key lookups and `fetchGroups()` for one-to-many.

```kotlin
// Key → single record
val bookById: Map<Long, BookRecord> = dsl.selectFrom(BOOK).fetchMap(BOOK.ID)

// Key → list of records
val booksByAuthor: Map<Long, List<BookRecord>> = dsl.selectFrom(BOOK).fetchGroups(BOOK.AUTHOR_ID)
```

---

## Pattern: Ad-hoc converters for field-level transformation
**Source**: [jOOQ Official Docs — Ad-hoc Converter](https://www.jooq.org/doc/3.20/manual/sql-execution/fetching/) (docs)

Convert individual fields inline without a global converter.

```kotlin
dsl.select(BOOK.TITLE, BOOK.PUBLISHED_IN.convertFrom { Year.of(it) })
    .from(BOOK)
    .fetch()
```

---

## Pattern: Don't use ad-hoc converters with UNION — move logic server-side
**Source**: [How to use jOOQ's Converters with UNION Operations](https://blog.jooq.org/how-to-use-jooqs-converters-with-union-operations) (2023-03-02)
**Since**: jOOQ 3.15 (ad-hoc converters)

Ad-hoc converters are **client-side post-fetch** transformations. In a UNION, jOOQ only considers the row type of the **first subquery** when fetching results, and the DB doesn't know about converters during deduplication. Converters on non-first subqueries silently do nothing.

```kotlin
// BAD — converter on second subquery never executes
dsl.select(BOOK.ID)
    .from(BOOK)
    .union(
        select(AUTHOR.ID.convertFrom { -it })
            .from(AUTHOR)
    )
    .fetch()

// GOOD — use a server-side function instead
dsl.select(BOOK.ID)
    .from(BOOK)
    .union(
        select(AUTHOR.ID.neg())
            .from(AUTHOR)
    )
    .fetch()
```

If you must use a converter with UNION, apply it to **all subqueries** (at minimum the first one).

---
