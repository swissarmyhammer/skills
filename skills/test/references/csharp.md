# C# Test Rules

## Commands

Run the commands at the solution (`*.sln` or `*.slnx`) or at the test project (`*.csproj`). Do not search for test files.

| Purpose | Command |
|---|---|
| All tests | `dotnet test` |
| One project | `dotnet test tests/<Project>.Tests` |
| One class or test | `dotnet test --filter "FullyQualifiedName~<Name>"` |
| Build with warnings as errors | `dotnet build -warnaserror` |
| Format check | `dotnet format --verify-no-changes` |

## Integration tests

Put integration tests in a test project of their own, for example `tests/<Project>.IntegrationTests`. Run that project directly. A trait filter is also structural: `dotnet test --filter "Category=Integration"`. Do not use an environment variable to select or skip a test.

## Skipped tests

Find and correct or delete each one:

- xUnit: `[Fact(Skip = "...")]`, `[Theory(Skip = "...")]`
- NUnit: `[Ignore]`, `Assert.Ignore()`
- MSTest: `[Ignore]`, `Assert.Inconclusive()`

## A test that does not stop

Run with `dotnet test --blame-hang-timeout 60s`. It stops the test host after the limit and names the test that ran.

## Tests that share state

xUnit runs the test classes in parallel. Put the classes that share a resource in one collection with `[Collection("<name>")]`. A collection runs one test at a time. Use `Path.GetTempPath()` with a new directory for each test.
