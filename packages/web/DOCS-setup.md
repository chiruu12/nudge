# Nudge Landing Page — Setup & Integration Guide

This document explains how to plug in real links, configure the landing page for production, and customize content.

## File Structure

```
Nudge Landing v3.html   — Main entry point (load this)
split-v3.jsx             — Split intro screen + download popover
dev-page-v3.jsx          — Developer page (11 sections)
pm-page-v3.jsx           — PM/Team Lead page (11 sections)
app-v3.jsx               — App shell, state management, tweaks
tweaks-panel.jsx         — Tweaks panel component (starter)
```

## Quick Start

1. Open `Nudge Landing v3.html` in a browser
2. The split intro loads by default
3. Click a side to enter that persona's page
4. Persona choice is saved in `localStorage` (key: `nudge-persona`)

---

## Links to Plug In

### Navigation Links

**Dev page nav** (`dev-page-v3.jsx`):
- `Features` → scrolls to `#d-features` (already wired)
- `Skills` → scrolls to `#d-skills` (already wired)
- `Pricing` → scrolls to `#d-pricing` (already wired)
- `GitHub ⭐` → replace `https://github.com` with your actual repo URL

Search for `href="https://github.com"` in `dev-page-v3.jsx` and replace all instances.

**PM page nav** (`pm-page-v3.jsx`):
- `Features` → `#p-feat` (wired)
- `Skills` → `#p-skills` (wired)  
- `Pricing` → `#p-price` (wired)

### CTA Buttons

**Dev page:**
- `pip install nudge-ai` copy button — already copies text to clipboard, no link needed
- `⭐ Star on GitHub` — replace `https://github.com` with repo URL

**PM page:**
- `Download for Mac` — opens the download popover (architecture picker)
- `See it in action` — add your demo video URL or scroll target
- `Join the waitlist` (integrations section) — wire to your waitlist form/endpoint

### Download Popover (`split-v3.jsx`)

The popover shows Apple Silicon and Intel options. To add real download links:

Search for the `DownloadPopover` component and add `onClick` handlers to the buttons:

```jsx
// Apple Silicon button — add:
onClick={() => window.open('https://your-domain.com/downloads/nudge-arm64.dmg')}

// Intel button — add:
onClick={() => window.open('https://your-domain.com/downloads/nudge-x64.dmg')}
```

### Footer Links

Both pages have GitHub and LinkedIn icons in the footer/CTA section:
- GitHub: replace `https://github.com` with repo URL
- LinkedIn: replace `https://linkedin.com` with profile URL

Search for `href="https://linkedin.com"` and `href="https://github.com"` in both page files.

### Persona Switch

The `[pm →]` and `Dev ⌨` buttons in the nav already work. They switch personas via React state.

---

## Content to Customize

### GitHub Stars Count

In `split-v3.jsx`, the split screen shows `★ 12.4k` — update this:
```
Search: ★ 12.4k
Replace with your actual star count
```

### Version Number

In the download popover (`split-v3.jsx`):
```
Search: v0.1.0
Replace with current version
```

### Testimonials

**Dev testimonials** (`dev-page-v3.jsx`):
Replace the placeholder quotes, handles, roles, and companies in the `quotes` array inside `DevTestimonials`.

**PM testimonials** (`pm-page-v3.jsx`):
Replace the placeholder quotes in `PMTestimonials`.

### Pricing

Both pages have 3 tiers defined in their `Pricing` components:
- Free: $0/forever
- Pro: $9/mo
- Team: Custom

Update the `tiers` array in each file to change prices, features, or CTA text.

### FAQ

Update the `faqs` array in `DevFAQ` and `PMFAQ` components.

### Provider List

The dev social proof strip lists: Groq, OpenAI, Anthropic, Ollama, LM Studio, Fireworks. Update in `DevSocial` component.

---

## Integrations Section (PM page)

The PM page has an Integrations section with Slack, WhatsApp, Calendar, Email — all marked "Coming soon". 

