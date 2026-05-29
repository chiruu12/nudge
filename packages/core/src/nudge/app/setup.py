"""Interactive setup wizard — picks STT, LLM, hotkey. Keys from .env."""

from __future__ import annotations

import os

from dotenv import load_dotenv
from rich.console import Console
from rich.prompt import Prompt

from nudge.core.config import NudgeConfig

console = Console()

_KEY_MAP = {
    "groq": "GROQ_API_KEY",
    "openai": "OPENAI_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "deepgram": "DEEPGRAM_API_KEY",
}


def env_key_set(provider: str) -> bool:
    """True if the provider's API key env var is present (and non-empty)."""
    env_key = _KEY_MAP.get(provider)
    return bool(env_key and os.environ.get(env_key, ""))


def _check_env_key(provider: str) -> None:
    """Check if the required env key exists and report."""
    env_key = _KEY_MAP.get(provider)
    if env_key:
        val = os.environ.get(env_key, "")
        if val:
            console.print(f"    [green]✓[/green] {env_key} found ({val[:8]}...)")
        else:
            console.print(f"    [yellow]⚠[/yellow] {env_key} not set — add it to your .env file")


def _check_whisper() -> None:
    """Check if a whisper backend is installed."""
    try:
        import mlx_whisper  # noqa: F401

        console.print("    [green]✓[/green] mlx-whisper installed")
        return
    except ImportError:
        pass
    try:
        import faster_whisper  # noqa: F401

        console.print("    [green]✓[/green] faster-whisper installed")
        return
    except ImportError:
        pass
    console.print("    [yellow]⚠[/yellow] No whisper backend — pip install mlx-whisper")


def run_setup() -> None:
    """Interactive setup wizard."""
    load_dotenv()
    config = NudgeConfig.load()

    console.print("\n[bold]Nudge Setup[/bold]")
    console.print("[dim]Keys are read from your .env file — we never ask for them.[/dim]\n")

    # ── STT ──────────────────────────────────────────────────────
    console.print("[bold]1. Speech-to-Text[/bold]")
    console.print("   [cyan]groq[/cyan]     — Groq Whisper API (fast cloud)")
    console.print("   [cyan]deepgram[/cyan] — Deepgram Nova-2 (accurate cloud)")
    console.print("   [cyan]whisper[/cyan]  — Local inference (offline, Apple Silicon)")

    stt = Prompt.ask(
        "\n  Provider",
        choices=["groq", "deepgram", "whisper"],
        default=config.stt_provider,
    )
    config.stt_provider = stt

    if stt == "whisper":
        _check_whisper()
    else:
        _check_env_key(stt)

    # ── LLM ──────────────────────────────────────────────────────
    console.print("\n[bold]2. LLM (for the agent)[/bold]")
    console.print("   [cyan]groq[/cyan]      — Fast open-source models")
    console.print("   [cyan]openai[/cyan]    — GPT models")
    console.print("   [cyan]anthropic[/cyan] — Claude models")
    console.print("   [cyan]ollama[/cyan]    — Local inference (Ollama)")
    console.print("   [cyan]lmstudio[/cyan] — Local inference (LM Studio)")

    llm = Prompt.ask(
        "\n  Provider",
        choices=["groq", "openai", "anthropic", "ollama", "lmstudio"],
        default=config.llm_provider,
    )
    config.llm_provider = llm
    _check_env_key(llm)

    # ── Hotkey ───────────────────────────────────────────────────
    console.print(f"\n[bold]3. Hotkey[/bold]  (current: [cyan]{config.hotkey}[/cyan])")
    console.print("   Examples: cmd+shift+n, ctrl+alt+h, cmd+space")

    custom = Prompt.ask(
        "\n  Use default or custom?",
        choices=["default", "custom"],
        default="default",
    )

    if custom == "custom":
        hotkey = Prompt.ask("  Enter key combo", default=config.hotkey)
        config.hotkey = hotkey

    console.print(f"    [green]✓[/green] Hotkey: [cyan]{config.hotkey}[/cyan]")

    # ── Save ─────────────────────────────────────────────────────
    path = config.save()

    console.print(f"\n[green]✓ Saved to {path}[/green]")
    console.print("\n[bold]Commands:[/bold]")
    console.print("  [cyan]nudge[/cyan]          — start voice assistant")
    console.print("  [cyan]nudge test[/cyan]     — quick 2s recording test")
    console.print("  [cyan]nudge config[/cyan]   — show config")
    console.print("  [cyan]nudge history[/cyan]  — recent interactions")
    console.print()
