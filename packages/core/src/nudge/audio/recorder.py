"""Recording manager — wraps Hive's AudioRecorder with session lifecycle."""

from __future__ import annotations

import logging
import time
from typing import cast

from hive.stt import AudioRecorder

logger = logging.getLogger(__name__)


class RecordingManager:
    """Manages recording state with min/max duration guards."""

    def __init__(
        self,
        sample_rate: int = 16000,
        min_duration_ms: int = 500,
        max_duration_s: float = 30.0,
    ) -> None:
        self._recorder = AudioRecorder(sample_rate=sample_rate, channels=1)
        self._sample_rate = sample_rate
        self._min_duration_ms = min_duration_ms
        self._max_duration_s = max_duration_s
        self._start_time: float = 0

    @property
    def is_recording(self) -> bool:
        return bool(self._recorder.is_recording)

    @property
    def elapsed_ms(self) -> int:
        if not self._recorder.is_recording:
            return 0
        return int((time.time() - self._start_time) * 1000)

    def start(self) -> None:
        if self._recorder.is_recording:
            return
        self._start_time = time.time()
        self._recorder.start()
        logger.debug("Recording started")

    def stop(self) -> bytes | None:
        """Stop recording. Returns audio bytes or None if too short."""
        if not self._recorder.is_recording:
            return None

        audio = cast(bytes, self._recorder.stop())
        elapsed = int((time.time() - self._start_time) * 1000)
        logger.debug("Recording stopped: %d bytes, %d ms", len(audio), elapsed)

        if elapsed < self._min_duration_ms:
            logger.debug("Too short (%d ms < %d ms), discarding", elapsed, self._min_duration_ms)
            return None

        max_bytes = int(self._max_duration_s * self._sample_rate * 2)
        if len(audio) > max_bytes:
            logger.warning("Recording exceeded max (%.0fs), truncating", self._max_duration_s)
            audio = audio[:max_bytes]

        return audio

    def cancel(self) -> None:
        """Cancel recording without returning audio."""
        if self._recorder.is_recording:
            self._recorder.stop()
            logger.debug("Recording cancelled")
