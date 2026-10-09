# skills

This repository is the `swissarmyhammer-skills` marketplace. It holds the
swissarmyhammer agent skills as Stencil templates that
[FoundationModelsSkills](https://github.com/swissarmyhammer/FoundationModelsSkills)
reads: each skill is a direct child of `skills/`, which is one layer root, and
the shared Stencil partials are in `_partials/` at the root. 


The marketplace is only this folder. It has no catalog file: the
host scans the folder to find the skills and the agents. 

