# swissarmyhammer-skills

This repository is the `swissarmyhammer-skills` marketplace. It holds the
swissarmyhammer agent skills as Stencil templates that
[FoundationModelsSkills](https://github.com/swissarmyhammer/FoundationModelsSkills)
reads: each skill is a direct child of `skills/`, which is one layer root, and
the shared Stencil partials are in `_partials/` at the root, which the
skills and the agents share. Every skill renders
untrusted, thus the templates use only the `if`, `for`, and `include` tags, and
no filters. To use these skills, add the marketplace URL to your host with the
`skills` CLI:

```sh
skills marketplace add https://github.com/swissarmyhammer/skills.git
```

## Agents

The repository also holds the swissarmyhammer sub-agents, in `agents/`, one
`<name>.md` file for each agent: YAML frontmatter and a body that is the
system prompt of the agent. The folder is at the root of the plugin, which is
where Claude Code finds the agents of a plugin. An agent preloads the skills
of this marketplace that its `skills:` key names, and its body includes the
same `_partials/sah-` partials as the skills. Every agent body also renders
untrusted.
