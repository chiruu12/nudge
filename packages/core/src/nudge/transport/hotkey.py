"""Hotkey transport — toggle recording with a keyboard shortcut."""

from __future__ import annotations

import logging

from hive.triggers import HotkeyTrigger

from nudge.audio.recorder import RecordingManager
from nudge.core.engine import NudgeEngine

logger = logging.getLogger(__name__)


class HotkeyTransport:
    """Bridges hotkey presses to the NudgeEngine."""

    def __init__(
        self,
        engine: NudgeEngine,
        hotkey: str = "cmd+shift+n",
        on_result: object = None,
    ) -> None:
        self._engine = engine
        self._hotkey = hotkey
        self._on_result = on_result
        self._recorder = RecordingManager(
            sample_rate=engine.config.sample_rate,
        )
        self._trigger = HotkeyTrigger()
        self._processing = False

    def start(self) -> None:
        self._trigger.register(self._hotkey, self._toggle, name="nudge-toggle")
        self._trigger.start()

    def stop(self) -> None:
        self._trigger.stop()
        if self._recorder.is_recording:
            self._recorder.cancel()

    async def _toggle(self) -> None:
        if self._processing:
            return
        if self._recorder.is_recording:
            await self._stop_and_process()
        else:
            self._recorder.start()
            if self._on_result and hasattr(self._on_result, "on_recording_start"):
                self._on_result.on_recording_start()

    async def _stop_and_process(self) -> None:
        audio = self._recorder.stop()
        if audio is None:
            return

        self._processing = True
        if self._on_result and hasattr(self._on_result, "on_processing_start"):
            self._on_result.on_processing_start()

        try:
            result = await self._engine.process_audio(
                audio, sample_rate=self._engine.config.sample_rate
            )
            if self._on_result and hasattr(self._on_result, "on_result"):
                self._on_result.on_result(result)
        except Exception as e:
            logger.error("Processing error: %s", e)
        finally:
            self._processing = False
