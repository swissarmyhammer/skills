---
name: explore
description: Learn how code that is new to you works before you plan or change it — its structure, its behavior, its data flow, and the blast radius of a change. Use when the user says "explore", "investigate", "how does X work", "why does X happen", "where is X handled", "what calls X", "what would it take to change X", or when you must know the code before you change it. Uses the `tools.code_context` verbs — symbol search, call graph and blast radius — and not a full read of each file.
license: MIT OR Apache-2.0
compatibility: Requires the `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
agent: explorer
metadata:
  author: swissarmyhammer
  version: "1.0.0"
---

# Explore

Learn the code. Then explain how it works, and what a change to it affects.

$ARGUMENTS

## Use these verbs first

**Rule:** Before you call `tools.files.read` or `tools.files.grep` on a code file, call a `tools.code_context` verb. Call the verbs in the `runCode` tool, as JavaScript.

| You want | Do not use | Use |
|---|---|---|
| The parts of a file | `files.read` of the full file | `listSymbol({ file })` |
| The source of a function or a class | `files.read` with `offset` and `limit` | `getSymbol({ query: "Class.method" })` |
| The definition of a name | `files.grep` for `def name` or `class Name` | `searchSymbol({ query })`, then `getSymbol({ query })` |
| The callers of a function | `files.grep` for the name | `getCallgraph({ symbol, direction: "inbound" })` |
| All uses of a name | `files.grep` for the name in a directory | `getReferences({ file, line, character })` or `grepCode({ pattern })` |
| The code that holds a text | `files.grep` with `outputMode: "filesWithMatches"` | `grepCode({ pattern, filePattern })` |
| The tests for a symbol | `files.grep` in `tests/` | `grepCode({ pattern: "<name>", filePattern: "*test*" })` |
| The effect of a change | many `files.grep` calls | `getBlastradius({ file, symbol })` |

Copy this snippet. It finds a symbol, gives its source and gives its callers in one call:

```js
const found = await tools.code_context.searchSymbol({ query: "<name>", maxResults: 5 });
const source = await tools.code_context.getSymbol({ query: "<Class.method>", maxResults: 1 });
const callers = await tools.code_context.getCallgraph({ symbol: "<Class.method>", direction: "inbound", maxDepth: 2 });
return { found, source, callers };
```

Use `tools.files.read` and `tools.files.grep` only in these three cases:

- The file is not code: TOML, YAML, JSON, Markdown or a template.
- A `tools.code_context` verb gave you the file and the symbol, and you must see the exact lines before you edit them.
- A `tools.code_context` verb gave an empty result because the index does not hold the file yet.

## Done Means

The exploration is complete when you can tell these three things:

```
1. HOW IT WORKS    — what calls what, and where the data goes
2. WHERE IT IS     — the files and the symbols
3. WHAT IT AFFECTS — the blast radius: what a change touches
```

If you cannot tell all three, the exploration is not complete. If you guess one of them, go back to the verbs. Do not fill a gap with a guess.

## Process

Each verb below is a code-mode call. Make the calls in the `runCode` tool, as JavaScript. `return` the part of the result that you need. A `line` and a `character` are 0-based. One `runCode` call can make many verb calls.

### 1. Orient — examine the layers

```js
await tools.code_context.getStatus({});
```

Find which layers are active. The live language server verbs (`getDefinition`, `getHover`, `getReferences`) work immediately. Do not wait for the index. If no language server runs, the results come from tree-sitter. `getLspStatus` shows whether each server runs.

**A server answers only the methods that it has.** The host asks only for those methods. Where a method is absent, the host uses another way when it has one. Python's `pylsp` has no call hierarchy, thus the callers come from references, and `getCallgraph`, `getBlastradius` and `getInboundCalls` all answer. On Python, `searchWorkspaceSymbol` and `getImplementations` give an empty result with a `notSupportedReason`. That field tells you that the server does not have the method. Use `searchSymbol` for a name. An empty result WITHOUT that field means that the code holds no match.

If `ARCHITECTURE.md` is at the project root, read it now. It gives the map of the system before you trace one symbol.

### 2. Survey — find the area

Start wide. Use the words of the problem:

```js
await tools.code_context.searchSymbol({ query: "<domain word>", maxResults: 15 });
```

If the index is not complete and `searchSymbol` gives few results, make the search wider:

```js
await tools.code_context.grepCode({ pattern: "<domain word>", maxResults: 20 });
await tools.code_context.listSymbol({ file: "<key file>" });
```

A `grepCode` hit comes back as the innermost symbol that holds it. A hit in one method gives that method, not the class around it. Use the hits to find WHICH symbols are important. Then use `getSymbol` for the one that you need. To find a method or a class by name, use `searchSymbol` or `getSymbol`. Do not use a pattern such as `def name`.

`searchWorkspaceSymbol` asks the live server, where the server has that method. On Python it gives an empty result.

**Find:** the nouns and the verbs of the problem — the types and the functions that are part of it.

### 3. Trace — follow the execution

```js
await tools.code_context.getSymbol({ query: "<specific symbol>" });
```

Go to definitions and types. Do not read the full file:

```js
await tools.code_context.getDefinition({ file: "<file>", line: <line>, character: <col> });
await tools.code_context.getHover({ file: "<file>", line: <line>, character: <col> });
```

Get the calls in the two directions:

```js
await tools.code_context.getCallgraph({ symbol: "<symbol>", direction: "both", maxDepth: 2 });
await tools.code_context.getInboundCalls({ file: "<file>", line: <line>, character: <col> });
```

Get all the uses:

```js
await tools.code_context.getReferences({ file: "<file>", line: <line>, character: <col> });
```

**Find:** the path of the data through the system. `getInboundCalls` asks the server now. `getCallgraph` reads the indexed edges, and it goes more levels. Where a server has no call hierarchy, such as on Python, the two verbs answer from references.

### 4. Scope — measure the blast radius

```js
await tools.code_context.getBlastradius({ file: "<target>", maxHops: 3 });
```

Also use `getReferences`. The blast radius follows call edges. References also find the uses of a type, the access to a field and the implementations of an interface.

An empty radius does not mean "nothing is affected". Before you believe it, examine it with `getReferences` on the symbol and with `grepCode` on its name.

**Find:** how far a change goes. If the radius is a surprise, you do not know the code yet. Go back to step 3.

### 5. Examine the tests

The tests show the intended behavior and the test patterns of the project.

Find the tests of a symbol with `grepCode({ pattern: "<name>", filePattern: "*test*" })`. Use `tools.files.glob` only to find a test file by its name:

- A file in the same directory with a `_test` or `test_` name
- A `tests/` directory at the root of the project or the crate
- A test module in the source file (`#[cfg(test)]`, `describe(`, `#[test]`)

