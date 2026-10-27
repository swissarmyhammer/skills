# Rust Test Rules

## Test runner

You can use `cargo nextest` or `cargo test`. Use `cargo nextest` when it is installed, because it is faster: it runs the tests of all of the test binaries in parallel. It also uses the `slow-timeout` and `terminate-after` limits of `.config/nextest.toml`, so it stops a test that does not stop. `cargo test` has no time limit for each test.

To find if nextest is installed, run `cargo nextest --version`. If it is not installed, use `cargo test`.

Do not search for test files. Run the command from the root of the workspace. It finds the tests.

## Commands

| Purpose | `cargo nextest` | `cargo test` |
|---|---|---|
| All tests | `cargo nextest run --workspace` | `cargo test --workspace` |
| One package | `cargo nextest run --package <name>` | `cargo test --package <name>` |
| One test | `cargo nextest run <test_name>` | `cargo test <test_name>` |
| One integration test target | `cargo nextest run --test <name>` | `cargo test --test <name>` |
| A changed crate and the crates that use it | `cargo nextest run -E 'rdeps(<crate>)'` | not available |
| Doctests | not available, use `cargo test --doc` | `cargo test --doc` (also in `cargo test --workspace`) |

| Purpose | Command |
|---|---|
| Lint | `cargo clippy --workspace --all-targets -- -D warnings` |
| Format check | `cargo fmt --check` |

Nextest does not run doctests. If you use nextest and the crate has doctests, also run `cargo test --doc`.

## Integration tests

An integration test is a file in `tests/`, or a crate of its own. Select it with `--test <name>` or `--package <crate>`. Do not use an environment variable to select or skip it.

## Skipped tests

Find each `#[ignore]` with `tools.code_context.grepCode({ pattern: "#\\[ignore" })`. Correct the test or delete it.

## A test that does not stop

With nextest, set a limit in `.config/nextest.toml`:

```toml
[profile.default]
slow-timeout = { period = "60s", terminate-after = 2 }
```

`cargo test` has no limit. To find the test, run one suspect test with the shell `timeout`: `timeout 60 cargo test <test_name>`.

## Tests that share state

Nextest runs each test in its own process, so tests do not share memory. `cargo test` runs the tests of one binary as threads in one process, so they share memory, global state, the environment variables, and the current directory. With both runners, tests can share files and ports.

- Use `tempfile::TempDir` for files. Bind port `0`.
- If tests must not run at the same time, use `#[serial_test::serial]`, or a nextest test group:

  ```toml
  [test-groups]
  serial = { max-threads = 1 }

  [[profile.default.overrides]]
  filter = 'test(/^db::/)'
  test-group = 'serial'
  ```

## Clean the build directory

`target/` gets larger with each build, and a large `target/` makes the tests slow. Run `cargo clean` one time each day, not between test runs.
