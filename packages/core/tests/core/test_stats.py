"""Tests for usage-stats aggregation."""

from __future__ import annotations

import json
from pathlib import Path

from nudge.core.stats import MANUAL_SECONDS_PER_COMMAND, compute_stats


def _write_log(path: Path, entries: list[dict]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        for e in entries:
            f.write(json.dumps(e) + "\n")


def test_missing_file_returns_empty(tmp_path: Path) -> None:
    stats = compute_stats(tmp_path / "nope.jsonl")
    assert stats["total_commands"] == 0
    assert stats["time_saved_seconds"] == 0.0
    assert stats["commands_by_intent"] == {}


def test_aggregates_counts_and_intents(tmp_path: Path) -> None:
    log = tmp_path / "sessions.jsonl"
    _write_log(
        log,
        [
            {"result": {"text": "a", "intent": "task", "duration_ms": 1000}},
            {"result": {"text": "b", "intent": "task", "duration_ms": 2000}},
            {"result": {"text": "c", "intent": "alarm", "duration_ms": 3000, "error": "boom"}},
        ],
    )
    stats = compute_stats(log)
    assert stats["total_commands"] == 3
    assert stats["commands_by_intent"] == {"task": 2, "alarm": 1}
    assert stats["success_count"] == 2
    assert stats["success_rate"] == 2 / 3
    assert stats["avg_duration_ms"] == 2000


def test_time_saved_heuristic_and_floor(tmp_path: Path) -> None:
    log = tmp_path / "sessions.jsonl"
    # 2 commands → 2*30 = 60s manual; actual 3s → saved 57s.
    _write_log(
        log,
        [
            {"result": {"text": "a", "intent": "task", "duration_ms": 1000}},
            {"result": {"text": "b", "intent": "note", "duration_ms": 2000}},
        ],
    )
    stats = compute_stats(log)
    assert stats["time_saved_seconds"] == 2 * MANUAL_SECONDS_PER_COMMAND - 3.0

    # If actual time somehow exceeds the heuristic, floor at 0.
    _write_log(log, [{"result": {"text": "a", "intent": "task", "duration_ms": 999_000}}])
    assert compute_stats(log)["time_saved_seconds"] == 0.0


def test_skips_malformed_and_empty(tmp_path: Path) -> None:
    log = tmp_path / "sessions.jsonl"
    with open(log, "w", encoding="utf-8") as f:
        f.write("not json\n")
        f.write("\n")
        f.write(json.dumps({"result": None}) + "\n")
        f.write(json.dumps({"result": {"text": ""}}) + "\n")
        f.write(json.dumps({"result": {"text": "ok", "intent": "task", "duration_ms": 500}}) + "\n")
    stats = compute_stats(log)
    assert stats["total_commands"] == 1


def test_stt_average_only_counts_audio(tmp_path: Path) -> None:
    log = tmp_path / "sessions.jsonl"
    _write_log(
        log,
        [
            {"result": {"text": "a", "intent": "task", "stt_ms": 0, "duration_ms": 100}},
            {"result": {"text": "b", "intent": "task", "stt_ms": 400, "duration_ms": 500}},
        ],
    )
    stats = compute_stats(log)
    # Only the audio command (stt_ms>0) counts toward avg_stt_ms.
    assert stats["avg_stt_ms"] == 400
