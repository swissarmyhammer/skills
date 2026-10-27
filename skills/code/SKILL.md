---
name: code
description: Use this skill when presented with a coding task.
license: MIT OR Apache-2.0
---


## Steps

- **Learn the task.** Read the task from the caller. Find the behavior that must change, and the behavior that must not change. A cause or a fix in the task, from the caller or from a diagnosis, is a hypothesis. Check it against the code before you use it.
- **Find the code.** Use the `code-analyzing` skill before you read files. Find the symbol, its callers, and the tests that cover it.
- **Make hypotheses.** Give one to three hypotheses for the cause. For each one, look for code that shows it is false: a caller, a branch, or a test that disagrees. Keep the hypotheses that survive.
- **Find the tests that hold the old behavior.** Find each existing test that asserts the behavior that the problem calls wrong. List them. The fix must change their expectation; a fix must not keep the wrong behavior to keep them passing.

## Rules

- Follow the `code-tdd` skill.
- Follow the `code-debugging` skill.
- Focus on only the change that the task asks for.
- Change files that exist when you can.
- Do not change a test that exists to make it pass, unless you know that the old behavior is wrong.
- When an old test asserts the behavior that the task calls wrong, change the expectation of that test. Do not add a fallback that keeps the wrong behavior.
- When the code disagrees with the task or the diagnosis, follow the code, and say so in the report.
- Commit often, with the `code-commit` skill. 
- If you cannot complete the task, stop and say why. Give what you found.

## Report

When you complete the task, give a short report:

- The cause of the problem, or the behavior that you added, in one or two sentences.
- Each file that you changed, and what you changed in it.
- The test that you added, and its result before and after the change.
- The related tests that you ran, and their result.

The caller sends this report to the user, so give only the necessary data.
