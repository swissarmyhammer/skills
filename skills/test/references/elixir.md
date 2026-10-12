# Elixir Test Rules

## Commands

Do not search for test files. `mix test` finds each `*_test.exs` file.

| Purpose | Command |
|---|---|
| All tests | `mix test` |
| One file | `mix test test/<file>_test.exs` |
| One test | `mix test test/<file>_test.exs:<line>` |
| Tests with a tag | `mix test --only <tag>` |
| Warnings as errors | `mix compile --warnings-as-errors` and `mix test --warnings-as-errors` |
| Format check | `mix format --check-formatted` |
| Lint | `mix credo --strict` (if the project uses Credo) |

## Integration tests

Give integration tests a tag, for example `@moduletag :integration`. Exclude the tag by default in `test/test_helper.exs` with `ExUnit.configure(exclude: [:integration])`. Select the tests with `mix test --only integration`. Do not use an environment variable to select or skip a test.

## Skipped tests

Find and correct or delete each `@tag :skip` and `@moduletag :skip`.

## A test that does not stop

ExUnit stops a test after 60 seconds by default. To change the limit for one test, use `@tag timeout: 30_000`. To change it for a run, use `mix test --timeout 30000`.

## Tests that share state

A module with `use ExUnit.Case, async: true` runs in parallel with other async modules. If a module changes global state (the application environment, a named process, a file), use `async: false`. With Ecto, use the SQL sandbox so that each test has its own transaction.