**Find:** the intended behavior, the test patterns of the project, and the behavior that no test covers.

### 6. Conclude — explain

This is the exit gate. Tell these three things exactly:

```
HOW IT WORKS: <the mechanism in plain words — what calls what, where the data goes>
KEY CODE:     <files and symbols — paths>
BLAST RADIUS: <what a change touches, or "n/a — investigation only">
```

Then name the next step. Do not do it. Exploration gives understanding. Action is a different step:

- **Make a change** → `/tdd` (a failing test first) or `/implement`
- **The work is too large for one step** → `/plan`
- **You found a bug** → describe the bug and the expected behavior, and recommend `/task`
- **A question about the architecture** → show what you found and ask the user. Do not guess.

## Layered Resolution

The `tools.code_context` verbs are the primary tools. The index verbs give tree-sitter symbols, call graphs and blast radius. The **live language server verbs** give definitions, hover, references, inbound calls and workspace symbol search. The live verbs work before the index is complete.

Each result has a `source_layer`:

- **lsp** — the full precision of the language server (types, generics, implementations)
- **treesitter** — the structure from the index (fast, and always available after the index is complete)
- **treesitter+lsp** — the two layers together

Only tree-sitter results for a language that must have a language server? Recommend `/lsp`.

Use the `tools.files` verbs only in the three cases in "Use these verbs first". Do not start with a full read of a file. Start with `searchSymbol` and `grepCode`. Then use `getCallgraph` or `getInboundCalls`. Use `getDefinition` and `getHover` to examine the details.

## When to Recurse

If the blast radius is a surprise, or the call graph goes to new code, go back to step 2 with new words. Each loop must make the area smaller, not larger.

## Examples

**Learn a feature:** The user says "explore how the kanban watcher decides which files to re-index".

1. Orient: `getStatus` — find the active layers.
2. Survey: `searchSymbol({ query: "watcher" })`, `searchSymbol({ query: "invalidate" })` → `KanbanWatcher::on_event`, `invalidate_file`.
3. Trace: `getSymbol({ query: "KanbanWatcher::on_event" })`, then `getCallgraph({ symbol: "invalidate_file", direction: "inbound", maxDepth: 2 })`.
4. Scope: `getBlastradius({ file: "src/watcher.rs", maxHops: 3 })` → the indexer and the MCP layer only.
5. Tests: `grepCode({ pattern: "on_event", filePattern: "*test*" })` → a smoke test covers creation. No test covers deletion.
6. Conclude:

   ```
   HOW IT WORKS: on_event gets a FileEvent, matches the EventKind, and calls
                 invalidate_file for created and modified files. The indexer
                 reads the invalidated paths on its next pass.
   KEY CODE:     src/watcher.rs (KanbanWatcher::on_event, invalidate_file)
   BLAST RADIUS: the indexer and the MCP layer only. The code does not handle
                 deletion (EventKind::Remove): no path calls invalidate_file
                 for a deleted file.
   ```

The exploration is complete. For the deletion gap → `/tdd` or `/task`.

**The work is too large:** `/explore what it would take to add SSO`. Orient, survey the auth symbols, and trace the login flow. The blast radius on `src/auth/login.rs` shows more than 40 call sites. Stop. Send the work to `/plan`. Do not force a conclusion.

## Constraints

- **Do not write code during exploration.** Give the work to the next step.
- **Do not skip the blast radius.** It shows the surprises. Examine an empty radius with `getReferences` and `grepCode`, but always measure it.
- **Do not read files from top to bottom.** Use the `tools.code_context` verbs to find the correct code. Then examine only what is important.
- **Do not explore without end.** After 3 loops with no result, stop. Tell the user what is not clear, and ask.
- **Do not use exploration to avoid the work.** When you can tell how it works, where it is and what it affects, go to the plan or to the implementation.
