# Nudge - Backend Agent Implementation Guide

## Overview
This document provides everything a coding agent needs to build the Nudge backend, API, and integrations. Nudge is a voice-first assistant that processes spoken commands through a pipeline: Voice → STT → Intent Classification → Agent Action.

## Architecture

```
User speaks
    ↓
[Audio Capture] → raw audio (macOS AVAudioEngine)
    ↓
[STT Provider] → transcript string
    ↓
[Intent Classifier] → intent + confidence + entities
    ↓
[Agent Router] → dispatches to the right agent
    ↓
[Agent] → executes action (create task, set alarm, save note, etc.)
    ↓
[Response] → confirmation back to UI
```

## Core Pipeline

### 1. Audio Capture
- macOS: `AVAudioEngine` for real-time mic capture
- Format: 16kHz mono PCM (most STT providers prefer this)
- Global hotkey: `cmd+shift+n` triggers recording
- Recording ends on: silence detection (1.5s pause) or manual stop (hotkey again / Esc)
- Max duration: 30 seconds

### 2. STT (Speech-to-Text)
Abstracted provider interface. All providers implement:

```python
class STTProvider:
    async def transcribe(audio: bytes) -> STTResult:
        # Returns: text, confidence, language, duration_ms
```

**Supported Providers:**
| Provider | Model | Tier | Latency | Cost |
|----------|-------|------|---------|------|
| Groq | whisper-large-v3 | free | ~200ms | $0 |
| Groq | whisper-large-v3 | standard | ~300ms | $0.006/min |
| OpenAI | whisper-1 | standard | ~500ms | $0.006/min |
| Ollama | whisper (local) | local | ~2s | $0 |
| LM Studio | whisper (local) | local | ~2s | $0 |
| Fireworks | whisper-v3 | standard | ~400ms | $0.004/min |

### 3. Intent Classification
Takes the transcript and classifies it into one of the supported intents.

**Supported Intents:**
| Intent | Description | Example |
|--------|-------------|---------|
| `task` | Create a new task | "add task to deploy by Friday" |
| `alarm` | Set a time-based reminder | "remind me in 2 hours" |
| `save` | Save to knowledge base | "save: API needs OAuth2" |
| `copy` | Clipboard operation | "copy that error message" |
| `search` | Search knowledge base | "what did I save about the API?" |
| `soul` | Add a personal rule | "later means this evening" |
| `config` | Change configuration | "switch to offline mode" |
| `list` | List tasks/alarms/notes | "what are my tasks?" |
| `done` | Mark task as complete | "mark standup as done" |
| `delete` | Remove task/alarm/note | "delete the dentist alarm" |

**Classification approach:**
- Use LLM with a structured prompt
- Return: intent name, confidence score (0-1), extracted entities
- Fallback: if confidence < 0.6, ask user to clarify

### 4. Agent Router
Maps intents to agent functions:

```python
AGENTS = {
    'task': TaskAgent,
    'alarm': AlarmAgent,
    'save': KnowledgeAgent,
    'copy': ClipboardAgent,
    'search': SearchAgent,
    'soul': SoulAgent,
    'config': ConfigAgent,
    'list': ListAgent,
    'done': CompleteAgent,
    'delete': DeleteAgent,
}
```

### 5. LLM Providers
Same abstraction as STT:

```python
class LLMProvider:
    async def complete(prompt: str, system: str = None) -> str:
        # Returns: completion text
```

**Supported Providers:**
| Provider | Model | Tier | Latency | Cost |
|----------|-------|------|---------|------|
| Groq | llama-3.3-70b | free | ~100ms | $0 |
| Groq | llama-3.3-70b | standard | ~150ms | $0.01/1K tok |
| OpenAI | gpt-4o-mini | standard | ~300ms | $0.15/1M tok |
| Anthropic | claude-haiku | standard | ~400ms | $0.25/1M tok |
| Ollama | llama-3.2 | local | ~1.5s | $0 |
| LM Studio | any local | local | ~1.5s | $0 |
| Fireworks | llama-v3p1-70b | standard | ~200ms | $0.01/1K tok |

## Data Models

### Task
```json
{
  "id": "uuid",
  "title": "Deploy by Friday",
  "done": false,
  "created_at": "2026-05-26T10:00:00Z",
  "completed_at": null,
  "source": "voice",
  "priority": "normal",
  "due_date": "2026-05-30T00:00:00Z"
}
```

