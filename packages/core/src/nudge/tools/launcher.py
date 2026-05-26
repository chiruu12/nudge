"""Launcher toolkit — voice-driven app launching with prompt passthrough."""

from __future__ import annotations

import logging
import shutil
import subprocess
from typing import NotRequired, TypedDict

logger = logging.getLogger(__name__)


class AppDefinition(TypedDict):
    cmd: str
    args_template: list[str]
    name: str
    mac_bundle: NotRequired[str]


APPS: dict[str, AppDefinition] = {
    "codex": {
        "cmd": "codex",
        "args_template": ["{prompt}"],
        "name": "OpenAI Codex",
    },
    "claude": {
        "cmd": "claude",
        "args_template": ["{prompt}"],
        "name": "Claude Code",
    },
    "cursor": {
        "cmd": "cursor",
        "args_template": [],
        "name": "Cursor",
        "mac_bundle": "Cursor",
    },
}


def launch_app(app_name: str, prompt: str = "") -> str:
    """Launch an app, optionally with a prompt.

    Returns a confirmation message.
    """
    key = app_name.lower().strip()

    # Handle aliases
    aliases = {
        "claude code": "claude",
        "claude-code": "claude",
    }
    key = aliases.get(key, key)

    if key not in APPS:
        available = ", ".join(APPS.keys())
        return f"Unknown app: {app_name}. Available: {available}"

    app = APPS[key]
    cmd = app["cmd"]

    # Check if CLI tool exists
    if not shutil.which(cmd):
        # Try macOS open -a for GUI apps
        bundle = app.get("mac_bundle")
        if bundle:
            try:
                subprocess.Popen(["open", "-a", bundle])
                return f"Opened {app['name']}."
            except Exception as e:
                return f"Could not open {app['name']}: {e}"
        return f"{app['name']} is not installed. Install it first."

    # Build command
    args = [cmd]
    if prompt and app["args_template"]:
        args.extend([a.format(prompt=prompt) for a in app["args_template"]])

    try:
        subprocess.Popen(args)
        msg = f"Launched {app['name']}."
        if prompt:
            msg = f"Launched {app['name']} with: {prompt}"
        return msg
    except Exception as e:
        logger.error("Failed to launch %s: %s", app["name"], e)
        return f"Failed to launch {app['name']}: {e}"


def list_available_apps() -> list[str]:
    """Return names of apps that are installed and available."""
    import os

    available = []
    for key, app in APPS.items():
        if shutil.which(app["cmd"]):
            available.append(f"{app['name']} ({key})")
        elif app.get("mac_bundle"):
            # Check if .app exists
            if os.path.exists(f"/Applications/{app['mac_bundle']}.app"):
                available.append(f"{app['name']} ({key})")
    return available
