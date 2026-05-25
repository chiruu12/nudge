# Design System — Nudge

## Product Context
- **What this is:** Voice assistant that gets things done. Press a hotkey, speak, done.
- **Who it's for:** Developers and knowledge workers who lose ideas because writing them down breaks flow
- **Space/industry:** Developer tools / voice productivity
- **Project type:** CLI tool + marketing website + dashboard
- **Memorable thing:** Freedom — "your voice, your tools, your rules"

## Aesthetic Direction
- **Direction:** Retro-Futuristic Terminal — dark, warm, alive. Like a terminal that breathes.
- **Decoration level:** Intentional — subtle waveform/audio visualizations as design elements, grain texture on dark backgrounds for warmth
- **Mood:** Empowering, open, alive. Not cold corporate minimalism, not playful consumer. The feeling of a well-loved dev environment that responds to your voice.
- **Reference sites:** Vercel (typography discipline), Warp (warmth + technical), Supabase (accent discipline), Neon (glow effects)

## Typography
- **Display/Hero:** Cabinet Grotesk — geometric with personality, distinctive at large sizes, free via Fontsource
- **Body:** Instrument Sans — clean, modern, excellent readability at body sizes
- **UI/Labels:** Instrument Sans (same as body)
- **Data/Tables:** JetBrains Mono — tabular-nums, the developer standard for monospace
- **Code:** JetBrains Mono
- **Loading:** Google Fonts or Fontsource (self-hosted for production)
- **Scale:**
  - xs: 12px / 0.75rem
  - sm: 14px / 0.875rem
  - base: 16px / 1rem
  - lg: 18px / 1.125rem
  - xl: 20px / 1.25rem
  - 2xl: 24px / 1.5rem
  - 3xl: 30px / 1.875rem
  - 4xl: 36px / 2.25rem
  - 5xl: 48px / 3rem
  - 6xl: 60px / 3.75rem
  - hero: 72px / 4.5rem

## Color
- **Approach:** Restrained — one bold accent, everything else is neutral
- **Background:** #0A0A0A (near-black, warm)
- **Surface:** #141414 (elevated cards, modals)
- **Surface elevated:** #1A1A1A (hover states, active cards)
- **Border:** #262626 (subtle structure)
- **Border strong:** #404040 (emphasized borders)
- **Text primary:** #EDEDED
- **Text secondary:** #A3A3A3
- **Text muted:** #737373
- **Accent:** #FF6B35 (burnt orange — warm, energetic, freedom)
- **Accent hover:** #FF8255
- **Accent muted:** rgba(255, 107, 53, 0.15)
- **Semantic:**
  - Success: #22C55E
  - Warning: #EAB308
  - Error: #EF4444
  - Info: #3B82F6
- **Dark mode:** This IS the dark mode. Light mode is not planned.

## Spacing
- **Base unit:** 4px
- **Density:** Comfortable
- **Scale:**
  - 2xs: 2px
  - xs: 4px
  - sm: 8px
  - md: 16px
  - lg: 24px
  - xl: 32px
  - 2xl: 48px
  - 3xl: 64px
  - 4xl: 96px

## Layout
- **Approach:** Hybrid — grid-disciplined for dashboard, creative-editorial for landing page
- **Grid:** 12 columns (desktop), 6 (tablet), 4 (mobile)
- **Max content width:** 1200px
- **Border radius:**
  - sm: 4px (inputs, small elements)
  - md: 8px (cards, buttons)
  - lg: 12px (modals, large containers)
  - full: 9999px (pills, badges)

## Motion
- **Approach:** Intentional — motion that communicates voice/audio states
- **Easing:** enter(ease-out) exit(ease-in) move(ease-in-out)
- **Duration:** micro(50-100ms) short(150-250ms) medium(250-400ms) long(400-700ms)
- **Signature animations:**
  - Listening pulse: breathing scale animation on the record indicator
  - Pipeline flow: left-to-right reveal for STT → Intent → Agent stages
  - Waveform idle: subtle ambient wave in hero section background

## Voice-Specific Design Elements
- **Waveform visualization:** Subtle audio waveform patterns as background elements (hero section, loading states)
- **Pipeline trace:** Glowing left-to-right trace showing STT → Intent → Agent flow with timing
- **Recording indicator:** Pulsing burnt-orange dot with breathing animation
- **Status colors:** Recording (#EF4444 red), Processing (#FF6B35 orange), Done (#22C55E green)

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-05-25 | Initial design system | Created by /design-consultation. Retro-futuristic terminal aesthetic with burnt orange accent. Research: Vercel, Warp, Supabase, Neon. Memorable thing: freedom. |
| 2026-05-25 | Burnt orange accent (#FF6B35) | Stands out from tech-blue/purple convention. Evokes warmth, energy, freedom. Category-breaking for developer tools. |
| 2026-05-25 | Cabinet Grotesk + Instrument Sans | Distinctive display font (not overused Inter/Geist). Clean body font with excellent readability. Both free. |
| 2026-05-25 | No light mode | Voice tool used in terminal context. Dark is native. Light mode is unnecessary scope. |
