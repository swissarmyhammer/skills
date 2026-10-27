---
name: code-test
description: Use when the user wants to run tests, or after a code change. Takes a scope (named tests, unit, integration, or project), or finds the scope from the change. Runs the tests and analyzes the results.
license: MIT OR Apache-2.0
compatibility: Requires the `tools.shell` and `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
agent: tester
---

# Test

**Zero failures. Zero skipped tests. The build is clean, or it is broken.**

## Scope

The caller gives the scope of the run:

```
$ARGUMENTS
```

| Scope | What to run |
|---|---|
| Named tests: a test name, a suite, or a test file | Only those tests. |
| `unit` | The unit test targets of each project that the change touches. |
| `integration` | The integration targets of each project that the change touches. |
| `project` | All of the unit and integration targets of each project. |

If the caller gives no scope, find it yourself:

1. Find the changed files with `git status --short`, or with `getBlastradius({ scope: "working" })`.
2. Find the project of each changed file, and the test targets that cover it.
3. Run the unit targets of those projects. Add an integration target only when the change is in the code of that integration.
4. If there is no change, use `project`.

Do not run more than the scope. Give the scope in the report.

## Find the Test Command

Do not guess the test command. Find it before you run a test.

**Find the projects.** Call the verb in the `runCode` tool:

   ```js
   return await tools.code_context.detectProjects({});
   ```

   The result gives the language and the directory of each project. It does not give a command. A workspace can have more than one project, for example a Rust crate and a TypeScript web app. Each project has its own test command. Run the command of each project in the scope.

**Find the command of each project.** Follow "Project detection" in the `code-analyzing` skill. It gives the reference file of each language, and the files of the repository that give the real command. In this skill, "the reference file of the language" is that file.

## Unit Tests and Integration Tests

- **Unit tests are fast, and they give coverage.** A unit test examines the logic of the code. It does not need an external system.
- **Integration tests can be slower.** They use real scenarios, for example a real model, a real database, or a real server. CI runs them. Run them only when the scope has them. Select each integration target directly with the test tool of the platform. The reference file of the language tells how.

## Rules

- All of the tests must pass. A partial pass is a failure.
- For each scope except named tests, run the type check and the linter of each project in the scope. Treat errors as failed tests.
- Do not run the same tests again if the code did not change. The result is the same. This wastes time and tokens.
- When tests fail, do work only on the failures. After each correction, run only the tests that failed. At the end, run the scope one more time.
- Do not run tests in a loop to solve 'flaky tests'. Do not use `for i in {1..N}`, `--count=N`, or `--repeat`.
- A skipped test is broken or it is dead. Correct a broken test. Delete a dead test. A skipped test is not acceptable.
- Do not hide a warning. Do not use `#[allow(...)]`, `@suppress`, or `// eslint-disable`.
- Do not skip a test to stop a failure. Do not use `#[ignore]` or `skip`.
- Do not prove by hand that a test is not vacuous (change the source, run the test, see it fail, and then undo the change). You cannot keep this proof or run it again. If the proof needs a change to the item under test, make that change a permanent test case:
  - Assert the literal value, not only the symbol. For example, write `assert_eq!(CONST, "haiku")`. Do not compare two values that both come from the same symbol.
  - Or, in the test, set an explicit override and assert the different result.

## Process

1. **Run the tests of the [scope](#scope) one time.** Use the commands that you found in [Find the Test Command](#find-the-test-command).
2. **Run the type check and the linter of each project in the scope**, except for named tests. Make warnings into errors.
3. **Find the skipped tests and the ignored tests.** Correct or delete each one.
4. **Make a list of the failures and the warnings** from the output of step 1. This list is your work. Do not run the suite again to make the list.
5. **Correct each failure and each warning on the list.** Before you change code, find the cause:

   ```js
   const source = await tools.code_context.getSymbol({ query: "<failing function>", maxResults: 1 });
   const callers = await tools.code_context.getCallgraph({ symbol: "<failing function>", direction: "inbound", maxDepth: 2 });
   return { source, callers };
   ```

   If you change a shared symbol, use `getBlastradius({ file, symbol })` to find the tests in other locations that the change can break. After a correction, run only the tests that failed, one time. Do not run the scope after each correction.
6. **When the list is empty, run the scope one last time.** If there are new failures, go to step 4 with only the new failures.

## Report

Give the result, `green`, `red`, or `stuck`, and the scope. Then give each command that you ran, with its counts. For example, for a workspace with a Rust project and a TypeScript project:

```
green (unit): cargo nextest run — 1284 passed, 0 failed, 0 skipped; cargo clippy --all-targets -- -D warnings clean; pnpm test — 212 passed, 0 failed, 0 skipped; tsc --noEmit clean
```

Report `green` only after a full run of the scope passes. If the run stopped before the end, the result is not `green`. Say what you ran.

Report `red` or `stuck` along with a list of specific failed tests.

## Troubleshooting

### There are no tests

Write one test to start.

### One test does not stop, and the suite does not finish

Run the tests with a hard time limit for each test, and find the test that does not stop. The reference file of the language tells how to set the limit. If the runner has no limit, run one suspect test with the shell command `timeout`, for example `timeout 60 <command for one test>`.

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

All failures are related, report them.
