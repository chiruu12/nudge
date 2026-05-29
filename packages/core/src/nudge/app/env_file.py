"""Read/write the ~/.nudge/.env file where API keys are stored."""

from __future__ import annotations

import os
from pathlib import Path

from nudge.core.config import CONFIG_DIR

ENV_FILE = CONFIG_DIR / ".env"


def upsert_env_key(env_var: str, value: str, path: Path | None = None) -> Path:
    """Set ENV_VAR=value in the .env file, replacing any existing line.

    Writes with 0600 permissions (the file holds secrets). Other lines are
    preserved verbatim.
    """
    p = path or ENV_FILE
    p.parent.mkdir(parents=True, exist_ok=True)

    lines: list[str] = []
    if p.exists():
        lines = p.read_text(encoding="utf-8").splitlines()

    prefix = f"{env_var}="
    new_line = f"{env_var}={value}"
    replaced = False
    for i, line in enumerate(lines):
        if line.startswith(prefix):
            lines[i] = new_line
            replaced = True
            break
    if not replaced:
        lines.append(new_line)

    # Create the file with restrictive perms before writing the secret.
    fd = os.open(p, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    os.chmod(p, 0o600)
    return p
