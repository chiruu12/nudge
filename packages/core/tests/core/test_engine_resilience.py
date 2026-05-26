"""Tests for engine resilience — timeouts, provider failures, error enrichment."""

from __future__ import annotations

import asyncio
import json
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
        stt_timeout_s=0.1,
        intent_timeout_s=0.1,
        agent_timeout_s=0.1,
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
        mock_llm.return_value = mock_provider
        mock_router_llm.return_value = mock_provider

        return NudgeEngine(config)


async def _hang_forever(*args, **kwargs):
    await asyncio.sleep(999)


class TestTimeouts:
    @pytest.mark.asyncio
    async def test_stt_timeout_returns_error(self, engine: NudgeEngine) -> None:
        engine._stt.transcribe_bytes = _hang_forever

        result = await engine.process_audio(b"\x00" * 100)

        assert not result.ok
        assert "timed out" in result.error.lower()
        assert result.error_type == "timeout"
        assert result.error_source == "stt"

    @pytest.mark.asyncio
    async def test_intent_timeout_returns_error(self, engine: NudgeEngine) -> None:
        with patch.object(engine._router, "classify", side_effect=_hang_forever):
            result = await engine.process_text("buy milk")

        assert not result.ok
        assert "timed out" in result.error.lower()
        assert result.error_type == "timeout"
        assert result.error_source == "intent"

    @pytest.mark.asyncio
    async def test_agent_timeout_returns_error(self, engine: NudgeEngine) -> None:
        from hive.routing.router import IntentResult

        with (
            patch.object(
                engine._router,
                "classify",
                new_callable=AsyncMock,
                return_value=IntentResult(intent="task", confidence=0.9, raw_text="buy milk"),
            ),
            patch.object(engine._agent, "run_once", side_effect=_hang_forever),
        ):
            result = await engine.process_text("buy milk")

        assert not result.ok
        assert "timed out" in result.error.lower()
        assert result.error_type == "timeout"
        assert result.error_source == "agent"


class TestProviderFailures:
    @pytest.mark.asyncio
    async def test_stt_exception_returns_error(self, engine: NudgeEngine) -> None:
        engine._stt.transcribe_bytes = AsyncMock(side_effect=ConnectionError("refused"))

        result = await engine.process_audio(b"\x00" * 100)

        assert not result.ok
        assert "refused" in result.error
        assert result.error_type == "provider"
        assert result.error_source == "stt"

    @pytest.mark.asyncio
    async def test_pipeline_exception_returns_error(self, engine: NudgeEngine) -> None:
        with patch.object(engine._router, "classify", side_effect=RuntimeError("model error")):
            result = await engine.process_text("test")

        assert not result.ok
        assert "model error" in result.error
        assert result.error_type == "provider"
        assert result.error_source == "intent"


class TestErrorEnrichment:
    @pytest.mark.asyncio
    async def test_error_result_has_provider_name(self, engine: NudgeEngine) -> None:
        with patch.object(engine._router, "classify", side_effect=Exception("fail")):
            result = await engine.process_text("test")

        assert result.provider_name == "groq"

    @pytest.mark.asyncio
    async def test_error_result_has_session_id(self, engine: NudgeEngine) -> None:
        with patch.object(engine._router, "classify", side_effect=Exception("fail")):
            result = await engine.process_text("test")

        assert result.session_id != ""
        assert len(result.session_id) == 12

    @pytest.mark.asyncio
    async def test_success_result_has_session_id(self, engine: NudgeEngine) -> None:
        from hive.routing.router import IntentResult

        with (
            patch.object(
                engine._router,
                "classify",
                new_callable=AsyncMock,
                return_value=IntentResult(intent="task", confidence=0.9, raw_text="test"),
            ),
            patch.object(engine._agent, "run_once", new_callable=AsyncMock, return_value="Done."),
        ):
            result = await engine.process_text("test")

        assert result.ok
        assert result.session_id != ""
        assert result.provider_name == "groq"

    @pytest.mark.asyncio
    async def test_session_logged_on_error(self, engine: NudgeEngine) -> None:
        with patch.object(engine._router, "classify", side_effect=Exception("boom")):
            await engine.process_text("test")

        log_path = Path(engine.config.log_dir) / "sessions.jsonl"
        assert log_path.exists()
        entries = [json.loads(line) for line in log_path.read_text().splitlines()]
        assert len(entries) == 1
        result_data = entries[0]["result"]
        assert result_data["error"] == "boom"
        assert result_data["error_type"] == "provider"
