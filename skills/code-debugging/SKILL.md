---
name: code-debugging
description: Use when a test fails, a build fails, or the code does not do what it must do. Find the root cause before you change code.
license: MIT OR Apache-2.0
---

# Debugging

**Find the root cause before you change code. A change to a symptom is a failure.**

Use this skill for each technical problem: a test failure, a bug, behavior that you did not expect, a performance problem, a build failure, or an integration problem. Use it also when the problem looks simple, when a fix looks obvious, and when a fix did not work.

Do the four phases in sequence. Complete each phase before you start the next phase.

## Phase 1: Find the cause

1. **Read the error.** Read all of the error message, the warnings, and the stack trace. Write down the file, the line, and the error code.
2. **Make the problem occur again.** Find the exact steps. If the problem does not occur each time, get more data. Do not guess, and do not run the test in a loop.
3. **Examine the recent changes.** Read `git diff` and the recent commits. Look for new dependencies, configuration changes, and differences in the environment.
4. **Trace the bad value back to its source.** Use the `code-analyzing` verbs:
   - `getSymbol` gives the source of the function that fails.
   - `getCallgraph({ symbol, direction: "inbound" })` and `getInboundCalls` give its callers.
   - `getReferences` gives each use of the value.

   Go back through the callers until you find where the bad value starts. The fix goes there, not where the error shows.
5. **In a system with many components, find the component that fails.** Examples are CI → build → signing, and API → service → database. At each boundary, log the data that goes in, the data that comes out, and the configuration. Run one time. Then examine only the component where the data becomes bad.

## Phase 2: Compare with code that works

1. Find code in the same repository that is similar and that works. Use `searchSymbol` and `grepCode`.
2. If you use a pattern, read all of the reference code. Do not read only a part of it.
3. List each difference between the code that works and the code that fails. Do not ignore a small difference.
4. Find what the code needs: other components, settings, configuration, and the environment.

## Phase 3: Make hypotheses

1. Write one to three hypotheses. Write each one as: "X is the root cause, because Y". Make each one specific.
2. For each hypothesis, look for code that shows that it is false: a caller, a branch, or a test that disagrees. Keep the hypotheses that survive.
3. If no hypothesis survives, go back to Phase 1. If you do not understand a part, say "I do not understand X". Do not guess.

## Phase 4: Fix the cause

1. Write a test that fails because of the root cause. Follow the `code-tdd` skill.
2. Make one change at the root cause. Do not make more than one change at a time.
3. Run the test with the `code-test` skill. If the test fails, the hypothesis is false. Undo the change, and go back to Phase 3.
4. If each fix shows a new problem in a different location, stop. The root cause is not found. Go back to Phase 1.

## Stop signals

If you think one of these, stop and go back to Phase 1:

- "A quick fix now, and I examine it later."
- "I change X and look at the result."
- "I make many changes, and then I run the tests."
- "I do not need a test. I can examine it manually."
- "It is probably X."
- "I do not understand all of it, but this can work."
- "The pattern does X, but I do it in a different way."
- You list fixes before you trace the data.
- Each fix shows a new problem in a different location.
