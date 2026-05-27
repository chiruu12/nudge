"""Provider registry — build STT and LLM providers from config."""

from __future__ import annotations

import time
from typing import Any

from hive.models.base import BaseProvider
from hive.models.openai import OpenAI as HiveOpenAI
from hive.models.registry import estimate_cost
from hive.runtime.types import GenerateResult, Message
from hive.stt.base import STTProvider

from nudge.core.config import NudgeConfig


class OpenAICompat(HiveOpenAI):
    """OpenAI wrapper that uses max_completion_tokens for GPT-5+ models."""

    async def generate_with_metadata(
        self,
        messages: list[Message],
        tools: list[dict[str, Any]] | None = None,
        temperature: float = 0.0,
        max_tokens: int = 4096,
    ) -> GenerateResult:
        if not self._model.startswith("gpt-5"):
            return await super().generate_with_metadata(messages, tools, temperature, max_tokens)

        api_messages = self._messages_to_openai(messages)
        t0 = time.time()

        kwargs: dict[str, Any] = {
            "model": self._model,
            "messages": api_messages,
            "max_completion_tokens": max_tokens,
            "temperature": temperature,
        }
        if tools:
            kwargs["tools"] = self._tools_to_openai(tools)

        response = await self._retry_with_backoff(self._client.chat.completions.create, **kwargs)
        duration_ms = int((time.time() - t0) * 1000)

        input_tokens = (response.usage.prompt_tokens or 0) if response.usage else 0
        output_tokens = (response.usage.completion_tokens or 0) if response.usage else 0
        cost = estimate_cost(self._model, input_tokens, output_tokens)

        return GenerateResult(
            message=self._response_to_message(response),
            model=self._model,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            cost_usd=cost,
            duration_ms=duration_ms,
        )


def create_stt(config: NudgeConfig) -> STTProvider:
    """Create the STT provider from config. Keys come from env."""
    from hive.stt import create_stt_provider

    return create_stt_provider(config.stt_provider)


def create_llm(config: NudgeConfig) -> BaseProvider:
    """Create the main LLM provider (for the agent)."""
    return _get_provider(config.llm_provider, config.llm_tier)


def create_router_llm(config: NudgeConfig) -> BaseProvider:
    """Create a lighter LLM for intent classification."""
    return _get_provider(config.llm_provider, "lite")


_PROVIDERS: dict[str, str] = {
    "groq": "hive.models.groq:Groq",
    "openai": "nudge.core.providers:OpenAICompat",
    "anthropic": "hive.models.anthropic:Anthropic",
    "fireworks": "hive.models.fireworks:Fireworks",
    "ollama": "hive.models.ollama:Ollama",
    "lmstudio": "hive.models.lmstudio:LMStudio",
}


def _get_provider(name: str, tier: str) -> BaseProvider:
    if name not in _PROVIDERS:
        raise ValueError(f"Unknown LLM provider: {name!r}. Available: {list(_PROVIDERS)}")

    module_path, class_name = _PROVIDERS[name].rsplit(":", 1)

    try:
        import importlib

        module = importlib.import_module(module_path)
    except ImportError:
        raise ValueError(
            f"Provider {name!r} requires the hive-agent package. "
            f"Install it: pip install 'hive-agent>=0.4.1'"
        ) from None

    cls = getattr(module, class_name)

    if not hasattr(cls, tier):
        raise ValueError(f"Unknown tier {tier!r} for provider {name!r}. Try: lite, standard, pro")

    return getattr(cls, tier)()
