---
name: code-context
description: >-
  Code context verbs for symbol lookup, search, grep, call graph, and blast
  radius analysis. Use when the user says "blast radius", "who calls this",
  "find symbol", "find references", "go to definition", "symbol lookup",
  "callgraph", "find callers", "what calls this function", or "what's affected
  if I change this". Also use before you change code, to know its structure,
  its callers and its impact: list the symbols of a file, get the inbound call
  graph of a symbol, and get the blast radius of a shared symbol. The index is
  faster and more exact than a raw text search.
license: MIT OR Apache-2.0
compatibility: Requires the `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
metadata:
  author: swissarmyhammer
  version: "1.0.0"
---

# Code Context

`tools.code_context` is structural code intelligence: an index of symbols, a
call graph, and blast radius analysis, from tree-sitter and live language
servers. Use it as a normal part of the task.

Do not read a file from top to bottom. Do not guess where a symbol is, or what
calls it. The verbs answer those questions exactly, and at a low cost.

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

## When to use which verb

- **Before you read a file:** `listSymbol({ file })` gives the table of
  contents. Then `getSymbol({ query })` gives only the source text that you
  need. A full file read is the fallback.
- **To find code by name:** `searchSymbol({ query, kind })` is a fuzzy match.
  `kind` is `"function"`, `"method"`, `"type"` or `"other"`.
- **To find code by pattern:** `grepCode({ pattern, filePattern })` runs a
  regular expression on the indexed chunks.
- **Before you change a symbol:** `getCallgraph({ symbol, direction: "inbound" })`
  gives its callers. For a shared or public symbol, also
  `getBlastradius({ file, symbol })`. If the result is a surprise, you do not
  know the change well enough yet.
- **After you change a signature:** look at each inbound caller again.
- **When a test fails:** `getCallgraph({ symbol })` on the symbol that fails
  shows what the failure reaches.
- **To see errors:** `getDiagnostics({ scope: "working" })` gives the errors and
  the warnings of the files that you changed.

## The verbs

```js
// Symbols, from the index
await tools.code_context.getSymbol({ query: "Model.save", maxResults: 5 });
await tools.code_context.searchSymbol({ query: "handler", kind: "function", maxResults: 10 });
await tools.code_context.listSymbol({ file: "django/db/models/base.py" });

// Text and structure, from the index
await tools.code_context.grepCode({ pattern: "def get_.*queryset", filePattern: "*.py", maxResults: 20 });
await tools.code_context.searchCode({ query: "where the admin builds the app list", topK: 10 });
await tools.code_context.queryAst({ language: "python", astQuery: "(function_definition) @function" });
await tools.code_context.findDuplicates({ file: "src/parser.py" });

// Impact
await tools.code_context.getCallgraph({ symbol: "Model.save", direction: "inbound", maxDepth: 2 });
await tools.code_context.getBlastradius({ file: "django/db/models/base.py", symbol: "save", maxHops: 3 });

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
  means that the language server layer is not complete. Look at
  `getLspStatus({})`, and use `getReferences` or `getInboundCalls` at the
  position of the symbol.

## When to use the file verbs

Use `tools.files.read` and `tools.files.grep` for files that are not code (TOML,
YAML, Markdown), for string literals and configuration values, and to see the
exact text after a code context verb gave you the location.

## Example

The user says "who calls `authenticate` and what breaks if I change its
signature?"

```js
const found = await tools.code_context.getSymbol({ query: "authenticate", maxResults: 3 });
const callers = await tools.code_context.getCallgraph({ symbol: "authenticate", direction: "inbound", maxDepth: 2 });
return { found, callers };
```

Then get the blast radius of the file that `found` names, and report the
definition, the callers, and the files that the change affects.
