"""Tests for provider validation (real test-call wiring)."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from nudge.app.validate import run_validation


@pytest.mark.asyncio
async def test_stt_validation_awaits_and_fails_on_bad_key() -> None:
    # transcribe_bytes is async; a bad key raises when awaited. The validator
    # must actually await it (regression: a missing await always "passed").
    stt = MagicMock()
    stt.transcribe_bytes = AsyncMock(side_effect=Exception("401 invalid api key"))
    with patch("nudge.app.validate.create_stt", return_value=stt):
        ok, message = await run_validation("deepgram", "stt", "bad-key")
    assert ok is False
    assert "invalid" in message.lower()
    stt.transcribe_bytes.assert_awaited_once()


@pytest.mark.asyncio
async def test_stt_validation_succeeds_on_good_key() -> None:
    stt = MagicMock()
    stt.transcribe_bytes = AsyncMock(return_value=MagicMock(text=""))
    with patch("nudge.app.validate.create_stt", return_value=stt):
        ok, message = await run_validation("deepgram", "stt", "good-key")
    assert ok is True
    assert "deepgram" in message


@pytest.mark.asyncio
async def test_llm_validation_uses_explicit_key() -> None:
    llm = MagicMock()
    llm.generate_with_metadata = AsyncMock(return_value=MagicMock())
    fake_cls = MagicMock(return_value=llm)
    # Patch the provider class so the explicit-key path constructs with the key.
    with patch.dict("nudge.core.providers._PROVIDERS", {"groq": "fake.mod:Groq"}, clear=False):
        with patch("importlib.import_module", return_value=MagicMock(Groq=fake_cls)):
            ok, _ = await run_validation("groq", "llm", "test-key")
    assert ok is True
    fake_cls.assert_called_once_with(api_key="test-key")
    llm.generate_with_metadata.assert_awaited_once()
