---
comments:
- actor: wballard
  id: 01m49n9c71j02nx2tzjnhmksyw
  text: |-
    Research: I read the bench transcripts (preds.code-context*.transcripts). The model used `files.read` with `offset` and `limit` on code files (for example django/forms/formsets.py, django/forms/models.py). It used `files.grep` for a class or function name (ResolverMatch, select_related_descend, ReadOnlyPasswordHashWidget), with `outputMode: "filesWithMatches"` in `tests/`, and with `contextLines` in one file. The substitution table has one row for each of these patterns.

    Changes:
    - Both skills have a new section "Use these verbs first" near the top: a rule, an 8-row substitution table, one `runCode` snippet (searchSymbol + getSymbol + inbound getCallgraph), and a list of only three cases for `tools.files.read`/`tools.files.grep` (not code; exact lines before an edit after a code_context verb gave the location; the index does not hold the file yet).
    - code-context: I removed the bullet "To find the exact lines of a text: tools.files.grep ..." and the section "When to use the file verbs". These were wide permissions.
    - explore: I rewrote the body and the description in STE. The old exception list and the "use tools.files.glob and tools.files.grep for test files" text now point to grepCode with filePattern. tools.files.glob is only to find a test file by name.
    - The validator dump for .md files gave zero rules. The repo has no tests.

    The last acceptance criterion (a new SWE-bench run) waits for the external bench run. The FoundationModelsACPAgent session must do that run. I did not check that item.
  timestamp: 2026-10-06T22:27:59.841661+00:00
- actor: wballard
  id: 01m49n9db415es9b71dw196nan
  text: |-
    ### implement — changed
    - evidence: 2 files — skills/explore/SKILL.md, skills/code-context/SKILL.md
    - next: /review. The SWE-bench acceptance item waits for the external bench run in the FoundationModelsACPAgent session.
  timestamp: 2026-10-06T22:28:00.996073+00:00
- actor: wballard
  id: 01m49nan10vbmax44105yr90t0
  text: |-
    ### review — clean
    - evidence: `review sha HEAD~1..HEAD` gave zero findings (findings 0, confirmed 0, refuted 0). The engine reviewed 0 files. The 19 `.kanban/` files are excluded by `.reviewignore`. For `skills/explore/SKILL.md` and `skills/code-context/SKILL.md`, no validator matches the file (no validator has a `*.md` glob). Thus, no validator examined the skill text.
    - next: The task is in done. The last acceptance criterion (a new SWE-bench run) stays open. Another session does it.
  timestamp: 2026-10-06T22:28:41.632302+00:00
- actor: wballard
  id: 01m49nax0g7w59fqjtewv9szbm
  text: |-
    ### finish iteration 1 — clean
    - implement: changed — 2 files (skills/explore/SKILL.md, skills/code-context/SKILL.md)
    - test: no test suite in this repo — nothing to run
    - commit: 8d07d09
    - review: clean — zero findings. No validator matches *.md, thus the engine did not examine the skill text.
    - open: the SWE-bench run criterion waits for the FoundationModelsACPAgent session.
  timestamp: 2026-10-06T22:28:49.808337+00:00
- actor: wballard
  id: 01m49ndsz0nnggz3gnqjexdd81
  text: |-
    ### Baseline counts before commit 8d07d09 (from the FoundationModelsACPAgent session)

    16 instances in each run, with the same instance ids.

    | Run | code_context | files.read | files.grep |
    |---|---|---|---|
    | 2026-10-05 (code-context) | 47 (grepCode 24, getSymbol 16, detectProjects 2, searchSymbol 2, searchCode 1, searchWorkspaceSymbol 1, listFiles 1) | 156 | 103 |
    | 2026-10-06 (code-context-1006, newer Router and Multitool) | 8 (grepCode 2, searchSymbol 2, detectProjects 1, getStatus 1, listSymbol 1, searchWorkspaceSymbol 1) | 274 | 100 |

    - The use of code_context changes much between two runs (47, then 8). Thus the earlier "approximately 49 to 260" is one run only.
    - Target for the next run: clearly more code_context calls than in both runs, and fewer files.read calls.
    - The model called verbs that do not exist: `code_context.listFiles` (1 call, 2026-10-05) and `files.readFile` (1 call, 2026-10-06).
    - The next run waits for a push of the skills to origin code-context. The push must have the approval of the user.
  timestamp: 2026-10-06T22:30:24.992023+00:00
position_column: done
position_ordinal: '80'
title: Make the explore and code-context skills steer a small model to the code_context verbs
---
## Problem

SWE-bench runs of the FoundationModelsACPAgent (model mlx-community/Qwen3.8-27B-mxfp4, skills from the code-context branch) show that the model does not use the `tools.code_context` verbs enough:

- In two 16-instance runs (code-context, 2026-10-05, and code-context-1006, 2026-10-06), the model made 29 skills tool calls and had no errors: 8 `list skill`, 11 `search skill`, and 10 `use skill` (explore 4, code-context 3, detected-projects 3). The model searched for skills often, but it loaded few of them.
- After the model loaded explore or code-context, it still used `tools.files.read`, `tools.files.grep` and shell more than the code_context verbs. In one 16-instance run, the code_context verbs had approximately 49 calls. `files.read` and `files.grep` had approximately 260 calls.

The source of this data is a report from the FoundationModelsACPAgent session (2026-10-06). The transcripts are in `/Users/wballard/github/swissarmyhammer/FoundationModelsACPAgent/bench/preds.code-context*.transcripts/<instance>/<session>/transcript.jsonl` (read-only). A call is in a "toolCalls" row (argumentsJSON). Its result is in the "toolOutput" row whose entryId is the call id.

## Files

- `skills/explore/SKILL.md`
- `skills/code-context/SKILL.md`

## Possible changes

- Put a short, direct rule near the top of each skill: "Before you call `tools.files.read` on a code file, call `listSymbol` and `getSymbol`." A small model reads the top of the text more than the end.
- Give a substitution table: "You want X → do not use `files.read`/`files.grep` → use verb Y".
- Make the first example a single `runCode` snippet that does survey + trace in one call, so that the model can copy it.
- Make the `tools.files.grep` exception in the code-context skill (line 61) and the explore skill (line 61, line 146) narrower, so that the model does not use it as a general permission.
- Keep the text short. A long skill text is a cost to a small model.

## Acceptance criteria

- [x] `skills/explore/SKILL.md` has a "use these verbs first" rule and a substitution table near the top.
- [x] `skills/code-context/SKILL.md` has the same rule and table.
- [x] The text of the two skills is in ASD-STE100 Simplified Technical English.
- [ ] A new SWE-bench run with the same model shows a higher ratio of code_context calls to files.read and files.grep calls than 49 to 260. (Ask the FoundationModelsACPAgent session to do the run.)