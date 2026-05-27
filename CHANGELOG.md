# Changelog

## 0.1.0 (2026-05-27)

Initial release.

- Voice pipeline: STT → Intent Classification → Agent Action
- 6 LLM providers: Groq, OpenAI, Anthropic, Ollama, LM Studio, Fireworks
- 4 presets: default, fast, offline, openai
- 7 intents: task, alarm, note, query, link, clipboard, launch
- Soul system for personality customization (`~/.nudge/soul.md`)
- CLI with 10 commands (nudge, setup, test, config, preset, serve, history, soul, links)
- HTTP server with CORS for local web development
- Codex/Claude Code/Cursor launcher with voice prompt passthrough
- Named link management (save/open/copy/list/remove URLs by voice)
- Pipeline timing in every result (stt_ms, intent_ms, agent_ms)
- 104 tests passing, ruff + mypy clean
- GitHub Actions CI
