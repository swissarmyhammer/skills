# swissarmyhammer-skills

This repository is the `swissarmyhammer-skills` marketplace. It holds the
swissarmyhammer agent skills as Stencil templates that
[FoundationModelsSkills](https://github.com/swissarmyhammer/FoundationModelsSkills)
reads: each skill is a direct child of `skills/`, which is one layer root, and
the shared Stencil partials are in `skills/_partials/`. Every skill renders
untrusted, thus the templates use only the `if`, `for`, and `include` tags, and
no filters. To use these skills, add the marketplace URL to your host with the
`skills` CLI:

```sh
skills marketplace add https://github.com/swissarmyhammer/skills.git
```

## License

`MIT OR Apache-2.0`. Read [LICENSE-MIT](LICENSE-MIT) and
[LICENSE-APACHE](LICENSE-APACHE).
