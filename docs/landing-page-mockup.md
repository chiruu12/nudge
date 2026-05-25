# Landing Page Mockup — Nudge

Use this as a prompt for Claude/design tools to generate the actual page.
All values reference DESIGN.md.

---

## Section 1: Hero (Full viewport, dark background #0A0A0A)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  [subtle waveform visualization in background, #FF6B35 at 5%]   │
│                                                                 │
│  ╔═══════════════════════════════════════════════════════════╗   │
│  ║                                                           ║   │
│  ║      Your voice, your tools, your rules.                  ║   │
│  ║      ─────────────────────────────────                    ║   │
│  ║      [Cabinet Grotesk, 72px, #EDEDED]                     ║   │
│  ║                                                           ║   │
│  ║      Voice assistant that actually gets things done.       ║   │
│  ║      Press a hotkey, speak, done.                         ║   │
│  ║      [Instrument Sans, 20px, #A3A3A3]                     ║   │
│  ║                                                           ║   │
│  ║      ┌──────────────────┐  ┌──────────────────┐           ║   │
│  ║      │  pip install nudge│  │  ⭐ Star on GitHub│           ║   │
│  ║      │  [#FF6B35 bg]    │  │  [border #262626] │           ║   │
│  ║      └──────────────────┘  └──────────────────┘           ║   │
│  ║                                                           ║   │
│  ╚═══════════════════════════════════════════════════════════╝   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  $ nudge                                                │    │
│  │  Nudge v0.1.0                                           │    │
│  │    Hotkey:  cmd+shift+n                                  │    │
│  │    STT:     groq                                         │    │
│  │    LLM:     groq (standard)                              │    │
│  │                                                          │    │
│  │  ● Recording... (1.2s)                                   │    │
│  │  → STT: "remind me to call mom" (Groq Whisper, 340ms)   │    │
│  │  → Intent: alarm (92%) (120ms)                           │    │
│  │  → Agent: set_alarm("Call mom", 24h) (280ms)             │    │
│  │  ✓ Total: 740ms                                          │    │
│  │                                                          │    │
│  │  [#141414 bg, JetBrains Mono, terminal mockup]           │    │
│  │  [● red, → orange, ✓ green colored indicators]           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 2: Pipeline Visualization (dark bg, centered)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   How it works                                                  │
│   [Cabinet Grotesk, 36px, #EDEDED]                              │
│                                                                 │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌─────────┐  │
│   │  🎤 You   │ →  │  STT     │ →  │  Intent  │ →  │  Agent  │  │
│   │  speak    │    │  340ms   │    │  120ms   │    │  280ms  │  │
│   │          │    │  Whisper  │    │  classify │    │  action │  │
│   └──────────┘    └──────────┘    └──────────┘    └─────────┘  │
│                                                                 │
│   [#141414 cards, #262626 borders, → arrows in #FF6B35]        │
│   [Animated left-to-right glow trace connecting the stages]    │
│                                                                 │
│   Sub-second. Every time.                                       │
│   [Instrument Sans, 18px, #A3A3A3]                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 3: Features (3x2 grid on dark bg)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   What Nudge does                                               │
│   [Cabinet Grotesk, 36px, #EDEDED]                              │
│                                                                 │
│   ┌───────────────────┐  ┌───────────────────┐  ┌────────────┐ │
│   │ Tasks & Alarms    │  │ Knowledge Base    │  │ Clipboard  │ │
│   │                   │  │                   │  │ & Links    │ │
│   │ "Add a task to    │  │ "Save this: the   │  │ "Copy that │ │
│   │  deploy by Friday"│  │  API uses OAuth"  │  │  error msg"│ │
│   │                   │  │                   │  │            │ │
│   │ Create todos and  │  │ Semantic search   │  │ Voice-to-  │ │
│   │ reminders with    │  │ over everything   │  │ clipboard  │ │
│   │ your voice.       │  │ you've saved.     │  │ instantly. │ │
│   └───────────────────┘  └───────────────────┘  └────────────┘ │
│                                                                 │
│   ┌───────────────────┐  ┌───────────────────┐  ┌────────────┐ │
│   │ Soul System       │  │ Provider Freedom  │  │ Presets    │ │
│   │                   │  │                   │  │            │ │
│   │ "Later means      │  │ Groq, OpenAI,     │  │ nudge      │ │
│   │  this evening"    │  │ Anthropic, Ollama, │  │  preset    │ │
│   │                   │  │ LM Studio         │  │  fast      │ │
│   │ Nudge learns how  │  │                   │  │            │ │
│   │ YOU work via      │  │ Bring your own    │  │ One command │ │
│   │ soul.md           │  │ LLM. No lock-in.  │  │ to switch. │ │
│   └───────────────────┘  └───────────────────┘  └────────────┘ │
│                                                                 │
│   [#141414 cards, 8px radius, #262626 border]                  │
│   [Feature name in #EDEDED, example in #FF6B35 monospace]      │
│   [Description in #A3A3A3]                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 4: Presets Comparison (centered table)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Pick your style                                               │
│   [Cabinet Grotesk, 36px, #EDEDED]                              │
│                                                                 │
│   ┌─────────────┬─────────────┬─────────────┐                  │
│   │  ⚡ Fast     │  ⚙ Default  │  🔒 Offline │                  │
│   │             │             │             │                  │
│   │  Groq free  │  Groq std   │  Ollama     │                  │
│   │  ~200ms     │  ~500ms     │  ~2s        │                  │
│   │  $0/month   │  $0/month   │  $0/month   │                  │
│   │             │             │             │                  │
│   │  Best for:  │  Best for:  │  Best for:  │                  │
│   │  Speed      │  Balance    │  Privacy    │                  │
│   └─────────────┴─────────────┴─────────────┘                  │
│                                                                 │
│   [#141414 cards, #FF6B35 highlight on selected]               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 5: Install CTA (centered, dramatic)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   [waveform visualization, subtle #FF6B35 glow]                │
│                                                                 │
│                  Ready to ship faster?                           │
│                  [Cabinet Grotesk, 48px]                         │
│                                                                 │
│   ┌─────────────────────────────────────────┐                   │
│   │  $ pip install nudge                     │                   │
│   │  [click to copy, #141414 bg, monospace]  │                   │
│   └─────────────────────────────────────────┘                   │
│                                                                 │
│   Open source · MIT licensed · Built on Hive                    │
│   [Instrument Sans, 14px, #737373]                              │
│                                                                 │
│   [GitHub icon] [Twitter/X icon]                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 6: Footer (minimal)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Nudge                    Docs  GitHub  Pricing                │
│   © 2026 chiruu12          [#737373 links]                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Design Prompt (for Claude/AI design tools)

Use this prompt to generate the actual landing page design:

> Design a dark-themed landing page for "Nudge" — a voice assistant for developers.
>
> **Brand:** "Your voice, your tools, your rules." Freedom-focused, empowering.
>
> **Palette:** Background #0A0A0A, cards #141414, borders #262626, text #EDEDED/#A3A3A3, accent burnt orange #FF6B35.
>
> **Fonts:** Cabinet Grotesk (headings), Instrument Sans (body), JetBrains Mono (code/terminal).
>
> **Key elements:**
> - Hero with large tagline + terminal mockup showing voice pipeline (Recording → STT → Intent → Agent with ms timings)
> - Subtle waveform/audio visualization in hero background
> - Pipeline visualization section (4 stages with glowing orange connectors)
> - 6-card feature grid (Tasks, Knowledge, Clipboard, Soul, Providers, Presets)
> - Preset comparison (Fast/Default/Offline)
> - Install CTA with `pip install nudge` code block
>
> **Feel:** Like Vercel's typography discipline meets Warp's warmth. Not cold, not playful. Alive, breathing, developer-grade. The burnt orange accent should feel like fire/energy against the dark background.
>
> **Anti-patterns to avoid:** Purple gradients, 3-column icon grids with colored circles, centered-everything, gradient buttons, stock photos, system-ui fonts.
