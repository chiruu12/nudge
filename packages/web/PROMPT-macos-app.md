# Nudge — macOS App Design & SwiftUI Implementation Prompt

## Overview
Build a macOS menu bar application for **Nudge** — a voice-first assistant that lets users press a hotkey, speak a command, and have it processed through a pipeline (Voice → STT → Intent → Agent Action) in sub-second time.

The app needs: a menu bar icon, a popover/panel UI, a dashboard, and settings. Package as a .dmg for distribution.

## What Nudge Does
- User presses **cmd+shift+n** (global hotkey)
- A compact recording UI appears (floating panel or popover from menu bar)
- User speaks a command (e.g., "remind me to push the fix in 2 hours")
- Pipeline processes: STT (340ms) → Intent classification (120ms) → Agent action (280ms)
- Result shown briefly, then UI dismisses
- Supports: tasks, alarms, knowledge base saves, clipboard ops, soul system rules

## Design System
- **Accent color**: #FF6B35 (burnt orange)
- **Typography**: System San Francisco (native macOS) for UI, monospace (SF Mono) for pipeline/technical info
- **Dark mode primary** (follows system appearance)
- **Light mode**: clean whites and light grays
- **Success green**: #22C55E
- **Recording red**: #EF4444
- **Corners**: 12px for cards, 8px for buttons, 4px for inputs
- **Shadows**: subtle, layered (macOS native feel)

## Components to Build

### 1. Menu Bar Icon
- Small, minimal icon in the macOS menu bar (top-right)
- Design: a small circle/dot or abstract "N" mark in the accent color when idle
- States:
  - **Idle**: subtle, monochrome icon
  - **Recording**: icon pulses red or turns accent-colored with animation
  - **Processing**: subtle spinner or progress indicator
  - **Success**: brief green flash, then back to idle
- Click → opens the main popover/dashboard
- Right-click → quick menu (Quit, Settings, About)

### 2. Recording Panel (the core interaction)
- Triggered by cmd+shift+n (or clicking the menu bar icon)
- Compact floating panel, centered on screen or anchored to menu bar
- **States:**
  - **Ready**: "Press to speak" or auto-starts recording. Waveform visualization.
  - **Recording**: Live audio waveform (orange/accent), elapsed time counter, "Listening..." label
  - **Processing**: Pipeline progress — show each step completing:
    - ● STT... → ✓ 340ms
    - ● Intent... → ✓ 120ms  
    - ● Agent... → ✓ 280ms
  - **Result**: Brief confirmation card (e.g., "✓ Alarm set — Push fix — 2h from now"), auto-dismisses after 2-3 seconds
  - **Error**: Red accent, retry option
- Waveform should be real-time audio visualization (not fake)
- Panel should feel lightweight — appears fast, dismisses fast
- Keyboard shortcut to cancel: Esc

### 3. Dashboard (main popover from menu bar)
Sections inside the popover (tabbed or scrollable):

#### Tasks Tab
- List of active tasks with checkboxes
- Each task shows: title, created time, source ("voice" badge)
- Completed tasks move to bottom, struck through
- Swipe to delete or long-press for options
- "Add task" button (opens recording or text input)

#### Alarms Tab  
- List of upcoming alarms, sorted by time
- Each alarm: time, label, recurring indicator
- Toggle to enable/disable
- Past alarms section (collapsible)

#### Knowledge Base Tab
- Saved snippets/notes from voice commands
- Search bar at top
- Each entry: content, timestamp, tags
- Click to expand/copy

#### Activity/History Tab
- Recent voice commands log
- Each entry: transcript, intent detected, action taken, latency
- Useful for debugging and seeing what Nudge understood

### 4. Settings Panel
- **General**: Launch at login, global hotkey customization, notification preferences
- **Providers**: 
  - Dropdown to select STT provider (Groq, OpenAI, Whisper local, etc.)
  - Dropdown to select LLM provider
  - API key inputs for each provider
  - "Test connection" button for each
  - Preset selector (Fast / Default / Offline) with one-click setup
- **Soul System**: 
  - List of personal rules (e.g., "later = this evening")
  - Add/edit/delete rules
  - Import/export
