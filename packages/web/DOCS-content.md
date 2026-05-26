# Nudge - Content Guide

## Brand Voice

### For Developers
- **Tone**: Direct, technical, no BS
- **Style**: Short sentences. Code speaks louder than words.
- **Pronouns**: "you" and "your" (never "we" for the product)
- **Avoid**: Marketing speak, buzzwords, exclamation marks, em dashes

**Examples:**
- Good: "Fork it. Extend it. Ship your own version."
- Bad: "We've built an amazing platform that empowers developers!"

### For Team Leads / PMs
- **Tone**: Warm, empathetic, benefit-focused
- **Style**: Conversational. Focus on outcomes, not features.
- **Pronouns**: "you" and "your"
- **Avoid**: Technical jargon, code references, em dashes

**Examples:**
- Good: "Your brain has better things to do."
- Bad: "Leveraging AI-powered NLP for task management!"

## Headlines

### Split Screen
- Dev: "BUILD THINGS."
- PM: "RUN THINGS."
- Center: "Choose Your Side"

### Dev Page
- Hero: "Hackable voice assistant for developers."
- Pipeline: "Sub-second pipeline"
- Features: "Built to be extended"
- Skills: "Nudge Skills"
- Compare: "Why Nudge"
- Pricing: "Don't want to manage usage?"
- Testimonials: "Developers love it"
- FAQ: "FAQ"
- CTA: "Ready to ship faster?"

### PM Page
- Hero: "Your brain has better things to do."
- Speed: "4x faster than typing"
- Pipeline: "How it works"
- Features: "What you get"
- Skills: "Nudge Skills"
- Integrations: "Integrations"
- Pricing: "Don't want to manage the tech?"
- Testimonials: "Loved by teams"
- FAQ: "Questions?"
- CTA: "Ready to think out loud?"

## Taglines by Persona

### Dev
- "Open Source. Offline. Sub-Second."
- "Your voice, your tools, your rules."
- "Not a product. A platform."

### PM
- "Intuitive. Productive. Voice-First."
- "Speak it. It's done."
- "4x faster than typing."

## Feature Copy

### Tasks & Alarms
- Dev: `nudge task "deploy by Friday"` / `nudge alarm "2h"`
- PM: "Never forget a task. Speak and it's captured."

### Knowledge Base
- Dev: `nudge save "API needs OAuth2"`
- PM: "Your second brain. Save anything by voice."

### Soul System
- Dev: `nudge soul add "later=evening"` — teach Nudge YOUR language
- PM: "Learns your language. 'High priority' means what YOU mean."

### Skills
- Dev: "Connect to Cursor, Claude Code, or Codex. Nudge learns your codebase."
- PM: "The more Nudge knows about you, the less you explain."

### Providers
- Dev: "6 providers + BYOLLM. Groq, OpenAI, Anthropic, Ollama, LM Studio, Fireworks."
- PM: "Works out of the box. Free AI providers included."

### Offline Mode
- Dev: `nudge preset offline` — "Air-gapped? No problem."
- PM: "Everything runs locally. Your data stays on your machine."

## Pricing Copy

### Free Tier
- Dev: "Self-managed. Full power. $0 forever."
- PM: "Get started, no strings attached."

### Pro Tier ($9/mo)
- Dev: "We handle the infra. You ship."
- PM: "We handle the tech. You focus."

### Team Tier (Custom)
- Dev: "For teams that ship together."
- PM: "For teams that move together."

## Social Proof / Stats
- Pipeline latency: 740ms total (STT 340ms + Intent 120ms + Agent 280ms)
- Providers: 6 supported
- License: MIT
- GitHub stars: 12.4k (placeholder)
- Speed comparison: Voice 3s vs Typing 30s = 4x faster

## Testimonials (Placeholder)

### Dev Testimonials
1. "Sub-second latency changed everything. Voice is now part of my dev flow."
   — @karthik_dev, ML Engineer, Stealth AI

2. "Fork-friendly architecture. I extended the pipeline with a custom agent in an afternoon."
   — @maya_codes, Full-Stack, YC S24

3. "Running fully offline with Ollama. Open source that actually respects privacy."
   — @privacy_eng, Security Eng, Cloudflare

### PM Testimonials
1. "I used to lose half my action items by the end of the day. Now I just speak them."
   — Sarah M., Product Lead

2. "My team thought I had a secret assistant. I do. It's Nudge."
   — James K., Eng Manager

3. "Zero learning curve. Installed it Monday, my whole team was using it by Wednesday."
   — Maria L., Director of Ops

## FAQ Content

### Dev FAQ
1. **Is it really free?** Yes. MIT licensed, free forever. Pro is for managed infrastructure.
2. **What are Skills?** Skills sync context from your IDE. They learn your projects, writing style, and vocabulary.
3. **Can I run it fully offline?** Yes. Use the offline preset with Ollama. Zero network dependency.
4. **Free vs Pro?** Free: bring your own API keys. Pro: we handle STT, LLM, and give you a usage dashboard.
5. **Can I extend it?** Absolutely. Custom intents, custom agents, plugin architecture.

### PM FAQ
1. **Is it really free to start?** Yes. All core features included. Pro for managed infrastructure.
2. **What are Skills?** Skills learn your writing style, vocabulary, team context, and projects.
3. **When are Slack and WhatsApp coming?** In development. Join the waitlist.
4. **Is my data private?** Yes. Free tier runs everything locally. Pro uses secure managed infrastructure.
5. **Pro vs Team?** Team adds shared knowledge bases, admin controls, and dedicated support.

## Footer
- "open source · MIT licensed · built with ❤ by chiruu12"
- Links: GitHub, LinkedIn

## File Map (Current)

```
Nudge Landing v3.html    — Main landing page (split + dev/PM pages)
split-v3.jsx             — Split intro with crossing tickers + download popover
dev-page-v3.jsx          — Developer page (11 sections)
pm-page-v3.jsx           — PM page (11 sections)
app-v3.jsx               — App shell (state management, tweaks)
tweaks-panel.jsx         — Tweaks panel component
Nudge App Mockups.html   — App dashboard mockups
app-mockups.jsx          — Dashboard mockup components
design-canvas.jsx        — Design canvas framework
macos-window.jsx         — macOS window component
PROMPT-landing-page.md   — Handoff prompt for landing page redesign
PROMPT-macos-app.md      — Handoff prompt for SwiftUI macOS app
DOCS-backend.md          — Backend implementation guide
DOCS-content.md          — This file
```
