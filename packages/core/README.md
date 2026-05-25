# Nudge

Voice assistant that actually gets things done. Speak, and Nudge handles the rest.

Built on [Hive](https://github.com/chiruu12/Hive), a local-first agent framework.

## Install

```bash
pip install nudge-ai
```

## Quick Start

```bash
# Interactive setup
nudge setup

# Start voice assistant
nudge

# Quick test (2s recording)
nudge test

# Load a preset
nudge preset fast      # Groq free tier
nudge preset offline   # Local inference (Ollama)
```

## Features

- **Voice-first** — Press a hotkey, speak, get things done
- **Tasks & Alarms** — Create todos, set reminders with your voice
- **Knowledge Base** — Save and recall notes with semantic search
- **Provider flexibility** — Groq, OpenAI, Anthropic, Ollama, LM Studio
- **Soul system** — Customize personality via `~/.nudge/soul.md`
- **Presets** — Switch between cloud/local/fast configs instantly

## Commands

```bash
nudge              # Start (hotkey mode)
nudge setup        # Interactive wizard
nudge test         # 2s live recording test
nudge config       # Show current config
nudge preset NAME  # Load preset (default/fast/offline)
nudge serve        # Start HTTP server
nudge history      # Show recent sessions
nudge soul show    # Display your soul.md
nudge soul edit    # Open soul.md in $EDITOR
```

## License

MIT
