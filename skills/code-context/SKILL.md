---
name: code-context
description: Use when the user says "find symbol", "go to definition", "find references", "who calls this", "callgraph", or "blast radius". The symbol index is faster and more exact than a text search.
license: MIT OR Apache-2.0
compatibility: Requires the `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
---

# Code Context

`tools.code_context` is structural code intelligence: an index of symbols, a
call graph, and blast radius analysis, from tree-sitter and live language
servers. Use it instead of reading full files of code.


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

This example finds a symbol, gives its source and gives its callers in one call:

```js
const found = await tools.code_context.searchSymbol({ query: "<name>", maxResults: 5 });
const source = await tools.code_context.getSymbol({ query: "<Class.method>", maxResults: 1 });
const callers = await tools.code_context.getCallgraph({ symbol: "<Class.method>", direction: "inbound", maxDepth: 2 });
return { found, source, callers };
```

## How to call the verbs

The code context is a group of verbs in code mode. Call them in the `runCode`
tool, as JavaScript. Each verb takes one object and gives a parsed JSON object.
Return the part of the result that you need.

```js
const r = await tools.code_context.getSymbol({ query: "Model.save", maxResults: 3 });
return r;
```

A file path is relative to the workspace root. A `line` and a `character` are
0-based. One `runCode` call can make many verb calls, thus do a lookup and its
follow-up in one snippet.

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

// Live language server, at a position (0-based line and character)
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

`searchCode` ranks by the meaning of the text. A host can turn that rank off.
Then `searchCode` answers with an error that says the embedding layer is off:
use `grepCode` and `searchSymbol`.

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

## Example

The user says "who calls `authenticate` and what breaks if I change its
signature?"

```js
const found = await tools.code_context.getSymbol({ query: "authenticate", maxResults: 3 });
const callers = await tools.code_context.getCallgraph({ symbol: "authenticate", direction: "inbound", maxDepth: 2 });
return { found, callers };
```

If `callers` is empty, ask the language server at the position of the name:

```js
const uses = await tools.code_context.getReferences({ file: "a/auth.py", line: 41, character: 8, maxResults: 50 });
return uses;
```

Then report the definition, the callers or the uses, and the files that the
change affects.
