---
name: detected-projects
description: Discover project types, build commands, test commands, and language-specific guidelines for the current workspace. Use when the user says "what kind of project", "detect project", "build command", "test command", "project type", asks what language or framework the code uses, or wants to know how to build, test, or format the project. Also use early in any session before making changes.
license: MIT OR Apache-2.0
compatibility: Requires the `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
metadata:
  author: swissarmyhammer
  version: "1.0.0"
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

Use the result to select the commands of the project:

- the language and the root directory of each project;
- the test command of that language, for example `python -m pytest`,
  `cargo test`, `swift test`, `go test ./...` or `npm test`;
- the build and format commands of that language.

Before you run a command, look for the file of the repository that gives the
real command: a `README`, a `Makefile`, a `tox.ini`, a `pyproject.toml`, or a
test runner script such as `tests/runtests.py`. The command of the repository
wins over the default command of the language.

Run the commands with `tools.shell.execute`.

## Example

The user says "how do I run the tests?"

1. `tools.code_context.detectProjects({})` gives one Python project at the root.
2. `tools.files.glob` finds `tox.ini` and `tests/runtests.py`.
3. Report: the project is Python, and the tests run with
   `python tests/runtests.py <module>`.