### Alarm
```json
{
  "id": "uuid",
  "label": "Call dentist",
  "time": "2026-05-26T15:00:00Z",
  "recurring": null,
  "enabled": true,
  "created_at": "2026-05-26T10:00:00Z",
  "source": "voice"
}
```

### Knowledge Entry
```json
{
  "id": "uuid",
  "content": "API needs OAuth2 for the new endpoint",
  "tags": ["api", "auth"],
  "created_at": "2026-05-26T10:00:00Z",
  "source": "voice"
}
```

### Soul Rule
```json
{
  "id": "uuid",
  "pattern": "later",
  "meaning": "this evening (after 6pm)",
  "created_at": "2026-05-26T10:00:00Z"
}
```

### Voice Command (History)
```json
{
  "id": "uuid",
  "transcript": "remind me to call the dentist at 3pm",
  "intent": "alarm",
  "confidence": 0.94,
  "entities": { "label": "Call dentist", "time": "3:00 PM" },
  "action_result": "Alarm set for 3:00 PM",
  "pipeline_ms": { "stt": 340, "intent": 120, "agent": 280, "total": 740 },
  "created_at": "2026-05-26T10:00:00Z"
}
```

## Configuration

### Config File: `~/.nudge/config.yaml`

```yaml
version: 1

hotkey: cmd+shift+n

stt:
  provider: groq
  model: whisper-large-v3
  tier: free

llm:
  provider: groq
  model: llama-3.3-70b
  tier: free

notifications: true
sound_effects: true
launch_at_login: true
silence_threshold: 1.5  # seconds
max_recording: 30       # seconds

soul_rules: []

skills:
  writing_style: null
  projects: []
  vocabulary: {}
```

### Presets

**Fast** (speed priority):
```yaml
stt: { provider: groq, model: whisper-large-v3, tier: free }
llm: { provider: groq, model: llama-3.3-70b, tier: free }
```

**Default** (balanced):
```yaml
stt: { provider: groq, model: whisper-large-v3, tier: standard }
llm: { provider: groq, model: llama-3.3-70b, tier: standard }
```

**Offline** (privacy):
```yaml
stt: { provider: ollama, model: whisper-local }
llm: { provider: ollama, model: llama-3.2 }
```

## Soul System

The Soul System lets users teach Nudge their personal language. Rules are applied during intent classification to resolve ambiguous terms.

**How it works:**
1. User says: "later means this evening"
2. Nudge creates a soul rule: `later → this evening (after 6pm)`
3. Next time user says "remind me later," Nudge interprets "later" as "6pm today"

**Rule types:**
- Time aliases: "later = evening", "ASAP = within the hour"
- Priority aliases: "high priority = before EOD"
- Team aliases: "the team = engineering team"
- Project aliases: "the project = Nudge v2"

**Implementation:**
- Store rules in `~/.nudge/soul_rules.json`
- Inject active rules into the LLM system prompt during intent classification
- Rules are ordered by recency (newer rules override older ones)

## Skills System

Skills are interactive onboarding flows that learn about the user. They gather context that makes Nudge smarter over time.

### IDE Knowledge Transfer
- Connects to Cursor, Claude Code, or Codex
- Reads project structure, recent files, languages used
- Asks: "What projects are you working on?"
- Asks: "What do you mainly do in this project?"
- Stores project context for smarter suggestions

### Writing Style Calibration  
- Analyzes samples of user's writing (commit messages, docs, emails)
- Extracts: tone (formal/casual), verbosity, preferred phrases
- Asks: "How do you refer to yourself? (I/we/the team)"
- Applies style to any text Nudge generates

### Personal Vocabulary
- Asks about team names, project codenames, acronyms
- Stores as lookup table
- Applied during intent classification

### Project Context Engine
- Asks: "What are your top priorities this quarter?"
- Asks: "What projects are you actively working on?"
- Updates suggestions and intent routing based on active projects

## Pricing Tiers

### Free ($0/forever)
- All core features
- User brings own API keys
- 6 LLM providers supported
- Full offline mode
- Self-managed Skills setup
- Community support (GitHub)
- Data stays on user's machine

### Pro ($9/month)
- Everything in Free
- Managed STT and LLM (no API keys needed)
- Usage dashboard (monthly STT minutes, LLM tokens)
- Managed Skills (auto-setup, cloud sync)
- Priority support (email)
- Nudge handles all provider management

