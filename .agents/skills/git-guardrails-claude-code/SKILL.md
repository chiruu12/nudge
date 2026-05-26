---
name: git-guardrails-Codex
description: >
  Set up Codex hooks to block dangerous git commands (push, reset --hard,
  clean, branch -D, etc.) before they execute. Use when user wants to prevent
  destructive git operations, add git safety hooks, or block git push/reset
  in Codex.
---

# Git Guardrails for Codex

Sets up a PreToolUse hook that intercepts and blocks dangerous git commands before Codex executes them. AI agents are confident and fast — a dangerous combination when `git push --force` or `git reset --hard` is one misinterpretation away. This hook adds a hard safety layer that can't be rationalized past.

## When to Use

- User wants to prevent Codex from running destructive git commands
- Setting up a new Codex project where git safety matters
- After an incident where Codex ran an unwanted git operation
- **NOT** when user wants general pre-commit hooks (use `setup-pre-commit`)
- **NOT** when user wants to block non-git commands — this is git-specific
- **NOT** in throwaway repos where destructive ops are fine

## What Gets Blocked

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

## Process

### 1. Ask scope

Ask the user: **this project only** (`.Codex/settings.json`) or **all projects** (`~/.Codex/settings.json`)?

### 2. Copy the hook script

Bundled at: [scripts/block-dangerous-git.sh](scripts/block-dangerous-git.sh)

Copy to target:
- **Project**: `.Codex/hooks/block-dangerous-git.sh`
- **Global**: `~/.Codex/hooks/block-dangerous-git.sh`

Make executable: `chmod +x`.

### 3. Add hook to settings

Merge into the appropriate settings file's `hooks.PreToolUse` array:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.Codex/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

If settings already exist, merge — don't overwrite.

### 4. Ask about customization

Ask if user wants to add or remove patterns from the blocked list.

### 5. Verify

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | <path-to-script>
```

Should exit code 2 with BLOCKED message.

## Common Rationalizations

| Shortcut | Why It Fails |
|----------|-------------|
| "I'll just tell Codex not to push in the system prompt" | System prompt instructions are soft — agents rationalize past them. A hook is a hard gate. |
| "I only need to block `--force`, regular push is fine" | Regular push to the wrong branch is just as dangerous. The USER decides when to push, not the agent. |
| "I'll add the hook later, this project is low-risk" | Incidents happen in "low-risk" projects. Cost of installing: 2 minutes. Cost of unwanted force-push: hours. |
| "The script doesn't need to be executable" | Hook fails silently if not executable. Codex proceeds believing no hook exists. Always `chmod +x`. |

## Red Flags

- Settings file has syntax errors after merging (validate JSON)
- Script uses hardcoded absolute path instead of `$CLAUDE_PROJECT_DIR` for project scope
- Hook added but never tested — silent failures mean false sense of security
- Existing hooks overwritten instead of merged

## Verification Checklist

- [ ] Script exists at target path and is executable
- [ ] Settings JSON is valid (no trailing commas, proper nesting)
- [ ] Blocked command exits code 2
- [ ] Safe command (`git status`) exits code 0
- [ ] Existing settings preserved (other hooks/permissions not lost)
- [ ] User confirmed which commands to block/allow

## Anti-patterns

- **DO NOT** overwrite existing settings.json — read, merge, write back
- **DO NOT** skip verification — untested hook provides false security
- **DO NOT** use hardcoded paths for project scope — use `$CLAUDE_PROJECT_DIR`
- **DO NOT** install globally without asking — project scope is safer default
- **DO NOT** block non-destructive operations (commit, status) — over-blocking makes users disable it
