---
name: do-task
description: Use this skill when presented with a task.
license: MIT OR Apache-2.0
---

## Scope

The caller gives the scope of the task:

```
$ARGUMENTS
```

## Kanban

First, find out if you have a kanban tool. In the `runCode` tool, run `return Object.keys(tools);`. The result lists your tool groups.

If the list has `kanban`, you have a kanban tool. Load the `kanban` skill now, before you do other work. Each step of this skill that starts with "If you have a kanban tool" applies to you, and the `kanban` skill tells you how to make those calls.

If the list has no `kanban`, skip each kanban step.

## Coding

If this is a coding task read [code.md](references/code.md) and follow.