### Team (Custom pricing)
- Everything in Pro
- Team management dashboard
- Shared knowledge base across team
- Admin controls and permissions
- SSO and audit logs
- Dedicated support

## API Endpoints (for Pro/Team managed tier)

```
POST /api/v1/transcribe       # STT
POST /api/v1/classify         # Intent classification
POST /api/v1/execute           # Agent execution
GET  /api/v1/tasks            # List tasks
GET  /api/v1/alarms           # List alarms
GET  /api/v1/knowledge        # Search knowledge
GET  /api/v1/history          # Voice command history
GET  /api/v1/usage            # Usage stats
POST /api/v1/soul/rules       # Add soul rule
GET  /api/v1/soul/rules       # List soul rules
POST /api/v1/skills/setup     # Start skill onboarding
GET  /api/v1/skills/status    # Skill completion status
```

## Integrations (Upcoming)

### Slack
- Bot that responds to voice notes in channels
- Slash command: `/nudge remind me to...`
- Voice note → transcript → action

### WhatsApp
- Voice messages → STT → action
- Reply with confirmation

### Calendar
- Voice-to-event creation
- "Schedule a meeting with Sarah tomorrow at 2pm"

### Email
- Voice-to-email draft
- "Email the team about the release"

## Storage

### Local (Free tier)
- SQLite database at `~/.nudge/nudge.db`
- Tables: tasks, alarms, knowledge, soul_rules, history, skills_data
- Full-text search on knowledge entries using FTS5

### Cloud (Pro/Team tier)  
- PostgreSQL on managed infrastructure
- Sync between local and cloud
- Encrypted at rest and in transit

## File Structure

```
nudge/
├── nudge/
│   ├── __init__.py
│   ├── cli.py                # CLI entry point
│   ├── config.py             # Config loading/saving
│   ├── pipeline.py           # Main pipeline orchestrator
│   ├── audio/
│   │   ├── capture.py        # Mic capture
│   │   └── vad.py            # Voice activity detection
│   ├── stt/
│   │   ├── base.py           # STTProvider interface
│   │   ├── groq.py
│   │   ├── openai.py
│   │   ├── ollama.py
│   │   ├── lmstudio.py
│   │   └── fireworks.py
│   ├── intent/
│   │   ├── classifier.py     # Intent classification
│   │   └── entities.py       # Entity extraction
│   ├── agents/
│   │   ├── base.py           # Agent interface
│   │   ├── task.py
│   │   ├── alarm.py
│   │   ├── knowledge.py
│   │   ├── clipboard.py
│   │   ├── search.py
│   │   ├── soul.py
│   │   ├── config.py
│   │   ├── list.py
│   │   ├── complete.py
│   │   └── delete.py
│   ├── llm/
│   │   ├── base.py           # LLMProvider interface
│   │   ├── groq.py
│   │   ├── openai.py
│   │   ├── anthropic.py
│   │   ├── ollama.py
│   │   ├── lmstudio.py
│   │   └── fireworks.py
│   ├── soul/
│   │   ├── system.py         # Soul rule engine
│   │   └── rules.py          # Rule storage
│   ├── skills/
│   │   ├── ide.py            # IDE integration
│   │   ├── writing.py        # Writing style
│   │   ├── vocabulary.py     # Personal vocab
│   │   └── context.py        # Project context
│   ├── storage/
│   │   ├── sqlite.py         # Local storage
│   │   └── cloud.py          # Cloud sync (Pro)
│   └── presets/
│       ├── fast.yaml
│       ├── default.yaml
│       └── offline.yaml
├── tests/
├── pyproject.toml
├── README.md
└── LICENSE (MIT)
```

## Installation

```bash
# From PyPI
pip install nudge-ai

# From source
git clone https://github.com/chiruu12/nudge-ai
cd nudge-ai
pip install -e .

# Run
nudge                    # Start with defaults
nudge preset fast        # Load a preset
nudge configure          # Interactive config
nudge --help             # CLI help
```

## Environment Variables

```bash
NUDGE_GROQ_API_KEY=...
NUDGE_OPENAI_API_KEY=...
NUDGE_ANTHROPIC_API_KEY=...
NUDGE_FIREWORKS_API_KEY=...
# Ollama and LM Studio don't need keys (local)
```

## Testing

```bash
pytest tests/                    # All tests
pytest tests/test_pipeline.py    # Pipeline tests
pytest tests/test_intents.py     # Intent classification
nudge test                       # Built-in self-test
```
