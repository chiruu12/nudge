"""Voice session — lifecycle of a single voice interaction."""

from __future__ import annotations

import logging
from datetime import UTC, datetime

from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)


class ProcessingResult(BaseModel):
    """Result of processing a voice command or text input."""

    text: str
    intent: str = ""
    confidence: float = 0.0
    response: str = ""
    error: str = ""
    duration_ms: int = 0
    stt_ms: int = 0
    intent_ms: int = 0
    agent_ms: int = 0
    timestamp: str = Field(default_factory=lambda: datetime.now(UTC).isoformat())

    @property
    def ok(self) -> bool:
        return self.error == ""


class VoiceSession:
    """Manages the state of a single voice interaction.

    Lifecycle: start_recording → stop_recording → process → result
    """

    def __init__(self, session_id: str = "") -> None:
        self.session_id = session_id or datetime.now(UTC).strftime("%Y%m%d_%H%M%S")
        self._audio: bytes = b""
        self._text: str = ""
        self._result: ProcessingResult | None = None

    @property
    def has_audio(self) -> bool:
        return len(self._audio) > 0

    @property
    def has_text(self) -> bool:
        return self._text != ""

    @property
    def result(self) -> ProcessingResult | None:
        return self._result

    def set_audio(self, audio: bytes) -> None:
        self._audio = audio

    def set_text(self, text: str) -> None:
        self._text = text

    def set_result(self, result: ProcessingResult) -> None:
        self._result = result

    def clear_audio(self) -> None:
        """Release audio buffer after logging to save memory."""
        self._audio = b""

    def to_log_dict(self) -> dict[str, object]:
        return {
            "session_id": self.session_id,
            "audio_bytes": len(self._audio),
            "text": self._text,
            "result": self._result.model_dump() if self._result else None,
        }
