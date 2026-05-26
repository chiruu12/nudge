"""Tests for CLI command cleanup behavior."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

from typer.testing import CliRunner

from nudge.transport.cli import app


class TestQuickTest:
    def test_short_recording_still_shuts_down_engine(self) -> None:
        engine = MagicMock()
        engine.shutdown = AsyncMock()
        recorder = MagicMock()
        recorder.stop.return_value = None
        config = MagicMock(sample_rate=16000)

        with (
            patch("nudge.core.config.NudgeConfig.load", return_value=config),
            patch("nudge.core.engine.NudgeEngine", return_value=engine),
            patch("nudge.audio.recorder.RecordingManager", return_value=recorder),
            patch("nudge.transport.cli.asyncio.sleep", new=AsyncMock()),
        ):
            result = CliRunner().invoke(app, ["test"])

        assert result.exit_code == 0
        engine.shutdown.assert_awaited_once()
