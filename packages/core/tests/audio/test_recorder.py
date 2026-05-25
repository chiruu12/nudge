"""Tests for RecordingManager."""

from __future__ import annotations

import time
from unittest.mock import MagicMock, patch

from nudge.audio.recorder import RecordingManager

_SD = "hive.stt.recorder.sd"
_HAS = "hive.stt.recorder._HAS_SOUNDDEVICE"


class TestRecordingManager:
    def test_not_recording_initially(self) -> None:
        mock_sd = MagicMock()
        mock_sd.InputStream.return_value = MagicMock()
        with patch(_SD, mock_sd), patch(_HAS, True):
            rec = RecordingManager()
            assert not rec.is_recording

    def test_start_and_stop(self) -> None:
        mock_sd = MagicMock()
        mock_sd.InputStream.return_value = MagicMock()
        with patch(_SD, mock_sd), patch(_HAS, True):
            rec = RecordingManager(min_duration_ms=0)
            rec.start()
            assert rec.is_recording

            rec._recorder._frames = [b"\x00" * 100]
            rec._recorder._recording = True
            # Simulate enough time passed
            rec._start_time = time.time() - 1.0

            audio = rec.stop()
            assert audio is not None
            assert len(audio) > 0

    def test_stop_too_short_returns_none(self) -> None:
        mock_sd = MagicMock()
        mock_sd.InputStream.return_value = MagicMock()
        with patch(_SD, mock_sd), patch(_HAS, True):
            rec = RecordingManager(min_duration_ms=1000)
            rec.start()
            rec._recorder._frames = [b"\x00"]
            rec._recorder._recording = True
            rec._start_time = time.time()

            audio = rec.stop()
            assert audio is None

    def test_cancel(self) -> None:
        mock_sd = MagicMock()
        mock_sd.InputStream.return_value = MagicMock()
        with patch(_SD, mock_sd), patch(_HAS, True):
            rec = RecordingManager()
            rec.start()
            rec._recorder._recording = True
            rec.cancel()

    def test_stop_without_start(self) -> None:
        mock_sd = MagicMock()
        mock_sd.InputStream.return_value = MagicMock()
        with patch(_SD, mock_sd), patch(_HAS, True):
            rec = RecordingManager()
            assert rec.stop() is None
