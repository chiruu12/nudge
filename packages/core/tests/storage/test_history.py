"""Tests for session history."""

from __future__ import annotations

import json
from pathlib import Path

from nudge.storage.history import load_history


class TestHistory:
    def test_load_empty(self, tmp_path: Path) -> None:
        result = load_history(tmp_path / "nope.jsonl")
        assert result == []

    def test_load_entries(self, tmp_path: Path) -> None:
        log = tmp_path / "sessions.jsonl"
        entries = [
            {"session_id": "1", "text": "hello"},
            {"session_id": "2", "text": "world"},
        ]
        with open(log, "w") as f:
            for e in entries:
                f.write(json.dumps(e) + "\n")

        result = load_history(log)
        assert len(result) == 2
        assert result[0]["text"] == "hello"

    def test_load_with_limit(self, tmp_path: Path) -> None:
        log = tmp_path / "sessions.jsonl"
        with open(log, "w") as f:
            for i in range(20):
                f.write(json.dumps({"id": i}) + "\n")

        result = load_history(log, limit=5)
        assert len(result) == 5
        assert result[0]["id"] == 15

    def test_handles_bad_json(self, tmp_path: Path) -> None:
        log = tmp_path / "sessions.jsonl"
        with open(log, "w") as f:
            f.write('{"ok": true}\n')
            f.write("not json\n")
            f.write('{"also": "ok"}\n')

        result = load_history(log)
        assert len(result) == 2
