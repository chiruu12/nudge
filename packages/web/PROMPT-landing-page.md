# Nudge — Landing Page Design Prompt

## What is Nudge?
Nudge is an open-source, voice-first assistant. Users press a hotkey (cmd+shift+n), speak a command, and Nudge processes it through a pipeline: Voice → STT (speech-to-text) → Intent Classification → Agent Action. The whole pipeline runs sub-second (~740ms).

It supports 6 LLM providers (Groq, OpenAI, Anthropic, Ollama, LM Studio, Fireworks) and can run fully offline. Users can bring their own LLM (BYOLLM).

## Two Personas
The landing page serves two audiences with a **split-screen intro** that leads to completely different pages:

### Developers ("I build things")
- Install via `pip install nudge-ai`
- Care about: open source, self-hosting, extensibility, plugin architecture, YAML config, offline mode, sub-second latency, fork-friendly MIT license
- Tone: technical, no BS, CLI-first
- Visual language: dark (#0A0A0A), monospace text, terminal aesthetics, sharp corners, minimal decoration
- Reference sites: Linear, Vercel, Warp terminal — clean dark dev tool energy

### Team Leads / PMs ("I run things")
- Install via "Download for Mac" button
- Care about: saving time, not forgetting tasks, voice-first workflow, zero setup, learning their language
- Tone: warm, empathetic, benefit-focused
- Visual language: light (#FAFAFA), rounded corners, soft shadows, friendly typography
- Reference sites: Wispr Flow (wisprflow.ai), Notion, Todoist — warm and approachable SaaS energy

## The Split Screen Intro (Full Viewport)
The page loads with the entire viewport split **diagonally** into two halves:
- **Left (Dev)**: Pure black background with animated Matrix-style code rain (orange characters falling). Floating text fragments like "$ nudge", "→ 740ms", "BYOLLM"
- **Right (PM)**: Almost white background with animated flowing sine waves. Floating text fragments like "✓ task done", "3:00 PM — dentist"
- **Diagonal divider**: Steep angle (~68% top to ~34% bottom), glows burnt orange (#FF6B35) on hover
- **Hover**: hovering a side expands it (shifts the diagonal toward that side)
- **Click**: chosen side expands to fill viewport with transition (fast/instant for dev, cinematic scale+fade for PM)
- **Logo**: "● nudge" centered at top spanning the divider, gradient from white to dark
- **Prompt**: "Choose your side" below logo

## Design System
- **Fonts**: Cabinet Grotesk (headings), Instrument Sans (body), JetBrains Mono (code/terminal)
- **Accent**: Burnt orange #FF6B35
- **Dev palette**: bg #0A0A0A, cards #141414, borders #1E1E1E, text #EDEDED/#A3A3A3/#666
- **PM palette**: bg #FAFAFA, cards #fff, borders #E8EAF0, text #1A1A2E/#4A4A6A/#9CA3AF
- **Green**: #22C55E (success/checks)
- **Red**: #EF4444 (recording dot)

## Dev Page Sections (11 sections)
1. **Nav**: Sticky, dark, monospace feel. Links: Features, Skills, Pricing, GitHub ⭐. Switch to PM button.
2. **Hero**: "Hackable voice assistant for developers." + `pip install nudge-ai` copy button + Star on GitHub + terminal mockup showing a live Nudge session with pipeline trace (recording → STT → intent → agent → ✓ 740ms)
3. **Social proof strip**: "Works with any LLM provider" + provider logos (Groq, OpenAI, Anthropic, Ollama, LM Studio, Fireworks)
4. **Pipeline**: 3 cards (Voice 340ms, Intent 120ms, Action 280ms) with animated orange glow connectors and counting numbers
5. **Features**: 6 cards emphasizing hackability — Fork-Friendly, Plugin Architecture, YAML Config, Soul System, 6 Providers + BYOLLM, Full Offline Mode. Each card has a terminal command snippet.
6. **Skills**: 4 cards — IDE Knowledge Transfer (Cursor, Claude Code, Codex), Writing Style Calibration, Project Context Engine, Personal Vocabulary. Skills learn from your IDE, your writing style, your projects, your team names.
7. **Comparison table**: Nudge vs Siri vs Alexa vs Google. Nudge wins on: open source, self-hosted, sub-second, BYOLLM, custom intents, offline mode.
8. **Pricing**: 3 tiers:
   - Free ($0/forever): All core features, bring your own API keys, 6 providers, offline mode, self-setup Skills, community support
   - Pro ($9/mo, "Popular"): Everything in Free + managed STT & LLM, no API keys needed, usage dashboard, managed Skills, priority support
   - Team (Custom): Everything in Pro + team management, shared knowledge base, admin controls, SSO, dedicated support
   Heading: "Don't want to manage usage? Get a sub instead."
9. **Testimonials**: 3 developer quotes with @handles and companies
10. **FAQ**: Accordion — Is it free? What are Skills? Offline? Free vs Pro? Can I extend it?
11. **CTA**: "Ready to ship faster?" + pip install copy button + footer

## PM Page Sections (11 sections)
1. **Nav**: Sticky, light, clean. Links: Features, Skills, Pricing. Switch to Dev button.
2. **Hero**: "Your brain has better things to do." + Download for Mac button + app mockup (task list, alarms, voice button)
3. **Speed comparison**: "4× faster than typing" — Keyboard ~30s vs Nudge ~3s with animated progress bars
4. **Pipeline**: 4 clean cards (You speak → We listen → We understand → It's done) with orange connectors
5. **Features**: 6 benefit cards — Never forget a task, Alarms that understand you, Your second brain, Learns your language, Always one hotkey away, Zero setup. Voice command examples in accent color.
6. **Skills**: 4 cards — Writing Style, Personal Context, Communication Preferences, Project Knowledge. "The more Nudge knows about you, the less you need to explain."
7. **Integrations**: 4 cards (Slack, WhatsApp, Calendar, Email) — all "Coming soon" with a "Join the waitlist" CTA button
8. **Pricing**: Same 3 tiers as Dev but with PM-friendly framing: "Don't want to manage the tech?"
9. **Testimonials**: 3 team lead quotes with names and roles
10. **FAQ**: Accordion — Is it free? What are Skills? When are integrations coming? Privacy? Pro vs Team?
11. **CTA**: "Ready to think out loud?" + Download for Mac button + footer

## Technical Notes
- Single page React app, state-driven (no routing)
- Three states: 'split' | 'dev' | 'pm'
- Persona stored in localStorage (return visits skip split)
- Nav has a "switch" button to swap persona without returning to split
- Canvas-based animations for the split background
- Scroll-triggered reveal animations for all sections
- Interactive preset picker with terminal typing effect (dev)
- Tweaks panel for accent color, scan-line toggle, skip-intro, back-to-intro

## Anti-patterns to AVOID
- No purple gradients
- No generic icon grids with colored circles
- No stock photos or hand-drawn SVGs
- No system-ui fonts
- No gradient buttons
- No salesy language on the dev page
- No terminal frames around non-code content
- Don't make the site feel too simple or rigid — emphasize that it's flexible and extensible
- Don't make every section look the same — vary layouts, backgrounds, and visual rhythm
