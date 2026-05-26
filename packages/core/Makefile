.PHONY: dev test test-quick lint format typecheck ci run serve

dev:
	uv pip install -e ".[dev,server]"

test:
	python -m pytest tests/ -v

test-quick:
	python -m pytest tests/ -v --ignore=tests/integration

lint:
	ruff check src/ tests/
	ruff format --check src/ tests/

format:
	ruff format src/ tests/
	ruff check --fix src/ tests/

typecheck:
	mypy src/nudge/

ci: lint typecheck test

run:
	nudge

serve:
	nudge serve
