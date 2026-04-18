# Spring test types and per-type defaults

Shared between `kotest-migrate` and `kotest-create`. Keep in sync if edited.

Before writing or porting a test, classify which Spring test type it is. The
test type determines annotations, injection strategy, transactional behavior,
and which helpers apply.

## Service / unit tests

Plain JUnit + Kotest. No Spring context (or a minimal one via `@ExtendWith`).
Collaborators are mocked or passed directly.

```kotlin
class TagServiceTest {

    private val tagRepository = mockk<TagRepository>()
    private val tagService = TagService(tagRepository)

    @Test
    fun `should create tag`() {
        every { tagRepository.save(any()) } returns savedTag
        // ...
    }
}
```

Defaults:
- No `@SpringBootTest`, no `@Transactional`.
- Collaborators provided directly to the constructor, not injected by Spring.
- Stubbing via MockK (`mockk`, `every`, `verify`) unless the project standard differs.
- Prefer backticked names and Kotest matchers.

## Web slice tests (`@WebMvcTest`)

Loads a controller slice with MockMvc. Service collaborators are replaced with
`@MockkBean` / `@MockBean`.

```kotlin
@WebMvcTest(TalkController::class)
class TalkControllerTest @Autowired constructor(
    private val mockMvc: MockMvc,
) {
    @MockkBean
    private lateinit var talkService: TalkService

    @Test
    fun `GET talk returns 200 with payload`() {
        every { talkService.find(1L) } returns talkDto()

        mockMvc.get("/api/talks/1")
            .andExpect { status { isOk() } }
            .andExpect { jsonPath("$.title") { value("Kotlin") } }
    }
}
```

Defaults:
- Use Spring's Kotlin MockMvc DSL (`mockMvc.get { }`) rather than static MockMvc calls.
- Reuse project helpers for request headers and JSON body parsing when they exist.
- Preserve exact HTTP status and response-body assertions — do not relax.
- `@MockkBean` for MockK projects; `@MockBean` for Mockito projects.

`@MockkBean` is the one place `lateinit var` is conventional — it's required by
the bean-replacement mechanism.

## Integration tests (`@SpringBootTest`)

Full application context. Often combined with `@Transactional` for automatic
rollback, or with a test-data scope helper for commit-boundary scenarios.

```kotlin
@SpringBootTest
@Transactional
@ActiveProfiles("it")
class TalkFlowIT @Autowired constructor(
    private val talkService: TalkService,
    private val speakerService: SpeakerService,
) {

    @Test
    fun `creating a talk wires the primary speaker`() {
        val speaker = speakerService.createSpeaker(createSpeakerRequest())
        val talk = talkService.createTalk(createTalkRequest(primarySpeaker = speaker))

        talk.primarySpeaker.id shouldBe speaker.id
    }
}
```

Defaults:
- Preserve the active profile from the Java source (`@ActiveProfiles("it")` is common).
- Constructor-inject all collaborators.
- Keep transactional/cleanup behavior identical to the Java test — do not
  silently add or drop `@Transactional`.
- For API-level tests (HTTP client against full app), use the project's
  existing test-data scope helper instead of `@Transactional` when visibility
  across commit boundaries matters.

## Slice test variants

- `@DataJpaTest` — repository slice, in-memory by default, `@Transactional` applied.
- `@JsonTest` — serialization-only slice, no HTTP layer.
- `@RestClientTest` — client-side HTTP slice with `MockRestServiceServer`.

For any slice: constructor inject, keep the slice annotation exactly as the
source test specified, and use MockK/Mockito consistently with the project.

## Testcontainers integration

If integration tests depend on Testcontainers (Postgres, Kafka, etc.), ensure
Docker is running before execution. Common signals in the source:
- JDBC URL like `jdbc:tc:postgresql:16-alpine:///db`
- `@Testcontainers` + `@Container` fields
- Profile such as `@ActiveProfiles("it")` that loads a container config

Keep these exactly as written — moving or renaming them usually breaks the
container lifecycle.

## Picking a type when writing a new test

- Pure logic, no Spring collaborators → unit test.
- Only HTTP/controller behavior, no repositories → `@WebMvcTest`.
- Only repository behavior, no HTTP → `@DataJpaTest`.
- Real end-to-end flow across layers → `@SpringBootTest` (+ Testcontainers if DB matters).

Choose the narrowest type that covers the behavior under test. Broader is
slower and hides failures behind more moving parts.
