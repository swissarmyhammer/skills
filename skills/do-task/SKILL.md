---
name: do-task
description: Use this skill when presented with a task.
license: MIT OR Apache-2.0
---

## Scope

The task is the user's prompt. When the caller gives a scope, it is in this block. An empty block means that the scope is the user's prompt alone.

```
$ARGUMENTS
```

{% if tools.kanban.enabled %}
## Kanban

Load the `kanban` skill now, before you do other work. It tells you how to call the kanban tool.

Use the kanban board in each step of this skill.

{% endif %}
## Coding

If this is a coding task, follow these steps.

{% include "references/code.md" %}
