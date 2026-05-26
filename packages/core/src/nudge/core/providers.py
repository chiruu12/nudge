"""Provider registry — build STT and LLM providers from config."""

from __future__ import annotations

from hive.models.base import BaseProvider
from hive.stt.base import STTProvider

from nudge.core.config import NudgeConfig


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


_PROVIDERS = {
    "groq": "hive.models.groq:Groq",
    "openai": "hive.models.openai:OpenAI",
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
