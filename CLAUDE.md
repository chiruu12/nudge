# Nudge

Voice assistant that gets things done. Press a hotkey, speak, and Nudge handles the rest.

## Hackathon Context

Building for the **OpenAI x Outskill AI Builders Hackathon** (May 26-30, 2026).
- MVP deadline: May 28 (product brief + working product)
- Final submission: May 30 (go-live product)
- See `.context/plan.md` for day-by-day execution plan
- See `.context/hackathon.md` for rules and details

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

## Important Context Files

- `.context/plan.md` — Day-by-day hackathon execution plan with checklist
- `.context/architecture.md` — Full architecture, product tiers, hosted STT flow
- `.context/hackathon.md` — Hackathon rules, dates, prizes
- `.context/mutter-reference.md` — Reference to original codebase (now private)

## Conventions

- Read existing files before creating new ones — match patterns
- Keep commit messages short: one line, under 50 characters
- Describe WHAT shipped, not HOW you got there
- **Never expose internal process or iteration history in public output**
- No "after AI discussion", no "based on grilling session", no process narration
- The GitHub profile should look like a skilled developer shipping clean work
- No multi-paragraph commit bodies unless truly necessary

## What's Done vs TODO

**DONE:** packages/core (engine, CLI, 33 tests, all transports, soul system, presets)
**TODO:** packages/web (Next.js site), packages/api (hosted FastAPI backend)

## Design System
Always read DESIGN.md before making any visual or UI decisions.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.
