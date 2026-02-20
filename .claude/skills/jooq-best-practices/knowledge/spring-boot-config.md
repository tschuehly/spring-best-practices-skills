# Spring Boot Configuration

## Pattern: DefaultConfigurationCustomizer callback
**Source**: [How to customise a jOOQ Configuration that is injected using Spring Boot](https://blog.jooq.org/how-to-customise-a-jooq-configuration-that-is-injected-using-spring-boot) (2021-12-16)
**Since**: Spring Boot 2.5

Use `DefaultConfigurationCustomizer` to modify jOOQ's `DefaultConfiguration` during Spring Boot auto-configuration. This is the idiomatic way to tweak settings without replacing the entire `DSLContext` bean.

```java
@Configuration
public class JooqConfig {
    @Bean
    public DefaultConfigurationCustomizer jooqConfigCustomizer() {
        return (DefaultConfiguration c) -> c.settings()
            .withRenderQuotedNames(RenderQuotedNames.EXPLICIT_DEFAULT_UNQUOTED);
    }
}
```

The callback receives the mutable `DefaultConfiguration` during initialization — you can change settings, add listeners, register converters, etc.

---
