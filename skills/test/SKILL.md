---
name: test
description: Run tests and analyze results. Use when the user wants to run the test suite or test specific functionality.
license: MIT OR Apache-2.0
compatibility: Requires the `tools.shell` and `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
agent: tester
metadata:
  author: swissarmyhammer
  version: "1.0.0"
---

# Test

**Zero failures. Zero skipped tests. The build is clean, or it is broken.**

## Find the Test Command

Do not guess the test command. Find it before you run a test.

1. **Find the projects.** Call the verb in the `runCode` tool:

   ```js
   return await tools.code_context.detectProjects({});
   ```

   The result gives the language and the directory of each project. It does not give a command. A workspace can have more than one project, for example a Rust crate and a TypeScript web app. Each project has its own test command, and you must run all of them.

2. **Read the test rules of each language.** Read the reference file for the `language` of each project. It gives the test commands, the lint commands, how to select integration tests, and how to find skipped tests, a test that does not stop, and tests that share state.

   | `language` | Reference |
   |---|---|
   | `rust` | [rust.md](references/rust.md) |
   | `swift` | [swift.md](references/swift.md) |
   | `python` | [python.md](references/python.md) |
   | `javascript`, `typescript`, `tsx` | [typescript.md](references/typescript.md) |
   | `go` | [go.md](references/go.md) |
   | `java` | [java.md](references/java.md) |
   | `csharp` | [csharp.md](references/csharp.md) |
   | `c`, `cpp` | [c-cpp.md](references/c-cpp.md) |
   | `ruby` | [ruby.md](references/ruby.md) |
   | `php` | [php.md](references/php.md) |
   | `elixir` | [elixir.md](references/elixir.md) |

   If there is no reference file for the language, use the files of the repository in step 3 to find the commands.

3. **Look for the command of the repository.** For each project, look in its directory for a file that gives the real command:
   - a `Makefile` or a `justfile` with a `test` target
   - the `scripts.test` entry of `package.json`
   - `pyproject.toml`, `tox.ini`, or `noxfile.py`
   - `.config/nextest.toml`
   - a test runner script, for example `tests/runtests.py` or `scripts/test.sh`
   - the CI workflow, for example `.github/workflows/*.yml`
   - the `README` or the `CONTRIBUTING` file

   The command of the repository is more important than the default command in the reference file. If the repository does not give a command, use the command of the reference file.

4. **Run the command in the directory of the project** with `tools.shell.execute`. Use the command that you found, not the example below:

   ```js
   return await tools.shell.execute({ command: "<the test command that you found>", workingDirectory: "<the directory of the project>" });
   ```

## Run the Tests One Time

**A test run is a measurement. Do it one time. Then do work on the result.**

- Run the suite one time. Read the output. The output tells you which tests failed.
- Do not run the same tests again if the code did not change. The result is the same. This wastes time and tokens.
- Do not run tests in a loop. Do not use `for i in {1..N}`, `--count=N`, or `--repeat`.
- Do not run the suite again to make sure of a pass or a failure. One run is sufficient.
- When tests fail, do work only on the failures. After each correction, run only the tests that failed. At the end, run the full suite one more time.
- Keep the output of the run. To see the output again, read the output that you kept. Do not run the tests again.

## Unit Tests and Integration Tests

- **Unit tests are fast, and they give coverage.** A unit test examines the logic of the code. It does not need an external system. Each test run includes all of the unit test targets.
- **Integration tests can be slower.** They use real scenarios, for example a real model, a real database, or a real server. CI runs them. Run them yourself only when it is necessary, usually when your change is in that integration. Then select that integration target directly with the test tool of the platform. The reference file of the language tells how. If your change is not in the integration, let CI run these tests.
- **Select tests only with the structure of the platform. Do not use an environment variable.** An integration test is in its own target or package, and the default test command does not see it. Select tests only with the filters of the platform: targets, packages, paths, and registered markers. Do not set or read an environment variable to select, skip, or change tests.

## Rules

- All of the tests must pass. A partial pass is a failure.
- Correct all of the warnings. A warning is a bug that did not cause a failure yet.
- A skipped test is broken or it is dead. Correct a broken test. Delete a dead test. A skipped test is not acceptable.
- Do not hide a warning. Do not use `#[allow(...)]`, `@suppress`, or `// eslint-disable`.
- Do not skip a test to stop a failure. Do not use `#[ignore]` or `skip`.
- Do not prove by hand that a test is not vacuous (change the source, run the test, see it fail, and then undo the change). You cannot keep this proof or run it again. If the proof needs a change to the item under test, make that change a permanent test case:
  - Assert the literal value, not only the symbol. For example, write `assert_eq!(CONST, "haiku")`. Do not compare two values that both come from the same symbol.
  - Or, in the test, set an explicit override and assert the different result.

## Process

1. **Run the full test suite of each project one time.** Use the commands that you found in [Find the Test Command](#find-the-test-command). The full suite is all of the unit test targets. Add the integration targets that your change touches. CI runs all of them.
2. **Run the type check and the linter of each project.** Make warnings into errors.
3. **Find the skipped tests and the ignored tests.** Correct or delete each one.
4. **Make a list of the failures and the warnings** from the output of step 1. This list is your work. Do not run the suite again to make the list.
5. **Correct each failure and each warning on the list.** Before you change code, find the cause:

   ```js
   const source = await tools.code_context.getSymbol({ query: "<failing function>", maxResults: 1 });
   const callers = await tools.code_context.getCallgraph({ symbol: "<failing function>", direction: "inbound", maxDepth: 2 });
   return { source, callers };
   ```

   If you change a shared symbol, use `getBlastradius({ file, symbol })` to find the tests in other locations that the change can break. After a correction, run only the tests that failed, one time. Do not run the full suite after each correction.
6. **When the list is empty, run the full suite one last time.** If there are new failures, go to step 4 with only the new failures.

## Report

Give the result, `green`, `red`, or `stuck`. Then give each command that you ran, with its counts. For example, for a workspace with a Rust project and a TypeScript project:

```
green: cargo nextest run — 1284 passed, 0 failed, 0 skipped; cargo clippy --all-targets -- -D warnings clean; pnpm test — 212 passed, 0 failed, 0 skipped; tsc --noEmit clean
```

Report `green` only after a full run passes. If you ran only one test, or if the run stopped before the end, the result is not `green`. Say what you ran.

## Troubleshooting

### There are no tests

Write one test to start.

### One test does not stop, and the suite does not finish

The test waits for something that CI cannot supply, for example a network, a child process, a file watcher, or a deadlock. Run the tests with a hard time limit for each test, and find the test that does not stop. The reference file of the language tells how to set the limit. If the runner has no limit, run one suspect test with the shell command `timeout`, for example `timeout 60 <command for one test>`.

Run that one test again with more log output, for example `--verbose`, to find what it waits for. Correct the cause.

### Tests pass one at a time but fail in parallel ("address in use", missing files)

The tests share a state that changes, for example the current directory, an environment variable, a fixed port, or a shared temporary file. Give each test its own temporary directory, and bind port `0`. If tests must not run at the same time, use the isolation method of the language on only those tests. The reference file of the language tells how. Do not stop parallel runs for all of the tests, for example with `--test-threads=1`. It hides the bug.

### A test is flaky (it fails one time and passes a different time)

The cause is something that is not deterministic, for example timing, an iteration with no order, the clock, or an external state. Do not run the test in a loop to find the cause. Read the test and the code under test. Find the cause in the code:

- An iteration over a `HashMap`, `HashSet`, `dict`, or `Set` with no sort
- A `sleep`, a timeout, or a wait for a background task
- The system clock, or a random number generator with no seed
- A shared port, current directory, environment variable, or temporary file

Remove the cause. Sort the iteration, inject a clock, give a seed to the random number generator, or wait for a signal and not for a timer. Do not add retries. Then run the test one time.

### Failures that are not related to your change

All failures are related. Your job is to correct all of the tests that fail.
