# Hive contribution: `read_clipboard` tool for `ClipboardToolkit`

Draft for a PR to the **hive** repo. `ClipboardToolkit` can currently only
*write* to the system clipboard (`copy_to_clipboard`, `copy_note`, `copy_task`,
`copy_link`). This adds the symmetric **read** capability so an agent can act on
whatever the user just copied — e.g. "save the link I just copied", "add this to
my notes".

Target file: `hive/tools/clipboard/toolkit.py` (matches the existing
write-path style: a module-level async helper + a `@tool()` method).

---

## 1. New module-level helper

Add next to `_copy_to_system_clipboard` (mirrors it; uses `pbpaste` / `xclip -o`):

```python
async def _read_from_system_clipboard() -> str | None:
    """Read text from the system clipboard. Supports macOS and Linux.

    Returns the clipboard text, or None if reading is unsupported or failed.
    """
    system = platform.system()
    if system == "Darwin":
        cmd = ["pbpaste"]
    elif system == "Linux":
        cmd = ["xclip", "-selection", "clipboard", "-o"]
    else:
        logger.warning("Clipboard not supported on %s", system)
        return None

    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=5)
        if proc.returncode != 0:
            return None
        return stdout.decode("utf-8", errors="replace")
    except Exception as e:
        logger.warning("Clipboard read failed: %s", e)
        return None
```

## 2. New `@tool()` method on `ClipboardToolkit`

Add alongside `copy_to_clipboard`:

```python
    @tool()
    async def read_clipboard(self) -> str:
        """Read the current text contents of the system clipboard.

        Use this when the user refers to something they have already copied —
        for example "save the link I just copied" or "add this to my notes".
        """
        text = await _read_from_system_clipboard()
        if text is None:
            return "Couldn't read the clipboard on this system."
        text = text.strip()
        if not text:
            return "The clipboard is empty."
        return text
```

## 3. Update the `instructions` property

```python
    @property
    def instructions(self) -> str:
        return (
            "You can copy text, notes, tasks, or links to the user's clipboard, "
            "and read what's currently on the clipboard."
        )
```

---

## Unified diff (against hive-agent 0.4.2)

```diff
--- a/hive/tools/clipboard/toolkit.py
+++ b/hive/tools/clipboard/toolkit.py
@@ async def _copy_to_system_clipboard(text: str) -> bool:
         await asyncio.wait_for(proc.communicate(input=text.encode()), timeout=5)
         return proc.returncode == 0
     except Exception as e:
         logger.warning("Clipboard copy failed: %s", e)
         return False
+
+
+async def _read_from_system_clipboard() -> str | None:
+    """Read text from the system clipboard. Supports macOS and Linux.
+
+    Returns the clipboard text, or None if reading is unsupported or failed.
+    """
+    system = platform.system()
+    if system == "Darwin":
+        cmd = ["pbpaste"]
+    elif system == "Linux":
+        cmd = ["xclip", "-selection", "clipboard", "-o"]
+    else:
+        logger.warning("Clipboard not supported on %s", system)
+        return None
+
+    try:
+        proc = await asyncio.create_subprocess_exec(
+            *cmd,
+            stdout=asyncio.subprocess.PIPE,
+            stderr=asyncio.subprocess.PIPE,
+        )
+        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=5)
+        if proc.returncode != 0:
+            return None
+        return stdout.decode("utf-8", errors="replace")
+    except Exception as e:
+        logger.warning("Clipboard read failed: %s", e)
+        return None
@@ class ClipboardToolkit(Toolkit):
     @property
     def instructions(self) -> str:
-        return "You can copy text, notes, tasks, or links to the user's clipboard."
+        return (
+            "You can copy text, notes, tasks, or links to the user's clipboard, "
+            "and read what's currently on the clipboard."
+        )
@@ class ClipboardToolkit(Toolkit):
         ok = await _copy_to_system_clipboard(text)
         if ok:
             preview = text[:80] + ("..." if len(text) > 80 else "")
             return f"Copied to clipboard: {preview}"
         return "Failed to copy to clipboard."
+
+    @tool()
+    async def read_clipboard(self) -> str:
+        """Read the current text contents of the system clipboard.
+
+        Use this when the user refers to something they have already copied —
+        for example "save the link I just copied" or "add this to my notes".
+        """
+        text = await _read_from_system_clipboard()
+        if text is None:
+            return "Couldn't read the clipboard on this system."
+        text = text.strip()
+        if not text:
+            return "The clipboard is empty."
+        return text
```

---

## Test

`tests/tools/test_clipboard_read.py`:

```python
"""Tests for ClipboardToolkit.read_clipboard."""

from __future__ import annotations

import pytest

from hive.tools.clipboard import toolkit as cb


@pytest.mark.asyncio
async def test_read_clipboard_returns_trimmed_text(monkeypatch):
    async def fake() -> str:
        return "  https://example.com  \n"

    monkeypatch.setattr(cb, "_read_from_system_clipboard", fake)
    tk = cb.ClipboardToolkit()
    assert await tk.read_clipboard() == "https://example.com"


@pytest.mark.asyncio
async def test_read_clipboard_empty(monkeypatch):
    async def fake() -> str:
        return "   \n"

    monkeypatch.setattr(cb, "_read_from_system_clipboard", fake)
    tk = cb.ClipboardToolkit()
    assert "empty" in (await tk.read_clipboard()).lower()


@pytest.mark.asyncio
async def test_read_clipboard_unavailable(monkeypatch):
    async def fake() -> None:
        return None

    monkeypatch.setattr(cb, "_read_from_system_clipboard", fake)
    tk = cb.ClipboardToolkit()
    assert "couldn't read" in (await tk.read_clipboard()).lower()


@pytest.mark.asyncio
async def test_helper_unsupported_platform(monkeypatch):
    monkeypatch.setattr(cb.platform, "system", lambda: "Windows")
    assert await cb._read_from_system_clipboard() is None
```

---

## PR text

**Title:** Add `read_clipboard` tool to `ClipboardToolkit`

**Description:**

`ClipboardToolkit` could write to the system clipboard but not read from it.
This adds a `read_clipboard` tool (and a `_read_from_system_clipboard` helper
mirroring `_copy_to_system_clipboard`) so agents can act on content the user has
already copied — e.g. "save the link I just copied", "add this to my notes".

- macOS: `pbpaste`; Linux: `xclip -selection clipboard -o`; other platforms
  return `None` (logged), consistent with the existing copy path.
- 5s timeout, never raises; the tool returns a friendly string on
  empty/unavailable.
- `instructions` updated to mention reading.

No new dependencies. Standalone (`ClipboardToolkit()`) — no store/memory needed.

**Changelog:** `Added: ClipboardToolkit.read_clipboard for reading the system clipboard.`

---

## Follow-up in Nudge (after hive ships this)

Nudge currently has a local stopgap, `nudge/tools/clipboard_read.py` (used by the
`save this link` flow in `named_links.py`). Once a hive release includes
`read_clipboard`:

- Drop `nudge/tools/clipboard_read.py` and call hive's `_read_from_system_clipboard`
  (or expose `read_clipboard` as an agent tool), and
- bump the hive pin in `packages/core/pyproject.toml`.
