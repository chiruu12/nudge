"""Launcher toolkit — voice-driven app launching with prompt passthrough."""

from __future__ import annotations

import logging
import os
import shutil
import subprocess
from typing import NotRequired, TypedDict

logger = logging.getLogger(__name__)


class AppDefinition(TypedDict):
    cmd: str
    args_template: list[str]
    name: str
    terminal: NotRequired[bool]
    mac_bundle: NotRequired[str]


APPS: dict[str, AppDefinition] = {
    "codex": {
        "cmd": "codex",
        "args_template": ["{prompt}"],
        "name": "OpenAI Codex",
        "mac_bundle": "Codex",
    },
    "claude": {
        "cmd": "claude",
        "args_template": ["{prompt}"],
        "name": "Claude Code",
        "terminal": True,
    },
    "cursor": {
        "cmd": "cursor",
        "args_template": [],
        "name": "Cursor",
        "mac_bundle": "Cursor",
    },
}


def _open_in_terminal(args: list[str]) -> None:
    """Open a command in a new macOS Terminal window."""
    escaped = " ".join(arg.replace("'", "'\\''") for arg in args)
    apple_script = f'tell application "Terminal" to do script "{escaped}"'
    subprocess.Popen(["osascript", "-e", apple_script])


def launch_app(app_name: str, prompt: str = "") -> str:
    """Launch an app, optionally with a prompt."""
    key = app_name.lower().strip()

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
    bundle = app.get("mac_bundle")

    # Prefer macOS .app when it exists
    if bundle and os.path.exists(f"/Applications/{bundle}.app"):
        try:
            subprocess.Popen(["open", "-a", bundle])
            msg = f"Opened {app['name']}."
            if prompt:
                msg = f"Opened {app['name']}. Prompt: {prompt}"
            return msg
        except Exception as e:
            logger.warning("Bundle launch failed for %s, trying CLI: %s", bundle, e)

    # Fall back to CLI
    if not shutil.which(cmd):
        return f"{app['name']} is not installed. Install it first."

    args = [cmd]
    if prompt and app["args_template"]:
        args.extend([a.replace("{prompt}", prompt) for a in app["args_template"]])

    try:
        if app.get("terminal"):
            _open_in_terminal(args)
        else:
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
    available = []
    for key, app in APPS.items():
        if shutil.which(app["cmd"]):
            available.append(f"{app['name']} ({key})")
        elif app.get("mac_bundle"):
            if os.path.exists(f"/Applications/{app['mac_bundle']}.app"):
                available.append(f"{app['name']} ({key})")
    return available