- **Skills**:
  - Connected IDEs list (Cursor, Claude Code, VS Code)
  - Writing style status (learned / not started)
  - Project context (which projects are synced)
  - "Run skill setup" button that starts the onboarding questionnaire
- **Usage Dashboard** (Pro tier):
  - Current month usage: STT minutes, LLM tokens
  - Usage graph (bar chart, last 7 days)
  - Billing status, plan tier
- **Account**: Sign in (for Pro/Team), manage subscription
- **About**: Version, check for updates, GitHub link, licenses

### 5. Onboarding Flow (first launch)
1. Welcome screen: "Meet Nudge" + brief description
2. Permissions: Request microphone access, accessibility access (for global hotkey)
3. Provider setup: Choose a preset (Fast/Default/Offline) or configure manually
4. Skills intro: "Want Nudge to learn how you work?" → optional setup wizard
5. Test drive: Record a test command, show the pipeline in action
6. Done: "You're all set. Press cmd+shift+n anytime."

## SwiftUI Architecture

```
NudgeApp/
├── App/
│   ├── NudgeApp.swift          // @main, MenuBarExtra
│   └── AppState.swift          // ObservableObject, central state
├── Views/
│   ├── MenuBar/
│   │   ├── MenuBarIcon.swift   // Menu bar icon + states
│   │   └── MenuBarPopover.swift // Main dashboard popover
│   ├── Recording/
│   │   ├── RecordingPanel.swift // Floating recording UI
│   │   ├── WaveformView.swift  // Real-time audio waveform
│   │   └── PipelineView.swift  // Processing steps visualization
│   ├── Dashboard/
│   │   ├── TasksView.swift
│   │   ├── AlarmsView.swift
│   │   ├── KnowledgeView.swift
│   │   └── HistoryView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift  // Main settings container
│   │   ├── ProvidersView.swift
│   │   ├── SoulView.swift
│   │   ├── SkillsView.swift
│   │   └── UsageView.swift
│   └── Onboarding/
│       └── OnboardingFlow.swift
├── Models/
│   ├── Task.swift
│   ├── Alarm.swift
│   ├── KnowledgeEntry.swift
│   └── VoiceCommand.swift
├── Services/
│   ├── AudioService.swift      // Microphone capture
│   ├── STTService.swift        // Speech-to-text (provider abstraction)
│   ├── IntentService.swift     // Intent classification
│   ├── AgentService.swift      // Action execution
│   ├── HotkeyService.swift     // Global hotkey registration
│   └── SkillsService.swift     // IDE integration, writing style analysis
├── Styles/
│   └── NudgeTheme.swift        // Colors, fonts, shared styles
└── Resources/
    └── Assets.xcassets         // App icon, menu bar icons
```

## Key SwiftUI Patterns
- Use `MenuBarExtra` (macOS 13+) for the menu bar presence
- `NSPanel` subclass for the floating recording panel (so it can appear above other apps)
- `AVAudioEngine` for real-time audio capture and waveform visualization
- `CGEventTap` or `MASShortcut` for global hotkey
- `@Observable` (macOS 14+) or `@ObservableObject` for state management
- `SwiftData` or `CoreData` for persistent storage (tasks, alarms, knowledge)
- `URLSession` for API calls to STT/LLM providers
- Combine for reactive pipeline processing

## Visual References
- **Menu bar**: Like Raycast or CleanShot X — minimal, polished
- **Recording panel**: Like macOS Dictation or Whisper Transcription — compact, focused
- **Dashboard**: Like Raycast's extensions panel or Bartender — clean tabbed interface
- **Settings**: Native macOS settings style (like System Settings in Ventura+)

## Important Notes
- App must feel **native macOS** — not like an Electron web app
- Respect system appearance (dark/light mode)
- Use SF Symbols for icons wherever possible
- Recording panel should appear within 100ms of hotkey press
- Pipeline visualization should show real-time progress, not fake animations
- The app should feel fast and lightweight — no splash screens, no loading states longer than necessary
- Menu bar icon should NOT be annoying — subtle when idle, informative when active

## Packaging
- Build as a standard macOS .app bundle
- Create a .dmg for distribution with:
  - App icon
  - Applications folder shortcut
  - Simple background image with "Drag to install" arrow
- Code sign and notarize for Gatekeeper
- Sparkle framework for auto-updates (optional)
