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
