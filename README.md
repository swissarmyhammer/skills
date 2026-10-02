# swissarmyhammer-skills

This repository is the `swissarmyhammer-skills` marketplace. It holds the
swissarmyhammer agent skills as Stencil templates that
[FoundationModelsSkills](https://github.com/swissarmyhammer/FoundationModelsSkills)
reads: each skill is a direct child of `skills/`, which is one layer root, and
the shared Stencil partials are in `_partials/` at the root. Every skill renders
untrusted, thus the templates use only the `if`, `for`, and `include` tags, and
no filters. To use these skills, add the marketplace URL to your host with the
`skills` CLI:

```sh
skills marketplace add https://github.com/swissarmyhammer/skills.git
```

## The `code-context` branch

This branch holds only the five skills whose one requirement is the
`code_context` tool: `code-context`, `detected-projects`, `explore`, `lsp`, and
`map`. No skill of this branch includes a partial, thus the branch has no
`_partials/` folder. The sub-agents of `main` preload skills and include
partials that this branch does not have, thus the branch has no `agents/`
folder. A host mounts the branch with `ref: code-context`.
