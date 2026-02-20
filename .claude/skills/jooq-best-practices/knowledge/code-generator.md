# Code Generator Configuration

## Pattern: Package-private generated code
**Source**: [How to Generate Package Private Code with jOOQ's Code Generator](https://blog.jooq.org/how-to-generate-package-private-code-with-jooqs-code-generator) (2023-06-28)

Hide generated jOOQ code from client code using package-private visibility. Requires two steps:

1. **Custom strategy** — put all generated code in a single package:

```java
public class SinglePackageStrategy extends DefaultGeneratorStrategy {
    @Override
    public String getJavaPackageName(Definition definition, Mode mode) {
        return getTargetPackage();
    }
}
```

2. **Set visibility to NONE** in code generator config:

```xml
<generate>
  <visibilityModifier>NONE</visibilityModifier>
</generate>
```

Use `<clean>false</clean>` on the target to avoid deleting other files in the shared package. Strategy code can be declared inline in configuration since jOOQ 3.19.

**Since**: jOOQ 3.19 (inline strategy support)

---

## Pattern: Table-valued parameters via code generation
**Source**: [How to Pass a Table Valued Parameter to a T-SQL Function with jOOQ](https://blog.jooq.org/how-to-pass-a-table-valued-parameter-to-a-t-sql-function-with-jooq) (2023-04-25)
**Dialect**: SQL Server (T-SQL)

The code generator produces type-safe wrappers for T-SQL table-valued parameters (TVPs). For a user-defined table type and function:

```sql
CREATE TYPE u_number_table AS TABLE (column_value INTEGER);
CREATE FUNCTION f_cross_multiply (@numbers u_number_table READONLY)
RETURNS @result TABLE (i1 INTEGER, i2 INTEGER, product INTEGER) ...
```

jOOQ generates three artifacts:
- **Record type** (`UNumberTableRecord`) — represents the TVP
- **Element type** (`UNumberTableElementTypeRecord`) — models individual rows
- **Function wrapper** (`Routines.fCrossMultiply()`) — type-safe call

```java
List<Integer> l = List.of(1, 2, 3);
Result<FCrossMultiplyRecord> result = ctx
    .selectFrom(fCrossMultiply(new UNumberTableRecord(
        l.stream().map(UNumberTableElementTypeRecord::new).toList()
    )))
    .fetch();
```

This abstracts away native JDBC complexity (`SQLServerDataTable`) behind jOOQ's type-safe API.

---

## Pattern: Version compatibility between runtime and code generator
**Source**: [Cannot resolve symbol 'VERSION_3_17' in jOOQ generated code](https://blog.jooq.org/cannot-resolve-symbol-version_3_17-in-jooq-generated-code) (2022-08-30)
**Since**: jOOQ 3.16

Starting with jOOQ 3.16, generated code includes a version reference constant that triggers a compile-time error if the runtime version is older than the code generator version. This catches version mismatches early.

**Rules**:
- Generated code is **forward compatible** — older generators work with newer runtimes
- Runtime API is **backward compatible** — newer runtimes work with older generated code
- **Newer generators with older runtimes are NOT supported**

**Best practice**: always keep runtime version >= code generator version. Ideally, match both versions exactly.

To disable the check (not recommended):
```xml
<jooqVersionReference>false</jooqVersionReference>
```

---