To update status:
1. Open `pm-page-v3.jsx`
2. Find the `PMIntegrations` component
3. Change `status: 'Coming soon'` to `'Live'` or `'Beta'` as needed
4. Update the waitlist button text/link

---

## Styling & Theming

### Accent Color

Default: `#FF6B35` (burnt orange). Can be changed via the Tweaks panel (toggle in toolbar) or by editing the `TWEAK_DEFAULTS` in `Nudge Landing v3.html`:

```js
const TWEAK_DEFAULTS = { "accentColor": "#FF6B35", ... }
```

### Fonts

Loaded from Google Fonts and Fontshare:
- **Cabinet Grotesk** (headings) — Fontshare
- **Instrument Sans** (body) — Google Fonts  
- **JetBrains Mono** (code) — Google Fonts

To change fonts, update the `<link>` tags in the HTML head and the CSS variables.

### Dev Page Colors

Defined as `D` object in `dev-page-v3.jsx`:
```js
const D = { bg: '#0A0A0A', bg2: '#0E0E0E', card: '#141414', border: '#1E1E1E', t1: '#EDEDED', t2: '#A3A3A3', t3: '#666' };
```

### PM Page Colors

Defined as `P` object in `pm-page-v3.jsx`:
```js
const P = { bg: '#FAFAFA', bg2: '#fff', card: '#fff', border: '#E8EAF0', t1: '#1A1A2E', t2: '#4A4A6A', t3: '#9CA3AF' };
```

---

## Deployment

### Option 1: Static hosting

Upload all files to any static host (Vercel, Netlify, GitHub Pages, Cloudflare Pages). The page is fully client-side rendered.

Required files:
- `Nudge Landing v3.html`
- `split-v3.jsx`
- `dev-page-v3.jsx`
- `pm-page-v3.jsx`
- `app-v3.jsx`
- `tweaks-panel.jsx`

### Option 2: Bundle for production

For production, you'd want to:
1. Replace Babel standalone with a build step (Vite, esbuild)
2. Bundle all JSX into a single JS file
3. Minify CSS and JS
4. Self-host the fonts instead of loading from CDN

### Option 3: Standalone HTML

Use the "Save as standalone HTML" feature to bundle everything into a single self-contained file that works offline.

---

## Analytics & Tracking

To add analytics, insert your tracking script in the `<head>` of `Nudge Landing v3.html`:

```html
<!-- Example: Plausible -->
<script defer data-domain="nudge.dev" src="https://plausible.io/js/script.js"></script>
```

To track which persona users choose, add events to the `handleSelect` function in `app-v3.jsx`:

```js
const handleSelect = (side) => {
  // Add your analytics event here
  // e.g., plausible('Persona Selected', { props: { persona: side } });
  setPersona(side);
  localStorage.setItem('nudge-persona', side);
  setTimeout(() => setPhase('page'), 50);
};
```

---

## localStorage Keys

| Key | Value | Purpose |
|-----|-------|---------|
| `nudge-persona` | `'dev'` or `'pm'` | Remembers persona choice (skips split on return) |

To reset to the split intro, remove this key or use the "Back to intro" button in the Tweaks panel.

---

## Checklist Before Launch

- [ ] Replace all `https://github.com` with real repo URL
- [ ] Replace all `https://linkedin.com` with real profile URL
- [ ] Update GitHub stars count (`★ 12.4k`)
- [ ] Update version number (`v0.1.0`)
- [ ] Add real download URLs to the download popover buttons
- [ ] Replace placeholder testimonials with real ones
- [ ] Wire "See it in action" button to a demo video
- [ ] Wire "Join the waitlist" to your waitlist endpoint
- [ ] Update integration statuses as they ship
- [ ] Review and finalize pricing tiers
- [ ] Add analytics tracking
- [ ] Test on mobile (responsive breakpoints included)
- [ ] Test both persona flows end-to-end
- [ ] Test download popover on both split and PM page
