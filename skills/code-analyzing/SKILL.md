---
name: code-analyzing
description: Use to find and search code symbols, definitions, references, usage, and impact. Also use early in a session to find the project types and how to build, test, or format them.
compatibility: Requires the `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
---

# Code Analyzing

`tools.code_context` is structural code intelligence: an index of symbols, a
call graph, and blast radius analysis, from tree-sitter LSP servers.

**Rule:** Before you call `tools.files.read` or `tools.files.grep` on a code
file, call a `tools.code_context` verb.

| You want | Do not use | Use |
|---|---|---|
| The parts of a file | `files.read` of the full file | `listSymbol({ file })` |
| The source of a function or a class | `files.read` with `offset` and `limit` | `getSymbol({ query: "Class.method" })` |
| The definition of a name | `files.grep` for `def name` or `class Name` | `searchSymbol({ query })`, then `getSymbol({ query })` |
| The callers of a function | `files.grep` for the name | `getCallgraph({ symbol, direction: "inbound" })` |
| All uses of a name | `files.grep` for the name in a directory | `getReferences({ file, line, character })` or `grepCode({ pattern })` |
| The code that holds a text | `files.grep` with `outputMode: "filesWithMatches"` | `grepCode({ pattern, filePattern })` |
| The tests for a symbol | `files.grep` in `tests/` | `grepCode({ pattern: "<name>", filePattern: "*test*" })` |
| The effect of a change | many `files.grep` calls | `getBlastradius({ file, symbol })`, or `getBlastradius({ scope: "working" })` for the changes that you made |

## How to call the verbs

The code context is a group of verbs in code mode. Call them in the `runCode`
tool, as JavaScript. Each verb takes one object and gives a parsed JSON object.
Return the part of the result that you need.

```js
const r = await tools.code_context.getSymbol({ query: "Model.save", maxResults: 3 });
return r;
```

## Project detection

**Call `detectProjects` early in your session**, before you change a file:

```js
return await tools.code_context.detectProjects({});
```

The result gives one project for each language, from the marker file of that
language, for example `Package.swift`, `Cargo.toml`, `pyproject.toml`,
`setup.py`, `package.json` or `go.mod`.

**Read the test rules of each language.** Read the reference file for the
`language` of each project. It gives the test commands, the lint commands, how
to select integration tests, and how to find skipped tests, a test that does
not stop, and tests that share state.

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

If there is no reference file for the language, use the files of the
repository.

**Look for the command of the repository.** For each project, look in its
directory for a file that gives the real command:

- a `Makefile` or a `justfile` with a `test` target
- the `scripts.test` entry of `package.json`
- `pyproject.toml`, `tox.ini`, or `noxfile.py`
- `.config/nextest.toml`
- a test runner script, for example `tests/runtests.py` or `scripts/test.sh`
- the CI workflow, for example `.github/workflows/*.yml`
- the `README` or the `CONTRIBUTING` file

The command of the repository is more important than the default command in
the reference file. If the repository does not give a command, use the command
of the reference file.

## The verbs

```js
// Symbols, from the index
await tools.code_context.getSymbol({ query: "Model.save", maxResults: 5 });
await tools.code_context.searchSymbol({ query: "handler", kind: "function", maxResults: 10 });
await tools.code_context.listSymbol({ file: "django/db/models/base.py" });

// Text and structure, from the index
await tools.code_context.grepCode({ pattern: "raise ValueError\\(.*primary key", filePattern: "*.py", maxResults: 20 });
await tools.code_context.searchCode({ query: "where the admin builds the app list", topK: 10 });
await tools.code_context.queryAst({ language: "python", astQuery: "(function_definition) @function" });
await tools.code_context.findDuplicates({ file: "src/parser.py" });

// Impact
await tools.code_context.getCallgraph({ symbol: "Model.save", direction: "inbound", maxDepth: 2 });
await tools.code_context.getBlastradius({ file: "django/db/models/base.py", symbol: "save", maxHops: 3 });
await tools.code_context.getBlastradius({ scope: "working", maxHops: 3 });
await tools.code_context.getBlastradius({ scope: "sha", sha: "HEAD~1", maxHops: 3 });

// Live language server, at a position (1-based line and character)
await tools.code_context.getDefinition({ file: "a.py", line: 41, character: 8, includeSource: true });
await tools.code_context.getTypeDefinition({ file: "a.py", line: 41, character: 8 });
await tools.code_context.getHover({ file: "a.py", line: 41, character: 8 });
await tools.code_context.getReferences({ file: "a.py", line: 41, character: 8, maxResults: 50 });
await tools.code_context.getImplementations({ file: "a.py", line: 41, character: 8 });
await tools.code_context.getInboundCalls({ file: "a.py", line: 41, character: 8 });
await tools.code_context.searchWorkspaceSymbol({ query: "AdminSite" });
await tools.code_context.getRenameEdits({ file: "a.py", line: 41, character: 8, newName: "build_app_dict" });
await tools.code_context.getCodeActions({ file: "a.py", startLine: 41, startCharacter: 0, endLine: 41, endCharacter: 20 });
await tools.code_context.getDiagnostics({ scope: "working" });

// Health
await tools.code_context.getStatus({});
await tools.code_context.getLspStatus({});
await tools.code_context.detectProjects({});
await tools.code_context.rebuildIndex({ layer: "treesitter" });
```


## Process

1. **Orient.** Call `getStatus({})` to see the active layers. If
   `ARCHITECTURE.md` is at the project root, read it.
2. **Survey.** Search wide with the words of the problem: `searchSymbol`. If
   the index is not complete, also use `grepCode` and `listSymbol`.
3. **Trace.** Get the source with `getSymbol`. Go to definitions and types with
   `getDefinition` and `getHover`. Get the calls in the two directions with
   `getCallgraph({ symbol, direction: "both", maxDepth: 2 })`.
4. **Scope.** Measure the blast radius with `getBlastradius`, and also call
   `getReferences`.
5. **Tests.** Find the tests of a symbol with
   `grepCode({ pattern: "<name>", filePattern: "*test*" })`.

If the blast radius is a surprise, or the call graph goes to new code, go back
to step 2 with new words. Each loop must make the area smaller. After 3 loops
with no result, stop. Tell the user what is not clear, and ask.

## How the results behave

- A `grepCode` hit gives the innermost symbol that holds it. A hit in one
  method gives that method, not the class around it. To find a method or a
  class by name, use `searchSymbol` or `getSymbol`, not a pattern such as
  `def name`.
- `getInboundCalls` asks the server now. `getCallgraph` reads the indexed
  edges, and it goes more levels.
- The blast radius follows call edges only. `getReferences` also finds the
  uses of a type, the access to a field and the implementations of an
  interface.
- **An empty blast radius does not mean "nothing is affected".** Examine it
  with `getReferences` on the symbol and with `grepCode` on its name.
- Each result has a `source_layer`: `lsp` (the full precision of the language
  server), `treesitter` (the structure from the index), or `treesitter+lsp`.

## The index fills in the background

The index starts when the session starts, and a large repository takes some
minutes. `getStatus({})` gives the progress. Do not wait for it:

- `listSymbol`, `getSymbol`, `searchSymbol` and `grepCode` answer from the files
  that the index already holds. An empty result early in a session can mean
  "not indexed yet". Try again later, or use `tools.files.grep` for that one
  search.
- The live language server verbs (`getDefinition`, `getHover`, `getReferences`,
  `searchWorkspaceSymbol`) work immediately.
- An empty `getCallgraph` or `getBlastradius` for code that clearly has callers
  usually means that the language server layer is not complete yet. Use
  `getInboundCalls` at the position of the symbol, which asks the server now.
  Look at `getLspStatus({})` only to see whether the server runs.

## Language servers

- **Only `treesitter` results for a language that must have a server:** call
  `getLspStatus({})`. The host installs an absent server when it can, and that
  takes some minutes. Do not install a server yourself. Continue with the
  tree-sitter results.
- **A server answers only the methods that it has.** A result with
  `notSupportedReason` means that the server does not have the method. An
  empty result without that field means that the code holds no match. Python's
  `pylsp` has no call hierarchy, thus `getCallgraph`, `getBlastradius` and
  `getInboundCalls` answer from references. It has no `searchWorkspaceSymbol`
  (use `searchSymbol`) and no `getImplementations` (use `getReferences`).
- **`clangd` gives no symbols:** it needs a `compile_commands.json` file.
  Without it, use the tree-sitter verbs for C and C++ files.
- **The servers run, but the call graph is empty:** mark the language server
  layer dirty with `rebuildIndex({ layer: "lsp" })`, and let the index fill
  again.

## Line numbers start at 1

Each line and each column in a verb input and in a verb result starts at 1,
the same as `files.read`, `files.grep` and `files.edit`. Give a line from a
result directly to `files.read` or `files.edit`. Do not add 1 and do not
subtract 1.

A result that holds source `text` with a `startLine` starts that text at
`startLine`. Line `n` of the text, counted from 0, is line `startLine + n` of
the file.

## Report

Use this report when you answer a question about code. When you complete a
change, use the report of the `code` skill.

Report code as `grep -n` does: the file, the line number and the text of each
line. Use the line numbers from the result. Do not count the lines yourself.

- Write a line that matches or that you discuss as `file:line:text`.
- Write a line that shows only the context as `file-line-text`.
- Write `--` between two groups of lines that are not adjacent.
- Put the lines in a fenced code block.

```text
django/contrib/auth/__init__.py:63:def authenticate(request=None, **credentials):
django/contrib/auth/__init__.py-64-    """
django/contrib/auth/__init__.py-65-    If the given credentials are valid, return a User object.
--
django/contrib/auth/views.py:88:        user = authenticate(self.request, **form.cleaned_data)
```

For a call graph or a blast radius, give one line for each caller or each
affected symbol, at the line of the call. A call graph node has no line. Get
the line with `getSymbol` or `getInboundCalls`.

Give only the lines that answer the question. Do not give a full symbol when
two lines show the answer.

After the lines, tell these three things:

- **How it works:** what calls what, and where the data goes.
- **Where it is:** the files and the symbols.
- **What it affects:** the blast radius of a change.

If you cannot tell all three, the analysis is not complete. Go back to the
verbs. Do not fill a gap with a guess.
