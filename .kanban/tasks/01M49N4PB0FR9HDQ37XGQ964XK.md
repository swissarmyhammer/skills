---
comments:
- actor: wballard
  id: 01m49n69wsy6k247ybj1s6kmm3
  text: |-
    ### Ranking method of `search skill` (from the FoundationModelsACPAgent session, 2026-10-06)

    - The search text of a skill comes only from `SkillMetadata.renderBlock()` (`/Users/wballard/github/swissarmyhammer/FoundationModelsSkills/Sources/FoundationModelsSkills/Search/SkillMetadata.swift:20-29`): the skill id, the description and a "Parameters:" line. The skill body is NOT in the search text. Checked in this session: the code agrees.
    - Thus, only the `name` and the `description` in the SKILL.md frontmatter change the rank.
    - Tier 1 (retrieval): `MetadataSearcher<SkillMetadata>` (FoundationModelsMetadataRegistry / FoundationModelsRanker). It makes tokens, trigrams and embeddings of the search text, and gives a keyword and vector score.
    - Tier 2 (optional selection): a small model session gets the candidate ids and descriptions and answers `{"ids": [...]}` (`Search/SelectionSessionRequest.swift`). If the answer does not decode, the agent uses the retrieval rank. It is not known which tier the ACP agent uses in the bench. Not checked in this session.
    - Conclusion: change the descriptions, not the ranker. Make the code-context description narrower (it has many trigger words). If possible, add a skill whose description matches "edit" and "fix".
  timestamp: 2026-10-06T22:26:19.161964+00:00
position_column: todo
position_ordinal: '8180'
title: A skill search for "edit" or "fix" must not return the code-context skill first
---
## Problem

In two SWE-bench runs of the FoundationModelsACPAgent (model mlx-community/Qwen3.8-27B-mxfp4, code-context branch skills, 2026-10-05 and 2026-10-06), the model made 11 `search skill` calls. Most of them returned code-context first. This is also true for the queries "edit a file apply a patch" and "fix a bug in source file". For these queries, code-context is not the correct skill. No skill in this repo describes how to edit a file or fix a bug. A small model that searches for "edit" or "fix" gets the code-context skill, and it can lose time.

All the queries: "find symbol, search code" (2), "explore codebase find issue", "edit a file apply a patch", "fix a bug in source file", "code context symbol lookup", "find symbol and references in code", "find symbol ResolverMatch", "fix bug in code", "explore Django code".

The source of this data is a report from the FoundationModelsACPAgent session (2026-10-06). The transcripts are in `/Users/wballard/github/swissarmyhammer/FoundationModelsACPAgent/bench/preds.code-context*.transcripts/<instance>/<session>/transcript.jsonl` (read-only).

## Files

- `skills/code-context/SKILL.md` (the `description` frontmatter, lines 3-11)
- `skills/explore/SKILL.md` (the `description` frontmatter, line 3)
- Possibly a new skill for edit and fix work.

## Possible changes

- Find how the host ranks `search skill` results (which fields it matches, and how). Do this first, because the fix depends on it.
- Remove words from the code-context description that match edit or fix queries, for example "before you change code".
- Or add a small skill that tells the model how to find the code to fix (with explore or code-context) and how to apply a patch. Then an "edit" or "fix" query gets that skill.

## Acceptance criteria

- [ ] The ranking method of `search skill` in the host is known and written in this task.
- [ ] A `search skill` for "edit a file apply a patch" and for "fix a bug in source file" does not return code-context first.
- [ ] A `search skill` for "find symbol" and for "code context symbol lookup" still returns code-context first.
- [ ] All the changed text is in ASD-STE100 Simplified Technical English. #skills