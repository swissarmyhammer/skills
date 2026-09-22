---
name: explore
description: Understand how unfamiliar code works before planning or changing it — its structure, behavior, data flow, and the blast radius of a change. Use when the user says "explore", "investigate", "how does X work", "why does X happen", "where is X handled", "what calls X", "what would it take to change X", or whenever you need to understand code before acting on it. Drives exploration with the `tools.code_context` verbs — symbol search, callgraph traversal, and blast-radius analysis — instead of reading files top to bottom.
license: MIT OR Apache-2.0
compatibility: Requires the `tools.code_context` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
agent: explorer
metadata:
  author: swissarmyhammer
  version: "1.0.0"
---

# Explore

Understand code well enough to explain how it works and what a change would touch.

$ARGUMENTS

## Done Means

Exploration is complete when you can explain:

```
1. HOW IT WORKS    — what calls what, what data flows where
2. WHERE IT LIVES  — specific files and symbols
3. WHAT IT TOUCHES — blast radius: what a change would affect
```

Can't state all three? Not done. Guessing at any? Back to the tool — don't fill the gap with assumptions.

## Process

Each verb below is a code-mode call. Make the calls in the `runCode` tool, as JavaScript, and `return` the part of the result that you need. A `line` and a `character` are 0-based.

### Orient — check layers

```js
await tools.code_context.getStatus({});
```

Note which layers are active. Live LSP ops (`getDefinition`, `getHover`, `getReferences`) work immediately — don't wait for indexing. If LSP unavailable, results come from tree-sitter. Check `getLspStatus` to see whether each server runs.

**A server answers only the methods it has**, and the host asks only for those. Where a method is absent it uses another way when it has one: Python's `pylsp` has no call hierarchy, so the callers come from references and `getCallgraph`, `getBlastradius` and `getInboundCalls` all answer. `searchWorkspaceSymbol` and `getImplementations` give an empty result on Python — use `searchSymbol` for a name. An empty result never says whether the server lacks the method or the code has no match, so confirm with a second verb before you conclude.

If `ARCHITECTURE.md` exists at the project root, read it now (per the Architecture Awareness guidance) — it gives the system map before tracing individual symbols.

### Survey — find the territory

Broad first. Use domain keywords:

```js
await tools.code_context.searchSymbol({ query: "<domain keyword>", maxResults: 15 });
```

If the index is building and `searchSymbol` is sparse, widen the search:

```js
await tools.code_context.grepCode({ pattern: "<domain keyword>", maxResults: 20 });
await tools.code_context.listSymbol({ file: "<key file>" });
```

`searchWorkspaceSymbol` is the live alternative where the server has it. On Python it answers empty.

**Looking for**: the nouns and verbs of the problem — structs, traits, functions that participate.

### Trace — follow execution

```js
await tools.code_context.getSymbol({ query: "<specific symbol>" });
```

Jump to definitions and types without reading whole files:

```js
await tools.code_context.getDefinition({ file: "<file>", line: <line>, character: <col> });
await tools.code_context.getHover({ file: "<file>", line: <line>, character: <col> });
```

Call relationships both directions:

```js
await tools.code_context.getCallgraph({ symbol: "<symbol>", direction: "both", maxDepth: 2 });
await tools.code_context.getInboundCalls({ file: "<file>", line: <line>, character: <col> });
```

All usages:

```js
await tools.code_context.getReferences({ file: "<file>", line: <line>, character: <col> });
```

**Looking for**: the path data takes through the system. `getInboundCalls` asks the server now; `getCallgraph` reads the indexed edges for broader traversal. Where a server has no call hierarchy, such as Python, both still answer, from references. A caller added a moment ago reaches `getCallgraph` only after the file of the callee is indexed again, so use `getInboundCalls` for a fresh answer.

### Scope — measure the blast radius

```js
await tools.code_context.getBlastradius({ file: "<target>", maxHops: 3 });
```

Supplement with `getReferences` — blast radius follows call edges, but references also catch type usage, field access, and trait impls.

An empty radius is not "nothing is affected". Confirm it with `getReferences` on the symbol and `grepCode` on its name before you believe it.

**Looking for**: how far a change propagates. If the radius surprises you, you don't understand the code yet — back to step 3.

