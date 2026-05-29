"""Read the system clipboard (hive's ClipboardToolkit only writes)."""

from __future__ import annotations

import logging
import platform
import subprocess

logger = logging.getLogger(__name__)


def read_clipboard() -> str:
    """Return the current system clipboard text, or "" if unavailable.

    macOS uses pbpaste; Linux uses xclip. Never raises.
    """
    system = platform.system()
    if system == "Darwin":
        cmd = ["pbpaste"]
    elif system == "Linux":
        cmd = ["xclip", "-selection", "clipboard", "-o"]
    else:
        return ""

    try:
        out = subprocess.run(cmd, capture_output=True, timeout=5)
    except (FileNotFoundError, subprocess.SubprocessError) as e:
        logger.warning("Clipboard read failed: %s", e)
        return ""
    if out.returncode != 0:
        return ""
    return out.stdout.decode("utf-8", errors="replace").strip()
