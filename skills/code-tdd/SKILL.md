---
name: code-tdd
description: Use before you write code for a feature, a bug fix, a refactor, or a change of behavior. Write a test that fails, then write the code that makes it pass.
license: MIT OR Apache-2.0
---

# Test-Driven Development

**Write the test first. See it fail. Then write the minimum code that makes it pass.**

If you did not see the test fail, you do not know that it tests the correct thing.

## When to use

- Use it for a new feature, a bug fix, a refactor, and a change of behavior.
- Do not use it for documentation, configuration files, generated code, or a prototype that you will discard. Do not write a test that asserts documentation.

## Run the tests

Run the tests with the `code-test` skill, in its subagent. Thus the test output stays out of your context. Give it the scope:

- For RED and GREEN, the scope is the new test, by name.
- After a correction, the scope is the tests that failed, by name.
- When the feature is complete, give no scope. `code-test` finds the scope of the change.

## The cycle

### 1. RED: write a test that fails

Write one small test for one behavior. Give it a name that tells the behavior. Use the real code. Use a mock only when there is no other way.

Good: the name tells the behavior, and the test uses the real code.

```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```

Bad: the name tells nothing, and the test examines the mock, not the code.

```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```

### 2. Make sure that the test fails

**Always do this step.** Run only the new test, one time. Make sure of these three things in the output:

- The test fails. It does not stop with an error.
- The failure message is the message that you expect.
- The test fails because the feature is not there, not because of a typing error.

If the test passes, it examines behavior that is already there. Change the test. If the test stops with an error, correct the error, and run the test one more time.

### 3. GREEN: write the minimum code

Write the simplest code that makes the test pass. Do not add options or features that the test does not need.

```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```

### 4. Make sure that the test passes

**Always do this step.** Run only the new test, one time. Make sure that it passes, and that the output has no errors and no warnings.

If the test fails, correct the code, not the test. Then run that test one more time. If other tests fail, correct only those tests, and run only those tests after each correction.

Do not run the tests of the change after each cycle. Run them one time when the feature is complete.

### 5. REFACTOR

Only after GREEN: remove duplicate code, make the names better, and move code into helpers. Keep the tests green. Do not add behavior.

### 6. Do the cycle again

Write the next failing test for the next behavior.

## Where the test goes

- **The cycle uses only unit tests.** Each unit test completes in less than 10 seconds, and it does not need an external system. When the logic needs a slow dependency, use a fake at an interface.
- **A test that needs an external system is an integration test.** Examples are the network, a database, a server, and a real model. Put it in the integration target of that system. It is not part of the cycle.
- **Select tests only with the methods of the platform:** targets, packages, paths, and markers. Do not use an environment variable to turn a test on or off.

## Good tests

| Quality | Good | Bad |
|---|---|---|
| Small | One behavior. If the name has "and", make two tests. | `test('validates email and domain and whitespace')` |
| Clear | The name tells the behavior. | `test('test1')` |
| Shows the intent | The test shows the API that you want. | The test hides what the code must do. |

## Stop signals

If one of these is true, delete the code and start again with a test:

- You wrote code before the test.
- You wrote the test after the code.
- The new test passed immediately.
- You cannot tell why the test failed.
- You think "I examined it manually", "only this one time", "this is different", or "I keep the old code as a reference".

A test that you write after the code passes immediately. It proves nothing, because you did not see it fail. Code that you cannot trust is the waste, not the time that you used to write it.

## Before the work is complete

- [ ] Each new function or method has a test.
- [ ] You saw each test fail before you wrote the code.
- [ ] Each test failed for the expected reason.
- [ ] You wrote the minimum code to make each test pass.
- [ ] All tests of the change pass in one `code-test` run with no scope.
- [ ] You did not run a test again without a code change between the two runs.
- [ ] The output has no errors and no warnings.
- [ ] The tests use the real code. They use a mock only when there is no other way.
- [ ] The tests cover the edge cases and the errors.

If one item is not true, you did not follow this skill. Start again.
