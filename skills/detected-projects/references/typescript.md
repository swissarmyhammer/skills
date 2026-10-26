# JavaScript and TypeScript Test Rules

These rules apply to the languages `javascript`, `typescript`, and `tsx`. The marker file of the three languages is `package.json`.

## Package manager

1. If `package.json` has `"packageManager": "<name>@..."`, use that package manager. If a `preinstall` script uses `only-allow <name>`, use that package manager.
2. If not, use the lock file:

   | Lock file | Package manager |
   |---|---|
   | `package-lock.json` | `npm` |
   | `pnpm-lock.yaml` | `pnpm` |
   | `yarn.lock` | `yarn` |
   | `bun.lockb` or `bun.lock` | `bun` |

Do not use two package managers in one project.

## Commands

Read the `scripts` of `package.json` first. Use the scripts that the project has, for example `test`, `lint`, `typecheck`, or `test:integration`. Do not search for test files. The runner finds the tests.

| Purpose | Command |
|---|---|
| All tests | `npm test` (or `pnpm test`, `yarn test`, `bun run test`) |
| One file | `npm test -- path/to/file.test.ts` |
| One test, Jest or Vitest | `npm test -- -t '<test name>'` |
| Type check | `npx tsc --noEmit` (or the `typecheck` script) |
| Lint with warnings as errors | `npx eslint . --max-warnings=0` (or the `lint` script) |

Find the runner in `devDependencies`: `jest`, `vitest`, `mocha`, `ava`, or none (`node --test`).

## Integration tests

Select integration tests with the structure of the project:

- a script, for example `npm run test:integration`
- a project of the runner, for example `vitest --project integration` or `jest --selectProjects integration`
- a path, for example `npm test -- tests/integration`

Do not use an environment variable to select or skip a test.

## Skipped tests

Find and correct or delete each one: `.skip`, `xit`, `xdescribe`, `xtest`, `.todo`. Also find each `.only`. A `.only` makes the runner skip all of the other tests.

## A test that does not stop

| Runner | Time limit |
|---|---|
| Jest | `--testTimeout=60000` |
| Vitest | `--testTimeout=60000` |
| Mocha | `--timeout 60000` |
| `node --test` | `--test-timeout=60000` |

Jest can also wait for an open handle after the tests. Use `--detectOpenHandles` to find it, and close the handle in the test.

## Tests that share state

Bind port `0` and read the port that you get. Use a new temporary directory for each test. To find tests that share state, run Jest with `--runInBand` one time. Do not keep `--runInBand` as the fix.
