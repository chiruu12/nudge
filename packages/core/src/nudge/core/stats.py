"""Usage statistics — aggregate the full session history into dashboard metrics."""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path
from typing import Any

# Heuristic: estimated time a user would spend doing one command by hand
# (typing it out, opening the right app, etc.). Used for the "time saved" metric.
MANUAL_SECONDS_PER_COMMAND = 30


def _empty_stats() -> dict[str, Any]:
    return {
        "total_commands": 0,
        "commands_by_intent": {},
        "success_count": 0,
        "success_rate": 0.0,
        "avg_duration_ms": 0,
        "avg_stt_ms": 0,
        "avg_intent_ms": 0,
        "avg_agent_ms": 0,
        "time_saved_seconds": 0.0,
    }


def compute_stats(log_path: Path) -> dict[str, Any]:
    """Aggregate every session in the JSONL log into dashboard metrics.

    Reads the full log (not just the recent window) so "time saved" reflects
    lifetime usage. Skips malformed lines and entries without a result.
    """
    if not log_path.exists():
        return _empty_stats()

    total = 0
    success = 0
    by_intent: Counter[str] = Counter()
    sum_duration = 0
    sum_stt = 0
    sum_intent = 0
    sum_agent = 0
    stt_n = 0

    with open(log_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            result = entry.get("result")
            if not isinstance(result, dict) or not result.get("text"):
                continue

            total += 1
            if not result.get("error"):
                success += 1
            intent = result.get("intent") or ""
            if intent:
                by_intent[intent] += 1

            sum_duration += int(result.get("duration_ms", 0) or 0)
            sum_intent += int(result.get("intent_ms", 0) or 0)
            sum_agent += int(result.get("agent_ms", 0) or 0)
            stt_ms = int(result.get("stt_ms", 0) or 0)
            if stt_ms > 0:
                sum_stt += stt_ms
                stt_n += 1

    if total == 0:
        return _empty_stats()

    actual_seconds = sum_duration / 1000
    time_saved = max(0.0, total * MANUAL_SECONDS_PER_COMMAND - actual_seconds)

    return {
        "total_commands": total,
        "commands_by_intent": dict(by_intent),
        "success_count": success,
        "success_rate": success / total,
        "avg_duration_ms": sum_duration // total,
        "avg_stt_ms": sum_stt // stt_n if stt_n else 0,
        "avg_intent_ms": sum_intent // total,
        "avg_agent_ms": sum_agent // total,
        "time_saved_seconds": time_saved,
    }
