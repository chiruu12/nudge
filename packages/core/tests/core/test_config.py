"""Tests for NudgeConfig."""

from __future__ import annotations

from pathlib import Path

import pytest

from nudge.core.config import NudgeConfig


class TestNudgeConfig:
    def test_defaults(self) -> None:
        cfg = NudgeConfig()
        assert cfg.stt_provider == "groq"
        assert cfg.llm_provider == "groq"
        assert cfg.llm_tier == "standard"
        assert cfg.hotkey == "cmd+shift+n"
        assert cfg.sample_rate == 16000
        assert "task" in cfg.intents
        assert "alarm" in cfg.intents

    def test_save_and_load(self, tmp_path: Path) -> None:
        cfg = NudgeConfig(stt_provider="deepgram", hotkey="ctrl+alt+h")
        path = cfg.save(tmp_path / "test.yaml")
        assert path.exists()

        loaded = NudgeConfig.load(path)
        assert loaded.stt_provider == "deepgram"
        assert loaded.hotkey == "ctrl+alt+h"
        assert loaded.llm_provider == "groq"

    def test_load_missing_file(self, tmp_path: Path) -> None:
        cfg = NudgeConfig.load(tmp_path / "nonexistent.yaml")
        assert cfg.stt_provider == "groq"

    def test_from_preset(self) -> None:
        cfg = NudgeConfig.from_preset("default")
        assert cfg.stt_provider == "groq"

    def test_from_preset_fast(self) -> None:
        cfg = NudgeConfig.from_preset("fast")
        assert cfg.llm_tier == "lite"

    def test_from_preset_openai(self) -> None:
        cfg = NudgeConfig.from_preset("openai")
        assert cfg.llm_provider == "openai"
        assert cfg.stt_provider == "groq"
        assert "launch" in cfg.intents

    def test_from_preset_missing(self) -> None:
        with pytest.raises(FileNotFoundError):
            NudgeConfig.from_preset("nonexistent_preset")

    def test_pydantic_validation(self) -> None:
        cfg = NudgeConfig(sample_rate=44100)
        assert cfg.sample_rate == 44100
        d = cfg.model_dump()
        assert d["sample_rate"] == 44100

    def test_custom_intents(self) -> None:
        cfg = NudgeConfig(intents={"greet": "user says hello"})
        assert cfg.intents == {"greet": "user says hello"}

    def test_load_malformed_yaml(self, tmp_path: Path) -> None:
        bad = tmp_path / "bad.yaml"
        bad.write_text(": invalid: yaml: [[[")
        cfg = NudgeConfig.load(bad)
        assert cfg.stt_provider == "groq"  # falls back to defaults
