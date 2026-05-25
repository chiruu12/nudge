"""Session history — read back past voice interactions from the log."""

from __future__ import annotations

import json
from pathlib import Path


def load_history(log_path: Path, limit: int = 50) -> list[dict[str, object]]:
    """Load recent session logs from the JSONL file."""
    if not log_path.exists():
        return []

    entries: list[dict[str, object]] = []
    with open(log_path) as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    continue

    return entries[-limit:]
