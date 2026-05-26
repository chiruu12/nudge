"""Nudge CLI — the terminal interface."""

from __future__ import annotations

import asyncio
import os
from pathlib import Path

import typer
from rich.console import Console

app = typer.Typer(
    help="Nudge — voice assistant. Press a hotkey, speak, get things done.",
)
console = Console()

_DEFAULT_SOUL = """# Soul — Nudge's Context About You

## Who You Are

name:
role:
timezone:

## How You Work

- Add your preferences here

## Things Nudge Should Know

- Add context about your projects, work style, etc.
"""


def _print_actionable_error(error: str) -> None:
    err = error.lower()
    if "timed out" in err or "timeout" in err:
        console.print(
            "  [red]✗[/red] Provider timed out. "
            "Try: [cyan]nudge preset fast[/cyan] or check your internet"
        )
    elif "api key" in err or "authentication" in err or "unauthorized" in err:
        console.print("  [red]✗[/red] API key issue. Run: [cyan]nudge setup[/cyan]")
    elif "connection" in err or "connect" in err:
        console.print("  [red]✗[/red] Can't reach provider. Try: [cyan]nudge preset offline[/cyan]")
    else:
        console.print(f"  [red]✗ {error}[/red]")


soul_app = typer.Typer(help="Manage your soul.md — personalize Nudge.")


@soul_app.command()
def show():
    """Display your current soul.md."""
    soul_path = Path.home() / ".nudge" / "soul.md"
    if not soul_path.exists():
        console.print(
            "\n  [dim]No soul.md yet. Run [cyan]nudge soul edit[/cyan] to create one.[/dim]\n"
        )
        return
    console.print(f"\n[bold]Soul[/bold] ({soul_path})\n")
    console.print(soul_path.read_text())


@soul_app.command()
def edit():
    """Open soul.md in your editor."""
    import subprocess

    soul_path = Path.home() / ".nudge" / "soul.md"
    soul_path.parent.mkdir(parents=True, exist_ok=True)
    if not soul_path.exists():
        soul_path.write_text(_DEFAULT_SOUL)
    editor = os.environ.get("EDITOR", "nano")
    try:
        subprocess.run([editor, str(soul_path)], check=True)
    except FileNotFoundError:
        console.print(
            f"\n  [red]Editor '{editor}' not found.[/red] Set your EDITOR env variable.\n"
        )
    except subprocess.CalledProcessError:
        console.print("\n  [yellow]Editor exited with an error.[/yellow]\n")


app.add_typer(soul_app, name="soul")

links_app = typer.Typer(help="Manage named links — save, open, copy URLs by name.")


def _links_path() -> Path:
    from nudge.core.config import NudgeConfig

    return Path(NudgeConfig.load().data_dir) / "links.json"


@links_app.command()
def add(name: str, url: str) -> None:
    """Save a named link. Example: nudge links add LinkedIn https://linkedin.com/in/me"""
    from nudge.tools.named_links import save_link

    result = save_link(name, url, _links_path())
    console.print(f"\n  {result}\n")


@links_app.command("list")
def list_cmd() -> None:
    """Show all saved links."""
    from nudge.tools.named_links import list_links

    result = list_links(_links_path())
    console.print(f"\n{result}\n")


@links_app.command()
def remove(name: str) -> None:
    """Remove a named link."""
    from nudge.tools.named_links import remove_link

    result = remove_link(name, _links_path())
    console.print(f"\n  {result}\n")


app.add_typer(links_app, name="links")


