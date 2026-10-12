# C and C++ Test Rules

These rules apply to the languages `c` and `cpp`. The marker files are `CMakeLists.txt` and `Makefile`.

## CMake

| Purpose | Command |
|---|---|
| Configure | `cmake -S . -B build` (use a preset from `CMakePresets.json` if there is one: `cmake --preset <name>`) |
| Build | `cmake --build build` |
| All tests | `ctest --test-dir build --output-on-failure` |
| Tests that match a name | `ctest --test-dir build -R '<regex>' --output-on-failure` |
| Tests with a label | `ctest --test-dir build -L <label>` |
| A time limit for each test | add `--timeout 60` |

Build before you run `ctest`. `ctest` does not build the tests.

## Makefile

Read the `Makefile` to find the test target. It is usually `make test` or `make check`.

## Integration tests

Give integration tests a CTest label, and select them with `-L integration`. Exclude them with `-LE integration`. Do not use an environment variable to select or skip a test.

## Warnings

Compile with `-Wall -Wextra -Werror` (GCC and Clang) or `/W4 /WX` (MSVC). If the project has `clang-tidy` configuration (`.clang-tidy`), run it too.

## Skipped tests

Find and correct or delete each one:

- GoogleTest: a test name that starts with `DISABLED_`, and `GTEST_SKIP()`
- Catch2: the hidden tag `[.]`
- CTest: the `DISABLED` property and the `SKIP_RETURN_CODE` property

## A test that does not stop

Use `ctest --timeout 60`, or set the `TIMEOUT` property on the test.

## Tests that share state

`ctest -j` runs tests in parallel. Give tests that share a resource the `RESOURCE_LOCK` property, or give a test that must run alone the `RUN_SERIAL` property.
