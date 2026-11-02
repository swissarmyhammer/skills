---
name: code-tdd
description: Use before you write code for a feature, a bug fix, a refactor, or a change of behavior. Write a test that fails, then write the code that makes it pass.
license: MIT OR Apache-2.0
---

# Test-Driven Development

**Write the test first. See it fail. Then write the minimum code that makes it pass.**

If you did not see the test fail, you do not know that it tests the correct thing.

## DO

- Test 
  - new features
  - bug fixes
  - changes
  - refactors
- Create small, fast unit tests with a single assertion
- Use fixtures or test setup for shared test initialization

## DO NOT

- Create test that assert the contents of doc strings
- Create tests that scan the source itself and assert on source strings
- Write a test that asserts documentation

## Unit vs Integration

Unit tests are small, fast, and focused. An ideal unit test has a single assertion. Use them in TDD.

Integration tests are larger, scenario driven tests involving real data, models, complex setups, and multiple assertion. Do not use them in TDD, use them in CI.

Keep unit tests separated from integration tests in the code. This allows you a faster TDD cycle by focusing only on unit tests. 

## Run the tests

Run the tests with the `tester` subagent. Thus the test output stays out of your context. Give it the scope:

- Initially, the scope is the tests you have just created.
- After a correction, the scope is the tests that failed, by name.

## The cycle

### RED: write a test that fails

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

**Always do this step.** Run only the new tests, one time. Make sure of these three things in the output:

- The test fails `red`, this is the initial state of TDD before you code.
- The failure message is the message that you expect.

### GREEN: write the minimum code

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

**Always do this step.** Run only the new test, one time. Make sure that it passes, and that the output has no errors and no warnings.

If the test fails, correct the code, not the test. Repeat until passing.

### REFACTOR

Only after GREEN. Refactor your code, keeping tests passing.

### REPEAT

Write the next failing test for the next behavior.

## Where the test goes

- **The cycle uses only unit tests** Each unit test must complete in less than 10 seconds. 
- **A test that needs an external system** Examples are the network, a database, a server, and a real model. Fake or mock.
- **Select tests only with the methods of the platform:** targets, packages, paths, and markers. Do not use an environment variable to turn a test on or off.

## Good tests

| Quality | Good | Bad |
|---|---|---|
| Small | One behavior. If the name has "and", make two tests. | `test('validates email and domain and whitespace')` |
| Clear | The name tells the behavior. | `test('test1')` |
| Shows the intent | The test shows the API that you want. | The test hides what the code must do. |

## Checklist

- [ ] Each new function or method has a test.
- [ ] You saw each test fail before you wrote the code.
- [ ] Each test failed for the expected reason.
- [ ] You wrote the minimum code to make each test pass.
- [ ] The output has no errors and no warnings.
- [ ] The tests cover the edge cases and the errors.
