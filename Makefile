.PHONY: dev serve widget run ci test lint all

# Start everything — server + widget
all: serve widget

# Start the HTTP server (background) + CLI
serve:
	@cd packages/core && nudge serve &
	@echo "Server running at http://localhost:8000"

# Build and run the macOS menu bar widget
widget:
	@cd packages/widget && swift run

# Build the widget without running
widget-build:
	@cd packages/widget && swift build

# Start CLI voice assistant
run:
	@cd packages/core && nudge

# Install Python dependencies
dev:
	@cd packages/core && uv pip install -e ".[dev,server]"

# Run CI checks
ci:
	@cd packages/core && make ci

# Run tests only
test:
	@cd packages/core && make test

# Run linter only
lint:
	@cd packages/core && make lint

# Start server + widget together (foreground)
demo:
	@echo "Starting server..."
	@cd packages/core && nudge serve &
	@sleep 2
	@echo "Starting widget..."
	@cd packages/widget && swift run
