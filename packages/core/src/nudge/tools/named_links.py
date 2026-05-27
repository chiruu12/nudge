"""Named link handler — deterministic save/open/copy/list/remove for named URLs."""

from __future__ import annotations

import json
import logging
import re
import subprocess
import webbrowser
from pathlib import Path
from urllib.parse import urlparse

logger = logging.getLogger(__name__)

DEFAULT_LINKS_PATH = Path.home() / ".nudge" / "data" / "links.json"


def _normalize(name: str) -> str:
    return re.sub(r"[\s_]+", "-", name.strip().lower())


def _load(path: Path) -> dict[str, dict[str, str]]:
    if path.exists():
        try:
            data: dict[str, dict[str, str]] = json.loads(path.read_text())
            return data
        except (json.JSONDecodeError, OSError):
            logger.warning("Corrupt links file, backing up before reset")
            try:
                path.rename(path.with_suffix(".json.bak"))
            except OSError:
                pass
    return {}


def _save(links: dict[str, dict[str, str]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(links, indent=2))


def _validate_url(url: str) -> bool:
    parsed = urlparse(url)
    return parsed.scheme in ("http", "https") and bool(parsed.netloc)


def save_link(name: str, url: str, path: Path = DEFAULT_LINKS_PATH) -> str:
    if not name.strip():
        return "Need a name for the link."
    if not _validate_url(url):
        return f"Invalid URL: {url}"
    links = _load(path)
    key = _normalize(name)
    action = "Updated" if key in links else "Saved"
    links[key] = {"name": name.strip(), "url": url.strip()}
    _save(links, path)
    return f"{action} {name.strip()} → {url.strip()}"


def open_link(name: str, path: Path = DEFAULT_LINKS_PATH, opener: object = None) -> str:
    links = _load(path)
    key = _normalize(name)
    if key not in links:
        return _suggest(name, links)
    url = links[key]["url"]
    if opener is not None:
        opener(url)  # type: ignore[operator]
    else:
        webbrowser.open(url)
    return f"Opened {links[key]['name']} ({url})"


def copy_link(name: str, path: Path = DEFAULT_LINKS_PATH, copier: object = None) -> str:
    links = _load(path)
    key = _normalize(name)
    if key not in links:
        return _suggest(name, links)
    url = links[key]["url"]
    if copier is not None:
        copier(url)  # type: ignore[operator]
    else:
        try:
            subprocess.run(["pbcopy"], input=url.encode(), check=True, capture_output=True)
        except (FileNotFoundError, subprocess.CalledProcessError):
            return f"{links[key]['name']}: {url} (clipboard unavailable)"
    return f"Copied {links[key]['name']} → {url}"


def list_links(path: Path = DEFAULT_LINKS_PATH) -> str:
    links = _load(path)
    if not links:
        return "No saved links."
    lines = [f"  {v['name']}: {v['url']}" for v in links.values()]
    return f"{len(links)} link(s):\n" + "\n".join(lines)


def remove_link(name: str, path: Path = DEFAULT_LINKS_PATH) -> str:
    links = _load(path)
    key = _normalize(name)
    if key not in links:
        return _suggest(name, links)
    display = links[key]["name"]
    del links[key]
    _save(links, path)
    return f"Removed {display}."


def _suggest(name: str, links: dict[str, dict[str, str]]) -> str:
    if not links:
        return f"No link named '{name}'. No links saved yet."
    available = ", ".join(v["name"] for v in links.values())
    return f"No link named '{name}'. Available: {available}"


def handle_link_command(
    text: str,
    data_dir: str | Path = "",
    opener: object = None,
    copier: object = None,
) -> str:
    """Parse a voice command and dispatch to the right link operation."""
    if data_dir:
        path = Path(data_dir) / "links.json"
    else:
        path = DEFAULT_LINKS_PATH

    clean = text.strip()
    lowered = clean.lower()

    # Strip trailing filler words
    for suffix in [" link", " url", " please"]:
        if lowered.endswith(suffix):
            clean = clean[: -len(suffix)].strip()
            lowered = clean.lower()

    # list
    if lowered in ("list", "show", "list links", "show links", "my links"):
        return list_links(path)

    # save: "save <name> as <url>" or "save <name> <url>"
    for verb in ["save", "set", "add", "update"]:
        if lowered.startswith(verb + " "):
            rest = clean[len(verb) + 1 :].strip()
            return _parse_save(rest, path)

    # remove/delete
    for verb in ["remove", "delete", "forget"]:
        if lowered.startswith(verb + " "):
            name = clean[len(verb) + 1 :].strip()
            if name.lower().startswith("my "):
                name = name[3:].strip()
            return remove_link(name, path)

    # open
    if lowered.startswith("open "):
        name = clean[5:].strip()
        if name.lower().startswith("my "):
            name = name[3:].strip()
        return open_link(name, path, opener=opener)

    # copy
    if lowered.startswith("copy "):
        name = clean[5:].strip()
        if name.lower().startswith("my "):
            name = name[3:].strip()
        return copy_link(name, path, copier=copier)

    # Fallback: if it looks like a URL, treat as save attempt
    words = clean.split()
    for w in words:
        if _validate_url(w):
            name_part = clean.replace(w, "").strip()
            if name_part:
                return save_link(name_part, w, path)

    return f"I don't understand the link command: {text.strip()}"


def _parse_save(rest: str, path: Path) -> str:
    """Parse 'my LinkedIn as https://...' or 'LinkedIn https://...'."""
    # Strip "my" prefix
    if rest.lower().startswith("my "):
        rest = rest[3:].strip()

    # Try "name as url"
    for sep in [" as ", " to ", " = "]:
        if sep in rest.lower():
            idx = rest.lower().index(sep)
            name = rest[:idx].strip()
            url = rest[idx + len(sep) :].strip()
            return save_link(name, url, path)

    # Try "name url" (last word is URL)
    words = rest.rsplit(maxsplit=1)
    if len(words) == 2 and _validate_url(words[1]):
        return save_link(words[0], words[1], path)

    return "Need a name and URL. Example: save LinkedIn as https://linkedin.com/in/me"
