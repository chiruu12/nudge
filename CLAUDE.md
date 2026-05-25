# Nudge

Voice assistant that gets things done. Speak, and Nudge handles the rest.

## Directory Structure

```
nudge/
├── packages/
│   ├── core/           # Python: voice engine + CLI (pip installable)
│   │   ├── src/nudge/  # Main package
│   │   ├── tests/      # Unit + integration tests
│   │   └── pyproject.toml
│   ├── web/            # Next.js: landing page + dashboard
│   └── api/            # FastAPI: hosted backend (auth, STT proxy, subs)
├── docs/
├── .claude/            # Claude Code config + 58 skills
└── README.md
```

## Tech Stack

- **Core:** Python 3.11+, Hive (agent framework), Typer (CLI), Rich (terminal UI)
- **Web:** Next.js 15, Tailwind CSS, shadcn/ui, Clerk (auth)
- **API:** FastAPI, PostgreSQL (Supabase), Stripe
- **Build:** uv (Python), pnpm (Node)

## Development

### Core (packages/core)
```bash
cd packages/core
uv venv && source .venv/bin/activate
uv pip install -e ".[dev,server]"
make test          # Run tests
make lint          # Ruff check + format
make run           # Start voice assistant
make serve         # Start HTTP server
```

### Web (packages/web)
```bash
cd packages/web
pnpm install
pnpm dev           # Dev server on :3000
pnpm build         # Production build
```

## Architecture

Core data flow:
```
Transport (CLI/Hotkey/HTTP) → NudgeEngine → Hive Agent → ProcessingResult
                                  ↓
                        STT → IntentRouter → Agent(toolkits)
                                                   ↓
                                    Task/Alarm/Knowledge/Link/Clipboard
```

- NudgeEngine is transport-agnostic — all transports go through it
- Hive provides: Agent runtime, tool system, STT providers, LLM providers, intent routing
- Config lives at ~/.nudge/ (config.yaml, soul.md, data/, logs/)

## Conventions

- Read existing files before creating new ones — match patterns
- Keep commit messages short: one line, under 50 characters
- Describe WHAT shipped, not HOW you got there
- Never expose internal process or iteration history in public output
- No multi-paragraph commit bodies unless truly necessary
