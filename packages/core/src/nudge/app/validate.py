"""Validate a provider/API key with a real, minimal test call."""

from __future__ import annotations

import os

from nudge.core.config import NudgeConfig
from nudge.core.engine import _sanitize_error
from nudge.core.providers import create_llm, create_stt

# Provider -> env var (mirrors app/setup.py _KEY_MAP).
_KEY_MAP = {
    "groq": "GROQ_API_KEY",
    "openai": "OPENAI_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "deepgram": "DEEPGRAM_API_KEY",
}

# 0.1s of 16-bit silence at 16 kHz — enough for an STT key/auth probe.
_SILENT_PCM = b"\x00\x00" * 1600


async def run_validation(provider: str, kind: str, api_key: str | None = None) -> tuple[bool, str]:
    """Run a minimal real call against a provider. Returns (ok, message).

    A supplied ``api_key`` is used for the test without mutating the running
    server's environment. Never raises — callers get a friendly message.
    """
    try:
        if kind == "llm":
            return await _validate_llm(provider, api_key)
        if kind == "stt":
            return await _validate_stt(provider, api_key)
        return False, f"Unknown validation kind: {kind!r}"
    except Exception as e:  # noqa: BLE001 — surface a friendly message, never 500
        return False, _friendly_error(provider, e)


def _friendly_error(provider: str, exc: Exception) -> str:
    """Map a raw provider exception to a short, user-facing message.

    Never returns raw JSON / stack detail — just a clean hint.
    """
    raw = _sanitize_error(str(exc)).lower()
    if any(s in raw for s in ("401", "invalid api key", "incorrect api key", "unauthorized")):
        return f"That {provider} API key is invalid."
    if any(s in raw for s in ("403", "permission", "forbidden")):
        return f"This key isn't authorized for {provider}."
    if any(s in raw for s in ("429", "rate limit", "quota", "insufficient")):
        return f"{provider} rejected the request (rate limit or quota). Try again later."
    if any(s in raw for s in ("connect", "timed out", "timeout", "resolve", "network", "refused")):
        return f"Couldn't reach {provider}. Check your internet connection."
    if any(s in raw for s in ("404", "model", "not found")):
        return f"Reached {provider}, but the request failed — check the provider/model."
    return f"Couldn't validate {provider}. Double-check the key and try again."


async def _validate_llm(provider: str, api_key: str | None) -> tuple[bool, str]:
    import importlib

    from hive.runtime.types import Message, Role

    from nudge.core.providers import _PROVIDERS

    # When a key is supplied, construct the provider with it directly so the
    # test actually exercises THAT key (hive resolves env/.env keys otherwise,
    # which would mask a bad key). With no key, fall back to the saved config.
    if api_key:
        if provider not in _PROVIDERS:
            return False, f"Unknown LLM provider: {provider}"
        module_path, class_name = _PROVIDERS[provider].rsplit(":", 1)
        cls = getattr(importlib.import_module(module_path), class_name)
        llm = cls(api_key=api_key)
    else:
        llm = create_llm(NudgeConfig(llm_provider=provider))

    await llm.generate_with_metadata([Message(role=Role.USER, content="ping")], max_tokens=1)
    return True, f"{provider} LLM connected"


async def _validate_stt(provider: str, api_key: str | None) -> tuple[bool, str]:
    # STT providers read their key from the environment; set it for the test
    # and restore the previous value so a bad key doesn't pollute the server.
    env_var = _KEY_MAP.get(provider)
    previous = os.environ.get(env_var) if env_var else None
    try:
        if api_key and env_var:
            os.environ[env_var] = api_key
        cfg = NudgeConfig(stt_provider=provider)
        stt = create_stt(cfg)
        # A real transcribe of silence: invalid keys raise here; local backends
        # return empty text. Either non-error outcome means the provider works.
        # Must be awaited — transcribe_bytes is async; without await the call
        # never runs and an invalid key would falsely pass.
        await stt.transcribe_bytes(_SILENT_PCM, sample_rate=16000)
        return True, f"{provider} STT connected"
    finally:
        if env_var:
            if previous is None:
                os.environ.pop(env_var, None)
            else:
                os.environ[env_var] = previous
