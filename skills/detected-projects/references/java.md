# Java Test Rules

## Build tool

Use the wrapper of the repository if it has one: `./mvnw` or `./gradlew`. If it does not, use `mvn` or `gradle`.

| Marker file | Build tool |
|---|---|
| `pom.xml` | Maven |
| `build.gradle` or `build.gradle.kts` | Gradle |

## Commands

Do not search for test files. The build tool finds the tests.

| Purpose | Maven | Gradle |
|---|---|---|
| Unit tests | `./mvnw test` | `./gradlew test` |
| One class | `./mvnw test -Dtest=<Class>` | `./gradlew test --tests '<Class>'` |
| One test | `./mvnw test -Dtest='<Class>#<method>'` | `./gradlew test --tests '<Class>.<method>'` |
| Unit and integration tests | `./mvnw verify` | `./gradlew check` |

## Integration tests

- Maven: the Failsafe plugin runs the `*IT` classes in the `verify` phase. Run one with `./mvnw verify -Dit.test=<Class>`.
- Gradle: the project usually has a task of its own, for example `./gradlew integrationTest`.

Do not use an environment variable to select or skip a test.

## Warnings

Compile with `-Xlint:all -Werror`. Set it in the compiler arguments of the build file. Run the static analysis tools that the build has, for example Checkstyle, SpotBugs, or Error Prone.

## Skipped tests

Find and correct or delete each one: `@Disabled` (JUnit 5), `@Ignore` (JUnit 4), and `assumeTrue` or `assumeFalse` that is false. Also find `-DskipTests` or `-Dmaven.test.skip` in the build files and in the CI files.

## A test that does not stop

- JUnit 5: add `@Timeout(60)`, or set `junit.jupiter.execution.timeout.default = 60s` in `junit-platform.properties`.
- To find the test, run it with the shell `timeout`.

## Tests that share state

- Use `@TempDir` for files.
- When parallel execution is on (`junit.jupiter.execution.parallel.enabled = true`), use `@ResourceLock("<name>")` on tests that share a resource, or `@Isolated` on a class that must run alone.