@app.callback(invoke_without_command=True)
def default(ctx: typer.Context) -> None:
    """Start Nudge. Press your hotkey to record, press again to stop."""
    if ctx.invoked_subcommand is not None:
        return

    from nudge.core.config import NudgeConfig
    from nudge.core.engine import NudgeEngine
    from nudge.core.logging import setup_logging
    from nudge.transport.hotkey import HotkeyTransport

    config = NudgeConfig.load()
    setup_logging()
    engine = NudgeEngine(config)

    class CLIHandler:
        def on_recording_start(self) -> None:
            console.print("  [bold red]● Recording...[/bold red] (press hotkey to stop)")

        def on_processing_start(self) -> None:
            console.print("  [dim]Processing...[/dim]")

        def on_result(self, result: object) -> None:
            from nudge.core.session import ProcessingResult

            if isinstance(result, ProcessingResult):
                separator = "[dim]─────────────────────────────────────[/dim]"
                console.print(f"  {separator}")

                if result.text:
                    console.print(f"  [cyan]You:[/cyan] {result.text}")
                    console.print()

                # Pipeline stage visualization
                total = result.duration_ms or 1  # avoid division by zero
                stages: list[tuple[str, int, str]] = []
                if result.stt_ms:
                    stages.append(("STT", result.stt_ms, "transcribed"))
                if result.intent_ms:
                    label = (
                        f"{result.intent} ({result.confidence:.0%})"
                        if result.intent
                        else "classified"
                    )
                    stages.append(("Intent", result.intent_ms, label))
                if result.agent_ms:
                    detail = result.response[:30] if result.response else "done"
                    stages.append(("Agent", result.agent_ms, detail))

                for name, ms, detail in stages:
                    filled = round((ms / total) * 10)
                    filled = max(1, min(10, filled))
                    bar = "█" * filled + "░" * (10 - filled)
                    console.print(
                        f"  [cyan]●[/cyan] {name:<6} [bold]{ms:>4}ms[/bold]  "
                        f"[cyan]{bar}[/cyan]  [dim]{detail}[/dim]"
                    )

                console.print(f"  {separator}")

                if result.error:
                    _print_actionable_error(result.error)
                elif result.response:
                    console.print(
                        f"  [green]✓[/green] {result.response}  [dim]{result.duration_ms}ms[/dim]"
                    )

                console.print(f"  {separator}")

    transport = HotkeyTransport(engine, hotkey=config.hotkey, on_result=CLIHandler())

    async def _run() -> None:
        checker_task = asyncio.create_task(engine.checker.run_forever())
        transport.start()

        console.print(f"\n[bold]Nudge[/bold] v{__import__('nudge').__version__}")
        console.print(f"  Hotkey:  [cyan]{config.hotkey}[/cyan]")
        console.print(f"  STT:     {config.stt_provider}")
        console.print(f"  LLM:     {config.llm_provider} ({config.llm_tier})")
        console.print(f"  Data:    {config.data_dir}")
        console.print(f"  Logs:    {config.log_dir}")
        console.print("  Press [cyan]Ctrl+C[/cyan] to quit\n")

        try:
            while True:
                await asyncio.sleep(1)
        except (KeyboardInterrupt, asyncio.CancelledError):
            pass
        finally:
            transport.stop()
            checker_task.cancel()
            await engine.shutdown()
            console.print("\n[dim]Bye![/dim]")

    asyncio.run(_run())


@app.command()
def setup() -> None:
    """Interactive setup — pick your STT provider, LLM, and hotkey."""
    from nudge.app.setup import run_setup

    run_setup()


@app.command()
def config() -> None:
    """Show current configuration."""
    from nudge.core.config import CONFIG_FILE, NudgeConfig

    cfg = NudgeConfig.load()

    console.print(f"\n[bold]Config[/bold] ({CONFIG_FILE})\n")
    for k, v in cfg.model_dump().items():
        if isinstance(v, dict):
            console.print(f"  [cyan]{k}[/cyan]:")
            for ik, iv in v.items():
                console.print(f"    {ik}: {iv}")
        else:
            console.print(f"  [cyan]{k}[/cyan]: {v}")
    console.print()


