# Landing Page Mockup — Nudge

Use this as a prompt for Claude/design tools to generate the actual page.
All values reference DESIGN.md.

---

## Section 0: The Split Screen Intro (FULL VIEWPORT — the wow moment)

The page loads with the entire viewport split vertically into two halves.
No scroll. No nav bar yet. Just two worlds, side by side.

When you hover a side, it expands slightly (55/45 ratio) with a smooth animation.
The divider line glows burnt orange (#FF6B35) on hover.
Click a side → the chosen half expands to fill the screen with a cinematic transition,
the other half slides away, and the full page for that persona loads below.

```
┌────────────────────────────┬────────────────────────────────┐
│                            │                                │
│                            │                                │
│   ░░░ terminal cursor ░░░  │     ┌─────────────────────┐    │
│                            │     │  ☑ Morning standup   │    │
│   $ nudge                  │     │  ☐ Review the PR     │    │
│   ● Recording...           │     │  ☐ Email design team │    │
│   → STT: "fix the bug"    │     └─────────────────────┘    │
│   → Intent: task (94%)     │                                │
│   ✓ 580ms                  │     🎤 "remind me to call     │
│                            │         the dentist at 3pm"   │
│                            │                                │
│   ──────────────────────   │     ──────────────────────     │
│                            │                                │
│   [ I build things ]       │     [ I run things ]           │
│                            │                                │
│   ⌨ Developer              │     📋 Team Lead               │
│                            │                                │
│   #0A0A0A bg               │     #0F1219 bg                 │
│   JetBrains Mono text      │     Instrument Sans text       │
│   Terminal grain texture   │     Clean, polished surface    │
│                            │                                │
│            ▼               │              ▼                 │
│    click to enter          │      click to enter            │
│                            │                                │
└────────────────────────────┴────────────────────────────────┘
                             │
                    divider glows #FF6B35
                    on hover of either side
```

**Visual details for the split:**
- Left half (Developer): Pure dark (#0A0A0A), subtle terminal scan-line effect, monospace text, blinking cursor, faint green/orange terminal glow. A live-feeling terminal showing a Nudge session mid-flow.
- Right half (Team Lead): Slightly lighter dark (#0F1219), clean card-based UI fragments floating — a task list, an alarm card, a voice button with a waveform. Feels like peeking into the app.
- Center divider: 2px line, faint #262626 default, glows #FF6B35 when either side is hovered.
- The Nudge logo sits centered at the very top, spanning the divider. Small, subtle.
- Below each mockup: a label — "I build things" / "I run things" — and persona name.
- No other text. No tagline yet. The split IS the hook.

**Hover interaction:**
- Hover left → left expands to 55%, right shrinks to 45%, left side brightens slightly
- Hover right → right expands to 55%, left shrinks to 45%, right side brightens
- Smooth CSS transition: `width 0.4s cubic-bezier(0.4, 0, 0.2, 1)`

**Click transition:**
- Clicked side expands to 100% width over 0.6s
- Other side slides out and fades
- Content below fades in as the hero settles
- Nav bar appears at top
- Feels cinematic, like choosing a path

---

## Section 1: Hero (appears after split selection)

### IF DEVELOPER:

```
┌─────────────────────────────────────────────────────────────────┐
│  [nav: Nudge logo | Features | Docs | GitHub ⭐ | switch: PM] │
│                                                                 │
│  [subtle waveform bg, #FF6B35 at 5% opacity]                  │
│                                                                 │
│     Your voice, your tools, your rules.                         │
│     [Cabinet Grotesk, 64px, #EDEDED]                            │
│                                                                 │
│     Open source voice assistant. BYOLLM. Sub-second.            │
│     [Instrument Sans, 20px, #A3A3A3]                            │
│                                                                 │
│     ┌──────────────────────┐  ┌─────────────────┐              │
│     │ $ pip install nudge-ai  │  │ ⭐ Star on GitHub│              │
│     │ [#FF6B35, copy btn]  │  │ [border #262626] │              │
│     └──────────────────────┘  └─────────────────┘              │
│                                                                 │
│     ┌──────────────────────────────────────────────────────┐    │
│     │  $ nudge                                             │    │
│     │  Nudge v0.1.0                                        │    │
│     │    Hotkey:  cmd+shift+n                               │    │
│     │    STT:     groq  |  LLM: groq (standard)            │    │
│     │                                                      │    │
│     │  ● Recording... (1.2s)                                │    │
│     │  → STT: "remind me to push the fix" (Groq, 340ms)   │    │
│     │  → Intent: alarm (92%) (120ms)                       │    │
│     │  → Agent: set_alarm("Push fix", 2h) (280ms)          │    │
│     │  ✓ Total: 740ms                                       │    │
│     │                                                      │    │
│     │  [#0A0A0A bg, JetBrains Mono, glowing pipeline]      │    │
│     │  [● red dot, → burnt orange arrows, ✓ green check]   │    │
│     └──────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### IF TEAM LEAD:

```
┌─────────────────────────────────────────────────────────────────┐
│  [nav: Nudge logo | Features | How it works | switch: Dev ⌨]  │
│                                                                 │
│  [subtle waveform bg, softer]                                  │
│                                                                 │
│     Speak it. It's done.                                        │
│     [Cabinet Grotesk, 64px, #EDEDED]                            │
│                                                                 │
│     Voice-first task management that learns how you work.       │
│     [Instrument Sans, 20px, #A3A3A3]                            │
│                                                                 │
│     ┌──────────────────────┐  ┌─────────────────┐              │
│     │  Download for Mac    │  │  See it in action│              │
│     │  [#FF6B35 bg]        │  │  [border #262626]│              │
│     └──────────────────────┘  └─────────────────┘              │
│                                                                 │
│     ┌──────────────────────────────────────────────────────┐    │
│     │                                                      │    │
│     │  ┌─ tasks ──────┐ ┌─ alarms ─────┐  ┌──────────┐   │    │
│     │  │ ☑ Standup    │ │ 3:00 PM      │  │  🎤      │   │    │
│     │  │ ☐ Review PR  │ │ Call dentist  │  │ press to │   │    │
│     │  │ ☐ Email team │ │ 5:30 PM      │  │  speak   │   │    │
│     │  │ ☐ Fix bug    │ │ Team sync    │  │          │   │    │
│     │  └──────────────┘ └──────────────┘  └──────────┘   │    │
│     │                                                      │    │
│     │  "remind me to call the dentist at 3pm"              │    │
│     │                                                      │    │
│     │  recent: alarm set · task created · note saved       │    │
│     │                                                      │    │
│     │  [#0F1219 bg, Instrument Sans, app mockup]           │    │
│     └──────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Nav bar detail:**
- Both versions have a small "switch" link in the nav to swap persona without going back to the split
- Dev nav: `switch: PM →` in the top right
- PM nav: `switch: Dev ⌨` in the top right
- Clicking it smoothly transitions hero content (crossfade, 0.3s)

---

## Section 2: Pipeline Visualization (SHARED — both personas see this)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   How Nudge works                                               │
│   [Cabinet Grotesk, 36px]                                       │
│                                                                 │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌─────────┐  │
│   │  🎤       │    │  📝       │    │  🧠       │    │  ✅      │  │
│   │  You      │ →  │  STT     │ →  │  Intent  │ →  │  Agent  │  │
│   │  speak    │    │  340ms   │    │  120ms   │    │  280ms  │  │
│   └──────────┘    └──────────┘    └──────────┘    └─────────┘  │
│                                                                 │
│   [cards: #141414, borders: #262626]                           │
│   [→ connectors: animated glow trail in #FF6B35]               │
│   [Numbers count up on scroll-into-view]                       │
│                                                                 │
│   Voice in, action out. Under a second.                         │
│   [Instrument Sans, 18px, #A3A3A3]                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 3: Features (SHARED — copy adjusts slightly per persona)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   What you get                                                  │
│   [Cabinet Grotesk, 36px]                                       │
│                                                                 │
│   ┌────────────────────┐  ┌────────────────────┐  ┌──────────┐ │
│   │ Tasks & Alarms     │  │ Knowledge Base     │  │ Clipboard│ │
│   │                    │  │                    │  │ & Links  │ │
│   │ DEV: "add task to  │  │ DEV: "save: API    │  │ "copy    │ │
│   │  deploy by Friday" │  │  needs OAuth2"     │  │  that    │ │
│   │ PM: "remind me to  │  │ PM: "save: budget  │  │  error"  │ │
│   │  prep for standup" │  │  approved by CFO"  │  │          │ │
│   └────────────────────┘  └────────────────────┘  └──────────┘ │
│                                                                 │
│   ┌────────────────────┐  ┌────────────────────┐  ┌──────────┐ │
│   │ Soul System        │  │ 6 Providers        │  │ Presets  │ │
│   │                    │  │                    │  │          │ │
│   │ DEV: "later means  │  │ Groq · OpenAI ·   │  │ fast ·   │ │
│   │  this evening"     │  │ Anthropic · Ollama │  │ default ·│ │
│   │ PM: "high priority │  │ LM Studio ·       │  │ offline  │ │
│   │  = before EOD"     │  │ Fireworks          │  │          │ │
│   └────────────────────┘  └────────────────────┘  └──────────┘ │
│                                                                 │
│   [#141414 cards, 8px radius, #262626 border]                  │
│   [Feature name: #EDEDED, voice example: #FF6B35 mono]         │
│   [Description: #A3A3A3]                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 4: Presets (SHARED)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Pick your speed                                               │
│   [Cabinet Grotesk, 36px]                                       │
│                                                                 │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│   │  ⚡ Fast      │  │  ⚙ Default   │  │  🔒 Offline  │         │
│   │              │  │              │  │              │         │
│   │  Groq free   │  │  Groq std    │  │  Ollama      │         │
│   │  ~200ms      │  │  ~500ms      │  │  ~2s         │         │
│   │  $0          │  │  $0          │  │  $0          │         │
│   │              │  │              │  │              │         │
│   │  "I want     │  │  "I want     │  │  "I want     │         │
│   │   speed"     │  │   balance"   │  │   privacy"   │         │
│   │              │  │              │  │              │         │
│   │  [selected   │  │              │  │              │         │
│   │   glow]      │  │              │  │              │         │
│   └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                 │
│   [Interactive: click a card, it glows #FF6B35 border]         │
│   [Shows the corresponding nudge preset command below]         │
│                                                                 │
│   $ nudge preset fast                                           │
│   ✓ Loaded preset fast → ~/.nudge/config.yaml                  │
│   [JetBrains Mono, animated typing effect]                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 5: Final CTA (SHARED — CTA text differs per persona)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   [waveform visualization, burnt orange glow]                  │
│                                                                 │
│   DEV:  Ready to ship faster?                                   │
│   PM:   Ready to think out loud?                                │
│   [Cabinet Grotesk, 48px]                                       │
│                                                                 │
│   DEV:                                                          │
│   ┌──────────────────────────────────┐                          │
│   │  $ pip install nudge-ai             │  [click to copy]        │
│   └──────────────────────────────────┘                          │
│                                                                 │
│   PM:                                                           │
│   ┌──────────────────────────────────┐                          │
│   │  Download for Mac                │  [#FF6B35 button]       │
│   └──────────────────────────────────┘                          │
│                                                                 │
│   Open source · MIT licensed · Built with ❤ by chiruu12         │
│   [GitHub icon] [LinkedIn icon]                                 │
│   [Instrument Sans, 14px, #737373]                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Interaction Summary

```
Page load
  ↓
Split Screen (full viewport, no scroll)
  ├── Hover left (Developer) → left expands 55/45, glow
  ├── Hover right (Team Lead) → right expands 55/45, glow
  └── Click either side
        ↓
  Cinematic transition (0.6s)
  Chosen side fills viewport
  Nav bar appears with "switch" link
        ↓
  Hero (persona-specific content)
        ↓
  Pipeline visualization (shared)
        ↓
  Features grid (shared, examples adjust per persona)
        ↓
  Presets comparison (shared)
        ↓
  Final CTA (persona-specific text)
        ↓
  Footer (shared)
```

---

## Technical Implementation Notes

```
React state:
  const [persona, setPersona] = useState<'split' | 'dev' | 'pm'>('split')

Three render states:
  'split'  → SplitIntro component (full viewport)
  'dev'    → Full page with dev hero + shared sections
  'pm'     → Full page with PM hero + shared sections

The switch link in nav: setPersona(persona === 'dev' ? 'pm' : 'dev')

CSS transitions:
  Split hover: width transition 0.4s ease
  Split → page: opacity + transform transition 0.6s
  Persona swap: crossfade 0.3s

No routing needed. Single page, state-driven.
Persona stored in localStorage so return visits skip the split.
```

---

## Design Prompt (for Claude/AI design tools)

> Design a dark-themed landing page for "Nudge" — a voice assistant for developers and team leads.
>
> **The hook:** Page loads with a full-viewport vertical split screen. Left half is pure terminal aesthetic (dark #0A0A0A, monospace text, blinking cursor, a Nudge CLI session mid-flow). Right half is a clean app UI (slightly lighter #0F1219, floating task cards, alarm widgets, a voice button). A 2px divider between them glows burnt orange (#FF6B35) on hover. Each side has a label: "I build things" (Developer) and "I run things" (Team Lead). Hovering a side makes it expand slightly (55/45). Clicking a side triggers a cinematic transition where it fills the full viewport and loads that persona's content.
>
> **Palette:** Background #0A0A0A (dev) / #0F1219 (PM), cards #141414, borders #262626, text #EDEDED/#A3A3A3, accent burnt orange #FF6B35.
>
> **Fonts:** Cabinet Grotesk (headings), Instrument Sans (body), JetBrains Mono (code/terminal).
>
> **After selection — Developer version:**
> - Hero: "Your voice, your tools, your rules." + terminal mockup with pipeline trace
> - CTA: `pip install nudge-ai` copy button + Star on GitHub
>
> **After selection — Team Lead version:**
> - Hero: "Speak it. It's done." + app GUI mockup (task list, alarms, voice button)
> - CTA: "Download for Mac" button
>
> **Shared sections below hero:**
> - Pipeline visualization (4 stages with animated orange glow connectors)
> - Features grid (6 cards with voice command examples)
> - Presets comparison (Fast/Default/Offline, interactive)
> - Final CTA with waveform background
>
> **Feel:** The split screen should feel like choosing between two worlds. Left side has terminal grain texture, scan-line effect, hacker energy. Right side is clean, polished, professional. The divider glowing orange is the moment of delight. After choosing, the page feels cohesive and premium — Vercel's typography discipline meets Warp's warmth.
>
> **Anti-patterns:** No purple gradients, no 3-column icon grids with colored circles, no stock photos, no system-ui fonts, no gradient buttons.
