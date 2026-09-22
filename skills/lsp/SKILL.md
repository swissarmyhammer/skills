---
name: lsp
description: >-
  Diagnose the language servers of the workspace. Use when the user says "lsp",
  "language servers", "check lsp", or wants to make sure that code intelligence
  works. Also use when a position verb (`getHover`, `getDefinition`,
  `getReferences`) gives an empty result, or when `getCallgraph` gives no edges
  for code that clearly has callers.
license: MIT OR Apache-2.0
compatibility: Requires the `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
metadata:
  author: swissarmyhammer
  version: "1.0.0"
---

# LSP

Diagnose the language servers behind `tools.code_context`. When a position verb
gives nothing, or the call graph has no edges, the usual cause is a language
server that is absent or not ready.

## Process

### 1. Get the status

Call the verbs in the `runCode` tool:

```js
const servers = await tools.code_context.getLspStatus({});
const projects = await tools.code_context.detectProjects({});
const index = await tools.code_context.getStatus({});
return { servers, projects, index };
```

### 2. Read the result

- `getLspStatus` gives the state of each language server that the workspace
  manages: whether it runs, whether it failed, and whether its binary was not
  found.
- `detectProjects` gives the languages of the workspace. A language with no
  server in the status has no language server layer.
- `getStatus` gives the progress of each index layer. A language server layer
  that is not complete gives an empty call graph for some files.

### 3. Act

- **Each server runs:** report that, and do no more.
- **A server is not found:** the host installs an absent server
  automatically when it can, and that takes some minutes. Look at the status
  again later. Do not install a server yourself unless the user tells you to.
- **A server failed:** report its name and its message. Then continue the task
  with the verbs that need no language server: `getSymbol`, `searchSymbol`,
  `listSymbol`, `grepCode` and `queryAst`.

### 4. Verify with a live verb

Ask for a definition at the name of a symbol that you know:

```js
return await tools.code_context.getDefinition({ file: "<file>", line: <line>, character: <col> });
```

A result that is not empty shows that a language server answers. Do not verify
with `searchWorkspaceSymbol`: a server may not have that method, and Python's
`pylsp` does not.

## Troubleshooting

### A position verb still gives nothing after the server runs

The server indexes the workspace after it starts. For a large repository this
is some minutes. Try again later. Make sure that `line` and `character` are
0-based, and that they point at the name of the symbol.

### `clangd` gives no symbols

`clangd` needs a `compile_commands.json` file. Without it, use the tree-sitter
verbs for C and C++ files.

### A verb gives nothing, and the server runs

A server answers only the methods that it has. For a method that it does not
have, it answers "method not found", and the verb gives you nothing. The state
in `getLspStatus` stays `running`, because the server is healthy.

| Language, server | The server does not have | Use instead |
|---|---|---|
| Python, `pylsp` | call hierarchy (`getCallgraph` edges from the server, `getInboundCalls`) | `getReferences` at the position |
| Python, `pylsp` | `searchWorkspaceSymbol` | `searchSymbol`, from the index |
| Python, `pylsp` | `getImplementations` | `getReferences`, then read each result |

This is not a fault to repair, and `rebuildIndex` does not change it. Report
the verb, the language, and the verb to use instead.

### The call graph is empty, and the servers run

Mark the language server layer dirty, and let the index fill again:

```js
return await tools.code_context.rebuildIndex({ layer: "lsp" });
```
