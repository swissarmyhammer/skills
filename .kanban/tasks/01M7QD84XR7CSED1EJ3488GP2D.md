---
assignees:
- claude-code
comments:
- actor: claude-code
  id: 01m7qdb2e1r5svy2h2txzc0m09
  text: |-
    ## Dependency check (research)

    Result: the `unknownSkill` warning is harmless. The change can land before ^e46cb97 and ^zx4k6r4 ship.

    Evidence:
    - `FoundationModelsAgents/Sources/FoundationModelsAgents/Run/AgentSkillsPreload.swift:42-46` — `unknownSkillFinding` makes an `AgentFinding` with `severity: .warning` and the message "... the entry is skipped".
    - `AgentSkillsPreload.swift:63-70` — `selection(of:)` puts only names with `visibility[name] == true` in `loaded`. An unknown name gets `nil`, so it is not loaded. It only adds a finding (`finding(for:isModelVisible:)`, lines 134-143, case `.none`).
    - `AgentSkillsPreload.swift:93-107` — `bodies(of:)` renders only the `loaded` names. It throws only for a render failure of a loaded skill. `render` (lines 117-125) maps `UnknownSkillError` to `.success(nil)`, so a skill that is removed after selection is also skipped.
    - `FoundationModelsAgents/Sources/FoundationModelsAgents/Run/AgentRunner+DefaultAgent.swift:89-90` — `sessionAgentInstructions` returns the diagnostics as data. It does not throw for them.
    - `FoundationModelsACPAgent/Sources/FoundationModelsACPAgent/Agent/SessionAgentComposition.swift:146-149` — ACPAgent only logs each diagnostic with `logger(.session).warning(...)`. The session continues.
    - `FoundationModelsAgents/Sources/FoundationModelsAgents/Run/AgentRunner.swift:664` — `runWarnings` adds the preload diagnostics to the catalog warnings. Thus `runner.catalog()` shows an `UNKNOWN_SKILL` warning until the dependencies ship. This is a warning, not a failure.

    State of the dependencies (on disk, 2026-11-18):
    - FoundationModelsMultitool (^e46cb97): `Sources/FoundationModelsMultitool/Resources/skills/sessions/SKILL.md` and `Sources/FoundationModelsMultitool/BuiltinSkills.swift` exist, and `Package.swift:645-646` copies `Resources/skills`. These files are NOT committed (`git status`: `?? Sources/FoundationModelsMultitool/BuiltinSkills.swift`, `?? Sources/FoundationModelsMultitool/Resources/`).
    - FoundationModelsACPAgent (^zx4k6r4): no source file refers to `BuiltinSkills`. The built-in skills layer is not wired yet.

    ## Implementation

    - `agents/default/AGENT.md`: front matter changed from `skills: [do-task, ste]` to `skills: [do-task, ste, sessions]`.
    - No `skills/sessions/` directory was added (checked: the path does not exist).
    - No validator rule applies to `agents/default/AGENT.md` (`dump validators`: 0 rules). This repository has no test suite for agent front matter. The change is configuration, so no unit test applies.

    ## Manual acceptance criteria

    The two `acp-agent` manual criteria (the `sessions` skill in the session instructions, and no warning from `runner.catalog()`) cannot run here. They need a manual run after ^e46cb97 and ^zx4k6r4 ship. Until then, the second criterion is expected to show the `UNKNOWN_SKILL` warning.
  timestamp: 2026-11-18T13:25:34.273085+00:00
- actor: claude-code
  id: 01m7qdb40t1c8ys46c9yjra4x0
  text: |-
    ### implement — changed
    - evidence: 1 file — agents/default/AGENT.md (`skills: [do-task, ste, sessions]`); no skills/sessions/; unknownSkill is a skipped warning (AgentSkillsPreload.swift:42-46, :63-70; SessionAgentComposition.swift:146-149)
    - next: /review. The two manual acp-agent criteria need a manual run after ^e46cb97 and ^zx4k6r4 ship.
  timestamp: 2026-11-18T13:25:35.898202+00:00
- actor: claude-code
  id: 01m7qdc1pw9yem29mfb0d1zww5
  text: |-
    ### review — clean
    - evidence: `review sha HEAD~1..HEAD` (commit 036c882). Counts: 0 findings, 0 confirmed, 0 refuted. No validator matches `agents/default/AGENT.md`, so the engine reviewed 0 files. The engine ignored 4 `.kanban/` files by `.reviewignore`. The two manual `acp-agent` acceptance criteria cannot run in this repository. They are not a review finding.
    - next: The task moves to `done`.
  timestamp: 2026-11-18T13:26:06.300232+00:00
- actor: claude-code
  id: 01m7qdc9jmghfrd23k7nzjfg9f
  text: |-
    ### finish iteration 1 — clean
    - implement: changed — 1 file (agents/default/AGENT.md)
    - test: no test suite in this repository; no test ran
    - commit: 036c882
    - review: clean — 0 findings (no validator matched AGENT.md)
  timestamp: 2026-11-18T13:26:14.356512+00:00
position_column: done
position_ordinal: '8280'
title: 'agents(default): load the built-in `sessions` skill at the start of a root session'
---
## Goal

The `default` agent is the root agent of `acp-agent` (the CLI). It must load the `sessions` skill at the start of each root session, the same as the Testudo default agent. Decision: D200 in `TestudoApp/features/decisions.md` (commit d1895ba). Brief: `/Users/wballard/github/swissarmyhammer/.briefs/at-sessions/skills-repo-brief-sessions-skill.md`.

## Change

1. In `agents/default/AGENT.md`, change the front matter `skills: [do-task, ste]` to `skills: [do-task, ste, sessions]`.
2. Do NOT add `skills/sessions/`. The built-in skill of FoundationModelsMultitool is the only text. A marketplace skill with the same name has lower precedence than the built-in layer, so it has no effect.

## Dependency

- The skill ships in FoundationModelsMultitool (task ^e46cb97).
- It resolves through the built-in layer of FoundationModelsACPAgent (task ^zx4k6r4).
- Until those land, an agent that lists `sessions` gets an `unknownSkill` warning and skips the skill (`FoundationModelsAgents/Sources/FoundationModelsAgents/Run/AgentSkillsPreload.swift:38-46`). Land this change after them, or make sure that the warning is harmless.

## Acceptance criteria

- [x] `agents/default/AGENT.md` front matter has `skills: [do-task, ste, sessions]`.
- [x] No `skills/sessions/` directory exists in this repository.
- [ ] Manual test: run `acp-agent` with the default marketplace and start a new session in a folder. The session instructions (debug dump or `/context`) hold the `sessions` skill.
- [ ] Manual test: `runner.catalog()` gives no warning for the `skills:` key.

#agents