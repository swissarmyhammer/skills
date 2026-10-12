# Ruby Test Rules

## Commands

Run the commands with `bundle exec` when the project has a `Gemfile`. Do not search for test files.

| Purpose | RSpec | Minitest |
|---|---|---|
| All tests | `bundle exec rspec` | `bundle exec rake test` |
| One file | `bundle exec rspec spec/<file>_spec.rb` | `bundle exec ruby -Itest test/<file>_test.rb` |
| One test | `bundle exec rspec spec/<file>_spec.rb:<line>` | `bundle exec ruby -Itest test/<file>_test.rb -n <test_name>` |

In a Rails application, use `bin/rails test` for Minitest. Use `bin/rails test:system` for system tests.

Lint: `bundle exec rubocop`.

## Integration tests

Select integration tests with a path or a tag:

- `bundle exec rspec spec/integration`
- `bundle exec rspec --tag integration`

Do not use an environment variable to select or skip a test.

## Skipped tests

Find and correct or delete each one: `skip`, `xit`, `xdescribe`, `xcontext`, `pending`.

## A test that does not stop

RSpec and Minitest do not have a time limit. Run the suspect test with the shell `timeout`: `timeout 60 bundle exec rspec spec/<file>_spec.rb:<line>`.

## Tests that share state

Use `Dir.mktmpdir` for files. For parallel runs (`parallel_tests`, or `parallelize` in Rails), give each worker its own database and its own port.
