---
name: code-commit
description: Use when the user says "commit", "save changes", or "check in", and after each step that works. Use this skill, not raw git commands.
license: MIT OR Apache-2.0
compatibility: Requires `git` on the system PATH, a writable Git working tree, and the `tools.shell` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
agent: committer
---

# Commit

Make a git commit with a good Conventional Commit message.

Run each git command with `tools.shell.execute`:

```js
return await tools.shell.execute({ command: "git status --short" });
```

## Rules

- Commit only the changes that are related to the task. A changed file can be from a different task, from the user, or from a different agent. Read the diff of each changed file before you stage it.
- Commit each change that the task made: the source, the tests, and the documents. Do not miss a file of the task.
- Do not stage a change that is not related to the task. Do not revert it. Give it in the report.
- If one file has changes for the task and other changes, do not split the file with an interactive command such as `git add -p`. Commit the file, and give the other changes in the report.
- Do not commit scratch files, temporary files, generated files, or build artifacts.
- Before you commit, look for sensitive data, for example keys and passwords.
- If the project makes scratch files, add their patterns to `.gitignore`.

## Safety

- Do not force push.
- Do not amend a commit that is pushed.
- You can commit directly to `main` or `master`.

## Process

1. Run `git status --short` and `git diff`. For each changed file, decide whether the change is related to the task.
2. Stage only the files of the task, by name. Do not use `git add -A` or `git add .`.
3. If the changes of the task are for different purposes, make one commit for each purpose.
4. Commit with a [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/#summary) message: `<type>(<scope>): <subject>`.

## Report

Give the short sha and the subject line of each commit:

```
42e32c3a3 fix(entity): parse frontmatter on line boundaries
```

If there is nothing to commit, say "nothing to commit". This is not an error.

## Examples

**A usual commit.** The user says "commit". `git status` shows `src/auth/login.rs`, `tests/auth.rs`, and an untracked file `scratch_notes.md`. Do not stage the scratch file. Stage the source and the test, then commit: `feat(auth): add JWT refresh endpoint`.

**Changes for different purposes.** `git status` shows a bug fix in `src/parser.rs` and a documentation change in `README.md`. Make two commits: `fix(parser): handle empty input without panicking`, then `docs: clarify installation steps for macOS`.

## Troubleshooting

### A pre-commit hook stops the commit

A hook of the repository (husky, pre-commit, lefthook) rejected the change. Read the output of the hook. Correct the problem in the files of the task only, stage those files again by name, and commit again. Do not use `--no-verify` unless the hook itself is broken.

```
npx prettier --write src/auth/login.ts
git add src/auth/login.ts
git commit -m "<same message>"
```

### Scratch files show in `git status` again and again

Add ignore patterns to `.gitignore`. If this is the first change to `.gitignore`, stage it in the same commit:

```
echo 'scratch_*.md' >> .gitignore
echo '*.tmp' >> .gitignore
git add .gitignore
```