@app.command()
def test() -> None:
    """Quick test — record 2 seconds, transcribe, classify intent."""
    from dotenv import load_dotenv

    load_dotenv()

    from nudge.audio.recorder import RecordingManager
    from nudge.core.config import NudgeConfig
    from nudge.core.engine import NudgeEngine

    cfg = NudgeConfig.load()

    async def _test() -> None:
        engine = NudgeEngine(cfg)
        try:
            rec = RecordingManager(sample_rate=cfg.sample_rate)

            console.print("\n[bold]Nudge Test[/bold]")
            console.print(f"  STT: {engine.stt.__class__.__name__}")

            console.print("  [red]● Recording 2 seconds...[/red]")
            rec.start()
            await asyncio.sleep(2)
            audio = rec.stop()

            if audio is None:
                console.print("  [yellow]Too short[/yellow]")
                return

            console.print(f"  Captured {len(audio)} bytes")

            result = await engine.process_audio(audio, sample_rate=cfg.sample_rate)

            separator = "[dim]─────────────────────────────────────[/dim]"
            console.print(f"  {separator}")
            console.print(f"  [cyan]You:[/cyan] {result.text!r}")
            console.print()

            # Pipeline stage visualization
            total = result.duration_ms or 1
            stages: list[tuple[str, int, str]] = []
            if result.stt_ms:
                stages.append(("STT", result.stt_ms, "transcribed"))
            if result.intent_ms:
                label = (
                    f"{result.intent} ({result.confidence:.0%})" if result.intent else "classified"
                )
                stages.append(("Intent", result.intent_ms, label))
            if result.agent_ms:
                detail = result.response[:30] if result.response else "done"
                stages.append(("Agent", result.agent_ms, detail))

            for name, ms, detail in stages:
                filled = round((ms / total) * 10)
                filled = max(1, min(10, filled))
                bar = "█" * filled + "░" * (10 - filled)
                console.print(
                    f"  [cyan]●[/cyan] {name:<6} [bold]{ms:>4}ms[/bold]  "
                    f"[cyan]{bar}[/cyan]  [dim]{detail}[/dim]"
                )

            console.print(f"  {separator}")

            if result.error:
                _print_actionable_error(result.error)
            elif result.response:
                console.print(
                    f"  [green]✓[/green] {result.response}  [dim]{result.duration_ms}ms[/dim]"
                )

            console.print(f"  {separator}")

            if not result.error:
                console.print("\n  [green]All systems working![/green]\n")
        finally:
            await engine.shutdown()

    asyncio.run(_test())


@app.command()
def preset(name: str) -> None:
    """Load a preset config (default/fast/offline) and save as active."""
    from nudge.core.config import NudgeConfig

    try:
        cfg = NudgeConfig.from_preset(name)
        path = cfg.save()
        console.print(f"\n[green]✓[/green] Loaded preset [cyan]{name}[/cyan] → {path}\n")
    except FileNotFoundError:
        console.print(
            f"\n[red]✗[/red] Preset [cyan]{name}[/cyan] not found."
            " Available: default, fast, offline\n"
        )
        raise typer.Exit(1)


@app.command()
def serve(host: str = "127.0.0.1", port: int = 8000) -> None:
    """Start the Nudge HTTP server."""
    import uvicorn

    from nudge.transport.server import create_app

    server_app = create_app()
    console.print(f"\n[bold]Nudge Server[/bold] — http://{host}:{port}")
    console.print(
        "  /health, /api/process, /api/transcribe, /api/tasks, /api/alarms, /api/history\n"
    )
    uvicorn.run(server_app, host=host, port=port, log_level="warning")


@app.command()
def history(limit: int = 10) -> None:
    """Show recent voice interactions."""
    from nudge.core.config import LOG_DIR
    from nudge.storage.history import load_history

    entries = load_history(LOG_DIR / "sessions.jsonl", limit=limit)

    if not entries:
        console.print("\n  [dim]No history yet. Run [cyan]nudge[/cyan] and talk![/dim]\n")
        return

    console.print(f"\n[bold]Recent Sessions[/bold] ({len(entries)})\n")
    for e in entries:
        raw_result = e.get("result")
        result = raw_result if isinstance(raw_result, dict) else {}
        text = str(result.get("text") or e.get("text") or "")
        response = str(result.get("response") or "")
        intent = str(result.get("intent") or "")
        ts = str(result.get("timestamp") or "")[:19]
        if text:
            console.print(f"  [dim]{ts}[/dim] [cyan]{text}[/cyan]")
            if intent:
                console.print(f"    [{intent}] {response[:80]}")
    console.print()


if __name__ == "__main__":
    app()
