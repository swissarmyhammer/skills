---
name: commit
description: Git commit workflow. Use this skill whenever the user says "commit", "save changes", "check in", or otherwise wants to commit code. Always use this skill instead of running git commands directly.
license: MIT OR Apache-2.0
compatibility: Requires `git` on the system PATH, a writable Git working tree, and the `tools.shell` verbs of a code-mode host such as FoundationModelsMultitool. The model calls them in the `runCode` tool.
agent: committer
metadata:
  author: swissarmyhammer
  version: "1.0.0"
---

# Commit

Make a git commit with a good Conventional Commit message.

Run each git command with `tools.shell.execute`:

```js
return await tools.shell.execute({ command: "git status --short" });
```

## Rules

- Commit only the source that you intend to commit. Do not commit scratch files, temporary files, generated files, or build artifacts.
- Commit all of the changed source on the branch. Do not miss a file.
- If you are not sure about a file, do not commit it.
- Before you commit, look for sensitive data, for example keys and passwords.
- If the project makes scratch files, add their patterns to `.gitignore`.

## Safety

- Do not force push.
- Do not amend a commit that is pushed.
- Do not commit directly to `main` or `master` unless the caller tells you to.

## Process

1. Run `git status --short`. Stage the source and the tests. Do not stage scratch files.
2. If the changes are for different purposes, make one commit for each purpose.
3. Commit with a [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/#summary) message: `<type>(<scope>): <subject>`.

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

A hook of the repository (husky, pre-commit, lefthook) rejected the change. Read the output of the hook. Correct the problem, stage the files again, and commit again. Do not use `--no-verify` unless the hook itself is broken.

```
npx prettier --write .
git add -A
git commit -m "<same message>"
```

### Scratch files show in `git status` again and again

Add ignore patterns to `.gitignore`. If this is the first change to `.gitignore`, stage it in the same commit:

```
echo 'scratch_*.md' >> .gitignore
echo '*.tmp' >> .gitignore
git add .gitignore
```
