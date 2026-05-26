"""Tests for NudgeEngine — the core brain."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from nudge.core.config import NudgeConfig
from nudge.core.engine import NudgeEngine


@pytest.fixture
def config(tmp_path: Path) -> NudgeConfig:
    return NudgeConfig(
        data_dir=str(tmp_path / "data"),
        log_dir=str(tmp_path / "logs"),
    )


@pytest.fixture
def engine(config: NudgeConfig) -> NudgeEngine:
    with (
        patch("nudge.core.engine.create_stt") as mock_stt,
        patch("nudge.core.engine.create_llm") as mock_llm,
        patch("nudge.core.engine.create_router_llm") as mock_router_llm,
    ):
        mock_stt_inst = MagicMock()
        mock_stt_inst.available = True
        mock_stt.return_value = mock_stt_inst

        mock_provider = MagicMock()
        mock_provider.generate = AsyncMock()
        mock_provider.generate_with_metadata = AsyncMock()
        mock_provider.generate_structured = AsyncMock()
        mock_llm.return_value = mock_provider
        mock_router_llm.return_value = mock_provider

        return NudgeEngine(config)


class TestNudgeEngine:
    def test_creation(self, engine: NudgeEngine) -> None:
        assert engine.config.stt_provider == "groq"
        assert engine.stt is not None
        assert engine.checker is not None

    @pytest.mark.asyncio
    async def test_process_text_with_mock(self, engine: NudgeEngine) -> None:
        with (
            patch.object(engine._router, "classify", new_callable=AsyncMock) as mock_classify,
            patch.object(engine._agent, "run_once", new_callable=AsyncMock) as mock_run,
        ):
            from hive.routing.router import IntentResult

            mock_classify.return_value = IntentResult(
                intent="task", confidence=0.9, raw_text="buy milk"
            )
            mock_run.return_value = "Task created."

            result = await engine.process_text("buy milk")

            assert result.ok
            assert result.text == "buy milk"
            assert result.intent == "task"
            assert result.response == "Task created."
            assert result.duration_ms >= 0

    @pytest.mark.asyncio
    async def test_process_text_error(self, engine: NudgeEngine) -> None:
        with patch.object(engine._router, "classify", side_effect=Exception("boom")):
            result = await engine.process_text("test")
            assert not result.ok
            assert "boom" in result.error

    @pytest.mark.asyncio
    async def test_process_audio_empty_transcription(self, engine: NudgeEngine) -> None:
        mock_result = MagicMock()
        mock_result.text = "  "
        engine._stt.transcribe_bytes = AsyncMock(return_value=mock_result)

        result = await engine.process_audio(b"\x00" * 100)
        assert result.text == ""

    @pytest.mark.asyncio
    async def test_session_logging(self, engine: NudgeEngine) -> None:
        with (
            patch.object(engine._router, "classify", new_callable=AsyncMock) as mock_c,
            patch.object(engine._agent, "run_once", new_callable=AsyncMock) as mock_r,
        ):
            from hive.routing.router import IntentResult

            mock_c.return_value = IntentResult(intent="note", confidence=0.8, raw_text="test")
            mock_r.return_value = "Noted."

            await engine.process_text("remember this")

        log_path = Path(engine.config.log_dir) / "sessions.jsonl"
        assert log_path.exists()
        content = log_path.read_text()
        assert "remember this" in content

    @pytest.mark.asyncio
    async def test_audio_metadata_preserved_in_log(self, engine: NudgeEngine) -> None:
        """Audio-originated sessions must log audio_bytes > 0."""
        mock_transcription = MagicMock()
        mock_transcription.text = "buy milk"
        engine._stt.transcribe_bytes = AsyncMock(return_value=mock_transcription)

        with (
            patch.object(engine._router, "classify", new_callable=AsyncMock) as mock_c,
            patch.object(engine._agent, "run_once", new_callable=AsyncMock) as mock_r,
        ):
            from hive.routing.router import IntentResult

            mock_c.return_value = IntentResult(intent="task", confidence=0.9, raw_text="buy milk")
            mock_r.return_value = "Task created."

            await engine.process_audio(b"\x00" * 3200)

        import json

        log_path = Path(engine.config.log_dir) / "sessions.jsonl"
        entries = [json.loads(line) for line in log_path.read_text().splitlines()]
        assert len(entries) == 1
        assert entries[0]["audio_bytes"] == 3200
        assert entries[0]["text"] == "buy milk"

    def test_get_recent_sessions(self, engine: NudgeEngine) -> None:
        assert engine.get_recent_sessions() == []

    def test_handle_launch_empty(self, engine: NudgeEngine) -> None:
        result = engine._handle_launch("open ")
        assert "Which app" in result

    @pytest.mark.asyncio
    async def test_shutdown(self, engine: NudgeEngine) -> None:
        await engine.shutdown()
