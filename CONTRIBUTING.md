# Contributing to Nudge

Thanks for your interest in contributing! Nudge is open source and welcomes contributions of all kinds.

## Getting Started

```bash
git clone https://github.com/chiruu12/nudge.git
cd nudge/packages/core
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev,server]"
```

## Development Workflow

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Run `make ci` to verify lint, types, and tests pass
4. Commit with a short, descriptive message (under 50 chars)
5. Open a PR against `main`

## Running Checks

```bash
make ci          # lint + typecheck + test (all three)
make lint        # ruff check
make typecheck   # mypy
make test        # pytest
make lint-fix    # auto-fix lint issues
```

All PRs must pass `make ci` before merge.

## Code Style

- **Linter:** Ruff (line length 100)
- **Type checker:** mypy (strict where possible)
- **Tests:** pytest with pytest-asyncio for async code
- **Commits:** One line, under 50 chars, describe what shipped

## Project Structure

```
packages/core/src/nudge/
  core/       # Engine, config, providers, session model
  transport/  # CLI, HTTP server, hotkey listener
  tools/      # Launcher, named links
  audio/      # Recording manager
  storage/    # Session history (JSONL)
  presets/    # YAML config presets
  app/        # Setup wizard
```

## What to Contribute

- Bug fixes with a failing test
- New intents or toolkits
- Provider integrations
- Documentation improvements
- Performance optimizations with benchmarks

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be kind, be constructive.
