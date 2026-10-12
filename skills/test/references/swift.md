# Swift Test Rules

## Test runner

- SwiftPM (`Package.swift`): `swift test`.
- Xcode (`*.xcodeproj` or `*.xcworkspace` and no `Package.swift`): `xcodebuild test`.

Do not search for test files. The runner finds the tests. A package can use XCTest, Swift Testing, or the two together. `swift test` runs both.

## Commands

| Purpose | Command |
|---|---|
| All tests | `swift test` |
| One test | `swift test --filter '<TestTarget>.<Suite>/<test>'` |
| Build with warnings as errors | `swift build --build-tests -Xswiftc -warnings-as-errors` |
| Xcode, all tests | `xcodebuild test -scheme <Scheme> -destination 'platform=macOS'` |
| Xcode, one test | add `-only-testing:<TestTarget>/<Suite>/<test>` |

`--filter` takes a regular expression, and the name of the target is part of the match.

## Integration tests

Put an integration test in its own package or test target. Select it directly:

- `swift test --package-path IntegrationTests`
- `swift test --filter '<IntegrationTestTarget>'`

## Lint and format

Use the tool whose configuration file the repository has, and obey that file:

| Tool | Check command | Configuration file |
|---|---|---|
| Apple swift-format | `swift format lint -s -r Sources Tests` | `.swift-format` |
| SwiftFormat | `swiftformat --lint .` | `.swiftformat` |
| SwiftLint | `swiftlint --strict` | `.swiftlint.yml` |

`swift format` and `swiftformat` are different programs. Keep `-s` on `swift format lint`. Without it, the command reports warnings but the exit code is 0.

## Skipped tests

Find and correct or delete each one:

- XCTest: `throw XCTSkip(...)`, `XCTSkipIf`, `XCTSkipUnless`
- Swift Testing: the `.disabled(...)` trait, and an `.enabled(if:)` trait that is false

## A test that does not stop

- Swift Testing: add the `.timeLimit(.minutes(1))` trait.
- XCTest: set `executionTimeAllowance`. With `xcodebuild`, also give `-test-timeouts-enabled YES`.
- To find the test, run one suspect test with the shell `timeout`: `timeout 120 swift test --filter '<test>'`.

## Tests that share state

Swift Testing runs tests in parallel by default. If tests in a suite must not run at the same time, add the `.serialized` trait to the suite. Use a new temporary directory for each test. Do not change the current directory of the process.

## Clean the build directory

`.build/` gets larger with each build. At the start of a new task, run `swift package reset` one time. Use `swift package clean` for a rebuild in a task.
