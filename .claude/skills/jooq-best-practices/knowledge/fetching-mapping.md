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
