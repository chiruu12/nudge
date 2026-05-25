# Nudge

Voice assistant that actually gets things done. Press a hotkey, speak, and Nudge handles the rest — tasks, alarms, notes, clipboard, links.

Built on [Hive](https://github.com/chiruu12/Hive), a local-first agent framework. Open source. Bring your own LLM.

## How It Works

```
You speak → STT transcribes → Intent classified → Agent acts → Done
```

```bash
# "Remind me to call mom tomorrow"
→ STT: "remind me to call mom tomorrow" (Groq Whisper, 340ms)
→ Intent: alarm (92%) (120ms)
→ Agent: set_alarm("Call mom", 24h) (280ms)
✓ Total: 740ms
```

## Install

```bash
pip install nudge-ai
nudge setup
```

## Quick Start

```bash
nudge              # Start — press hotkey to record
nudge test         # Quick 2s recording test
nudge preset fast  # Switch to Groq free tier (200ms responses)
```

## Features

- **Voice-first** — Hotkey to record, release to process
- **Tasks & Alarms** — Create todos, set reminders naturally
- **Knowledge Base** — Save and recall notes with semantic search
- **Clipboard & Links** — Copy results, save URLs by voice
- **Soul System** — Personalize behavior via `~/.nudge/soul.md`
- **Provider Flexibility** — Groq, OpenAI, Anthropic, Ollama, LM Studio
- **Presets** — `fast` (free cloud), `offline` (local), `default` (balanced)
- **Pipeline Timing** — See exactly how long each stage takes

## Presets

| Preset | STT | LLM | Latency | Cost |
|--------|-----|-----|---------|------|
| `fast` | Groq Whisper | Groq (lite) | ~200ms | Free |
| `default` | Groq Whisper | Groq (standard) | ~500ms | Free |
| `offline` | Local Whisper | Ollama | ~2s | $0 |

## Soul System

Nudge reads `~/.nudge/soul.md` to understand how you work:

```bash
nudge soul edit   # Open in your editor
nudge soul show   # Display current soul
```

Example:
```markdown
## Who You Are
name: Alex
timezone: America/New_York

## How You Work
- "Later" means this evening
- High priority = today, Medium = this week
- Keep task descriptions short
```

## Commands

| Command | Description |
|---------|-------------|
| `nudge` | Start voice assistant (hotkey mode) |
| `nudge setup` | Interactive setup wizard |
| `nudge test` | 2s recording test |
| `nudge config` | Show configuration |
| `nudge preset NAME` | Load preset (default/fast/offline) |
| `nudge serve` | Start HTTP server |
| `nudge history` | Recent interactions |
| `nudge soul show` | Display soul.md |
| `nudge soul edit` | Edit soul.md |

## Project Structure

```
nudge/
├── packages/
│   ├── core/       # Python: voice engine + CLI
│   ├── web/        # Next.js: landing page + dashboard
│   └── api/        # FastAPI: hosted backend
├── docs/
└── README.md
```

## Development

```bash
cd packages/core
uv venv && source .venv/bin/activate
uv pip install -e ".[dev,server]"
make test
make lint
```

## License

MIT