### Check tests

Tests are the clearest executable spec — they confirm understanding and show project patterns.

Also use `tools.files.glob` and `tools.files.grep` for test files near the code:
- Same dir with `_test` suffix
- `tests/` at project/crate root
- Inline test modules (`#[cfg(test)]`, `describe(`, `#[test]`)

**Looking for**: intended behavior, the project's test patterns, behavior with no coverage.

### Conclude — explain

Exit gate. State concretely:

```
HOW IT WORKS: <mechanism in plain terms — what calls what, what flows where>
KEY CODE:     <files and symbols — paths>
BLAST RADIUS: <what a change touches, or "n/a — investigation only">
```

Then point at the next step — but don't take it. Exploration produces understanding; acting is separate:

- **Make a change** → `/tdd` (failing test first) or `/implement`
- **Too large for one step** → `/plan`
- **Found a bug** → describe it + expected behavior, suggest `/task`
- **Architectural question** → present findings, ask the user — don't guess

## Layered Resolution

`code-context` is primary. Indexed ops (tree-sitter symbols, callgraphs, blast radius) plus **live LSP ops** (definitions, hover, references, inbound calls, workspace symbol search). Live ops work before the index is fully built.

Results include `source_layer`:
- **lsp** — full language-server precision (types, generics, trait impls)
- **treesitter** — structural parsing from the index (fast, always available after indexing)
- **treesitter+lsp** — combined

Tree-sitter-only for a language that should have LSP? Suggest `/lsp`.

Use `tools.files.read`, `tools.files.grep` and `tools.files.glob` only for:
- String literals, config, error messages not in the symbol index
- Non-code files (TOML, YAML, JSON, Markdown)
- Confirming exact syntax after code-context gave you the location

**Don't** start by reading files top to bottom. Start with `searchSymbol` and `grepCode`, then `getCallgraph` or `getInboundCalls`; use `getDefinition`/`getHover` to inspect specifics.

## When to Recurse

If blast radius reveals surprises or the callgraph leads to new territory, loop back to step 2 with new keywords. Each loop should *narrow* focus, not widen it.

## Examples

**Understanding a feature:** User says "explore how the kanban watcher decides which files to re-index".

1. Orient with `getStatus` — note active layers.
2. Survey: `searchSymbol({ query: "watcher" })`, `searchSymbol({ query: "invalidate" })` → `KanbanWatcher::on_event`, `invalidate_file`.
3. Trace: `getSymbol({ query: "KanbanWatcher::on_event" })`, then `getCallgraph({ symbol: "invalidate_file", direction: "inbound", maxDepth: 2 })`.
4. Scope: `getBlastradius({ file: "src/watcher.rs", maxHops: 3 })` → indexer + MCP layer only.
5. Tests: `grepCode({ pattern: "on_event", filePattern: "*test*" })` → smoke test covers creation; nothing covers deletion.
6. Conclude:

   ```
   HOW IT WORKS: on_event receives a FileEvent, matches the EventKind, and calls
                 invalidate_file for created/modified files; the indexer picks up
                 invalidated paths on its next pass.
   KEY CODE:     src/watcher.rs (KanbanWatcher::on_event, invalidate_file)
   BLAST RADIUS: indexer + MCP layer only. Deletion (EventKind::Remove) is not
                 handled — invalidate_file is never called for deleted files.
   ```

Exploration complete. Deletion gap → `/tdd` or `/task`.

**Exploration reveals work too large:** `/explore what it would take to add SSO`. Orient, survey auth symbols, trace login flow. Blast radius on `src/auth/login.rs` shows 40+ call sites. Stop — escalate to `/plan` rather than force a conclusion.

## Constraints

- **Don't write code during exploration.** Hand off.
- **Don't skip blast radius.** It's where surprises surface. Confirm an empty radius with `getReferences` and `grepCode` — but measure it.
- **Don't read files top to bottom.** Use the `tools.code_context` verbs to find the right code, inspect what matters.
- **Don't explore forever.** 3 loops without convergence → stop, say what's unclear, ask the user.
- **Don't use exploration to avoid acting.** Once you can explain how/where/what-it-touches, move to planning or implementation.
