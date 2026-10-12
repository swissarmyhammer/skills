# PHP Test Rules

## Commands

Read the `scripts` of `composer.json` first. If it has a `test` script, use `composer test`. Do not search for test files.

| Purpose | PHPUnit | Pest |
|---|---|---|
| All tests | `vendor/bin/phpunit` | `vendor/bin/pest` |
| One test suite | `vendor/bin/phpunit --testsuite <name>` | `vendor/bin/pest --testsuite <name>` |
| One test | `vendor/bin/phpunit --filter '<name>'` | `vendor/bin/pest --filter '<name>'` |
| Fail on warnings and skips (PHPUnit 10 and later) | add `--fail-on-warning --fail-on-risky --fail-on-skipped` | the same options |

Static analysis: `vendor/bin/phpstan analyse` or `vendor/bin/psalm` (the tool that the project uses).

## Integration tests

Put integration tests in a test suite of their own in `phpunit.xml`, and select it with `--testsuite integration`. Do not use an environment variable to select or skip a test.

## Skipped tests

Find and correct or delete each one: `markTestSkipped()`, `markTestIncomplete()`, the `#[RequiresPhp]` and `#[RequiresPhpExtension]` attributes that are not satisfied, and `->skip()` in Pest.

## A test that does not stop

PHPUnit time limits need the `php-invoker` package. If it is not installed, run the suspect test with the shell `timeout`: `timeout 60 vendor/bin/phpunit --filter '<name>'`.

## Tests that share state

Use `sys_get_temp_dir()` with a new directory for each test. For parallel runs (ParaTest, or `pest --parallel`), give each worker its own database.
