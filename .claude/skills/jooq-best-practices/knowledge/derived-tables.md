# Derived Tables

## Pattern: Declare derived table before use
**Source**: [How to Write a Derived Table in jOOQ](https://blog.jooq.org/how-to-write-a-derived-table-in-jooq) (2023-02-24)

Java requires variable declaration before use, so declare your derived table as a `Table<?>` first, then reference it in the outer query.

```java
Table<?> nested =
    select(BOOK.AUTHOR_ID, count().as("books"))
    .from(BOOK)
    .groupBy(BOOK.AUTHOR_ID).asTable("nested");

ctx.select(nested.fields())
   .from(nested)
   .orderBy(nested.field("books"))
   .fetch();
```

---

## Pattern: Extract fields for type-safe derived table columns
**Source**: [How to Write a Derived Table in jOOQ](https://blog.jooq.org/how-to-write-a-derived-table-in-jooq) (2023-02-24)

Derived tables lose generated-code type safety. Recover it by extracting `Field<T>` references and passing them to `nested.field(fieldRef)`:

```java
Field<Integer> count = count().as("books");

Table<?> nested =
    select(BOOK.AUTHOR_ID, count)
    .from(BOOK)
    .groupBy(BOOK.AUTHOR_ID).asTable("nested");

ctx.select(nested.fields())
   .from(nested)
   .orderBy(nested.field(count))
   .fetch();
```

---

## Pattern: Simplify away unnecessary derived tables
**Source**: [How to Write a Derived Table in jOOQ](https://blog.jooq.org/how-to-write-a-derived-table-in-jooq) (2023-02-24)

Many derived tables are unnecessary — flattening the query restores full type safety from generated code. Always evaluate whether you actually need the subquery.

```java
// Before: unnecessary derived table
// After: flat query with full type safety
Field<Integer> count = count().as("books");

ctx.select(BOOK.AUTHOR_ID, count)
   .from(BOOK)
   .groupBy(BOOK.AUTHOR_ID)
   .orderBy(count)
   .fetch();
```

---
