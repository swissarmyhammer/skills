# Go Test Rules

## Commands

Do not search for test files. Go finds each `*_test.go` file.

| Purpose | Command |
|---|---|
| All tests | `go test ./...` |
| All tests, with the race detector | `go test -race ./...` |
| One package | `go test ./path/to/pkg` |
| One test | `go test -run '^TestName$' ./path/to/pkg` |
| Vet | `go vet ./...` |
| Lint | `golangci-lint run` or `staticcheck ./...` (the tool that the project uses) |
| Format check | `gofmt -l .` (the output must be empty) |

Go keeps the results of tests in a cache. A result with `(cached)` is a real result for code that did not change. Do not add `-count=1` to run the tests again.

## Integration tests

Put integration tests in their own directory, or give them a build tag. Select them directly:

- `go test ./integration/...`
- `go test -tags integration ./...`, with `//go:build integration` at the top of each integration test file

Do not use an environment variable to select or skip a test.

## Skipped tests

Find and correct or delete each `t.Skip`, `t.Skipf`, and `t.SkipNow`. A test that calls `t.Skip` when `testing.Short()` is true is a skipped test too. Use `go test -v` to see the `SKIP` lines.

## A test that does not stop

`go test` stops a test binary after 10 minutes by default. Set a shorter limit: `go test -timeout 60s ./path/to/pkg`. When the limit stops the binary, Go writes the stack of each goroutine. Read the stack to find the wait.

## Tests that share state

- Use `t.TempDir()` for files and `t.Setenv()` for environment variables. `t.Setenv` does not work in a test that calls `t.Parallel()`.
- Bind port `0` (`net.Listen("tcp", "127.0.0.1:0")`).
- Do not call `t.Parallel()` in a test that changes global state.
