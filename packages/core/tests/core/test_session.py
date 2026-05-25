"""Tests for VoiceSession and ProcessingResult."""

from __future__ import annotations

from nudge.core.session import ProcessingResult, VoiceSession


class TestProcessingResult:
    def test_ok_when_no_error(self) -> None:
        r = ProcessingResult(text="hello", response="hi there")
        assert r.ok

    def test_not_ok_when_error(self) -> None:
        r = ProcessingResult(text="", error="something broke")
        assert not r.ok

    def test_serialization(self) -> None:
        r = ProcessingResult(
            text="buy milk",
            intent="task",
            confidence=0.9,
            response="Task created.",
            duration_ms=150,
        )
        d = r.model_dump()
        assert d["intent"] == "task"
        assert d["confidence"] == 0.9

    def test_defaults(self) -> None:
        r = ProcessingResult(text="test")
        assert r.intent == ""
        assert r.confidence == 0.0
        assert r.duration_ms == 0
        assert r.timestamp != ""

    def test_timing_field_defaults(self) -> None:
        r = ProcessingResult(text="test")
        assert r.stt_ms == 0
        assert r.intent_ms == 0
        assert r.agent_ms == 0

    def test_timing_fields_serialization(self) -> None:
        r = ProcessingResult(
            text="hello",
            stt_ms=50,
            intent_ms=30,
            agent_ms=120,
            duration_ms=200,
        )
        d = r.model_dump()
        assert d["stt_ms"] == 50
        assert d["intent_ms"] == 30
        assert d["agent_ms"] == 120


class TestVoiceSession:
    def test_lifecycle(self) -> None:
        s = VoiceSession()
        assert not s.has_audio
        assert not s.has_text
        assert s.result is None

        s.set_audio(b"\x00" * 100)
        assert s.has_audio

        s.set_text("hello world")
        assert s.has_text

        r = ProcessingResult(text="hello", response="hi")
        s.set_result(r)
        assert s.result is not None
        assert s.result.response == "hi"

    def test_to_log_dict(self) -> None:
        s = VoiceSession(session_id="test-123")
        s.set_audio(b"\x00" * 50)
        s.set_text("test")
        s.set_result(ProcessingResult(text="test", response="ok"))

        d = s.to_log_dict()
        assert d["session_id"] == "test-123"
        assert d["audio_bytes"] == 50
        assert d["text"] == "test"
        assert d["result"]["response"] == "ok"
