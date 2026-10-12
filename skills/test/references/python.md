# Python Test Rules

## Environment

Before you run a test, find the virtual environment of the project: `.venv/`, `venv/`, or `env/`. Use its interpreter, for example `.venv/bin/python -m pytest`. If the project uses a tool that manages the environment, run the tests through that tool:

| File | Command |
|---|---|
| `uv.lock` | `uv run pytest` |
| `poetry.lock` | `poetry run pytest` |
| `tox.ini` | `tox` (all environments) or `tox -e <env>` |
| `noxfile.py` | `nox` or `nox -s <session>` |

## Commands

Do not search for test files. The runner finds the tests.

| Purpose | Command |
|---|---|
| All tests | `python -m pytest` |
| unittest (no pytest in the project) | `python -m unittest discover` |
| One file | `python -m pytest tests/test_file.py` |
| One test | `python -m pytest tests/test_file.py::test_name` |
| Show the reason for each skip | add `-rsx` |
| Make warnings into errors | add `-W error` |
| Lint | `ruff check .` (or the linter in `pyproject.toml`) |
| Type check | `mypy .` or `pyright` (the checker in the configuration) |

The project can set `filterwarnings = ["error"]` in `pyproject.toml`. If it does not, use `-W error`.

## Integration tests

Put integration tests in their own directory, or give them a registered marker. Select them directly:

- `python -m pytest tests/integration/`
- `python -m pytest -m integration`

Register the marker in `pyproject.toml` (`[tool.pytest.ini_options] markers`). Do not use an environment variable to select or skip a test.

## Skipped tests

Find and correct or delete each one: `@pytest.mark.skip`, `@pytest.mark.skipif`, `@pytest.mark.xfail`, `pytest.skip(...)`, `@unittest.skip`. Use `-rsx` to see them in the output.

## A test that does not stop

Use `pytest-timeout`: `python -m pytest --timeout=60`. If it is not installed, use the shell `timeout`: `timeout 60 python -m pytest <test>`.

## Tests that share state

- Use the `tmp_path` fixture for files, and `monkeypatch` for environment variables and the current directory.
- With `pytest-xdist` (`-n auto`), give tests that must not run at the same time one `@pytest.mark.xdist_group("<name>")`, and run with `--dist loadgroup`.
