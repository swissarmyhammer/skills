---
name: detected-projects
description: Use early in a session, before you change code, or when the user asks what kind of project this is or how to build, test, or format it. Gives the project types, commands, and guidelines.
license: MIT OR Apache-2.0
compatibility: Requires the `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
---

# Project Detection

Find the project types of this workspace. Call the verb in the `runCode` tool:

```js
return await tools.code_context.detectProjects({});
```

**Call it early in your session**, before you change a file. The result gives
one project for each language, from the marker file of that language, for
example `Package.swift`, `Cargo.toml`, `pyproject.toml`, `setup.py`,
`package.json` or `go.mod`.

**Read the test rules of each language.** Read the reference file for the `language` of each project. It gives the test commands, the lint commands, how to select integration tests, and how to find skipped tests, a test that does not stop, and tests that share state.

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

   If there is no reference file for the language, use the files of the repository

**Look for the command of the repository.** For each project, look in its directory for a file that gives the real command:
   - a `Makefile` or a `justfile` with a `test` target
   - the `scripts.test` entry of `package.json`
   - `pyproject.toml`, `tox.ini`, or `noxfile.py`
   - `.config/nextest.toml`
   - a test runner script, for example `tests/runtests.py` or `scripts/test.sh`
   - the CI workflow, for example `.github/workflows/*.yml`
   - the `README` or the `CONTRIBUTING` file

   The command of the repository is more important than the default command in the reference file. If the repository does not give a command, use the command of the reference file.

## Example

The user says "how do I run the tests?"

1. `tools.code_context.detectProjects({})` gives one Python project at the root.
2. `tools.files.glob` finds `tox.ini` and `tests/runtests.py`.
3. Report: the project is Python, and the tests run with
   `python tests/runtests.py <module>`.
