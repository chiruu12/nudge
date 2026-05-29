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

## macOS App (menu-bar widget)

The widget ships as a standalone menu-bar app. It auto-starts the local Python
server (`nudge serve`) if it isn't already running, so the Python package must be
installed:

```bash
pip install nudge-ai      # or: pipx install nudge-ai
```

### Build

```bash
make icon          # generate packages/widget/Nudge.icns from the source PNG
make app           # build dist/Nudge.app (ad-hoc signed)
make dmg           # build dist/Nudge-0.1.0.dmg
make signing-cert  # optional, run once: stable self-signed identity
```

`make icon` reads `packages/widget/icon-source/Nudge.png`, or pass a path:
`packages/widget/scripts/make-icon.sh /path/to/logo.png`.

`make signing-cert` creates a self-signed "Nudge Dev" code-signing identity in
your login keychain so the microphone permission survives rebuilds (otherwise
each `make app` re-prompts). It is not notarization — the Gatekeeper step below
still applies.

### Using the app

- **Left-click** the menu-bar icon → open the dashboard popover.
- **Right-click** (or Control-click) the icon → menu with **Open**, **Restart
  Backend**, **Launch at Login**, and **Quit Nudge**.
- The same actions live in the dashboard's **Settings** tab.

The app auto-starts `nudge serve` on launch and stops the server it started when
you quit.

### Install & first launch

Drag **Nudge.app** from the DMG into **Applications**. Because the app is
ad-hoc signed (not notarized), Gatekeeper blocks a normal double-click the first
time. To open it:

1. Right-click (or Control-click) **Nudge.app** → **Open**
2. Click **Open** in the dialog

After this once, it launches normally. On the first voice command, macOS asks for
**microphone** permission — click Allow.

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
