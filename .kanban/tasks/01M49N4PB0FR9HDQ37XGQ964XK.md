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
- actor: wballard
  id: 01m49np5khv8rkj195m5qvgx92
  text: |-
    ### Research: the search that the ACP agent uses

    - `ToolCatalog.makeSkillsTool` (FoundationModelsACPAgent) calls `SkillsTool.make(registry:session:)` with NO embedder. Thus the retrieval tier is keyword (BM25) + trigram, fused with RRF. There is no cosine signal in the bench.
    - With a session, the searcher is in `.auto` mode: a selection tier on the `flash` model answers each search. A second searcher in `.retrieval` mode over the same index is the fallback (`SkillsToolAssembly.makeContext`).
    - The search text is `renderBlock()`: the skill id, the `description`, and a "Parameters:" line. The skill id `code-context` holds the token "code". Thus a query with "code" always gets a match on the id.

    ### How I measured

    - I made a small Swift package in my scratchpad (not in any repo). It has a path dependency on `/Users/wballard/github/swissarmyhammer/FoundationModelsSkills`. It builds `SkillsRegistry` over one `.defaults` layer at `skills/`, calls the public `SkillsTool.make(registry:followReloads:)` (retrieval tier, no embedder, model-visible skills), and runs `skill search --query <q>` through `OperationCLIDriver`. This is the same retrieval tier as the bench, with the same five skills. `git status` in FoundationModelsSkills is clean after the build.
    - I did NOT measure the selection tier. It needs the `flash` model of the bench profile, and I did not run that model.

    ### Ranks BEFORE the change (retrieval tier)

    - "edit a file apply a patch" -> code-context explore lsp map detected-projects
    - "fix a bug in source file" -> code-context detected-projects explore lsp map
    - "fix bug in code" -> code-context detected-projects lsp explore map
    - "find symbol" -> code-context ...
    - "code context symbol lookup" -> code-context ...

    ### What did not work fully

    - Only a narrower code-context description moved the first two queries to explore first. "fix bug in code" stayed code-context first: "fix" and "bug" matched no skill, and "code" matches the id `code-context`. A description change cannot remove a token from the id. Removing "Code context" from the description start did not change any rank, thus I kept that wording.
    - Then I added "where is the bug" and "fix a bug in it" to the explore description. To find the code of a bug is a real use of explore, thus this is not a change only for the rank.
    - I did not add a new edit or fix skill. I do not know the edit verbs of the code-mode host well enough to write a correct skill, and explore now gets the "fix" queries.
  timestamp: 2026-10-06T22:34:59.057083+00:00
- actor: wballard
  id: 01m49np8gm3h6w1xb1hybtn9nk
  text: |-
    ### Ranks AFTER the change (retrieval tier, measured)

    - "edit a file apply a patch" -> explore lsp code-context map detected-projects
    - "fix a bug in source file" -> explore detected-projects code-context lsp map
    - "fix bug in code" -> explore code-context detected-projects lsp map
    - "find symbol" -> code-context explore detected-projects map lsp
    - "code context symbol lookup" -> code-context explore lsp detected-projects map
    - "find symbol and references in code" -> code-context explore lsp detected-projects map
    - "find symbol, search code" -> code-context explore lsp detected-projects map
    - "find symbol ResolverMatch" -> code-context explore map lsp detected-projects
    - "explore codebase find issue" -> explore code-context map detected-projects lsp
    - "explore Django code" -> explore code-context detected-projects lsp map

    Limit: these ranks are for the retrieval tier only. The bench also runs a selection tier on the `flash` model. I did not measure that tier.
  timestamp: 2026-10-06T22:35:02.036217+00:00
- actor: wballard
  id: 01m49npj46thc1r49cdjj4hj5g
  text: |-
    ### implement — changed
    - evidence: 2 files — skills/code-context/SKILL.md (description: removed "before you change code", "what's affected if I change this", "list the symbols of a file"; kept the lookup trigger phrases), skills/explore/SKILL.md (description: added "where is the bug" and "fix a bug in it"). Retrieval-tier ranks measured with a scratch harness over FoundationModelsSkills (path dependency, read-only repo not changed): the edit/fix queries rank explore first; the lookup queries rank code-context first. Selection tier (flash model) not measured. No new skill added. No commit.
    - next: /review
  timestamp: 2026-10-06T22:35:11.878327+00:00
position_column: doing
position_ordinal: '80'
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

- [x] The ranking method of `search skill` in the host is known and written in this task.
- [x] A `search skill` for "edit a file apply a patch" and for "fix a bug in source file" does not return code-context first. (Measured on the retrieval tier only. The selection tier on the `flash` model is not measured. See the comments.)
- [x] A `search skill` for "find symbol" and for "code context symbol lookup" still returns code-context first. (Measured on the retrieval tier only. The selection tier on the `flash` model is not measured. See the comments.)
- [x] All the changed text is in ASD-STE100 Simplified Technical English. #skills