"""NudgeEngine — the core brain. No UI, no transport, just processing."""

from __future__ import annotations

import json
import logging
import time
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from hive import (
    Agent,
    AlarmChecker,
    AlarmToolkit,
    Instructions,
    KnowledgeToolkit,
    TaskToolkit,
)
from hive.routing import IntentRouter
from hive.stt.base import STTProvider
from hive.tools.clipboard import ClipboardToolkit
from hive.tools.links import LinkToolkit

from nudge.core.config import NudgeConfig
from nudge.core.providers import create_llm, create_router_llm, create_stt
from nudge.core.session import ProcessingResult, VoiceSession

logger = logging.getLogger(__name__)


class NudgeEngine:
    """Core engine: text/audio in → intent classification → agent → result.

    This is the class everything else consumes — CLI, server, GUI, SDK.

    Usage::

        engine = NudgeEngine()
        result = await engine.process_text("add a task to buy milk")
        result = await engine.process_audio(raw_pcm_bytes)
    """

    def __init__(self, config: NudgeConfig | None = None) -> None:
        load_dotenv()
        self._config = config or NudgeConfig.load()
        self._sessions: list[VoiceSession] = []

        data_dir = Path(self._config.data_dir)
        data_dir.mkdir(parents=True, exist_ok=True)
        log_dir = Path(self._config.log_dir)
        log_dir.mkdir(parents=True, exist_ok=True)

        self._log_path = log_dir / "sessions.jsonl"
        db_path = data_dir / "nudge.db"

        self._stt: STTProvider = create_stt(self._config)
        self._router = IntentRouter(
            model=create_router_llm(self._config),
            intents=self._config.intents,
        )

        self._task_tk = TaskToolkit(db_path=db_path)
        self._alarm_tk = AlarmToolkit(db_path=db_path)
        self._knowledge_tk = KnowledgeToolkit(memory_dir=data_dir)
        self._link_tk = LinkToolkit(memory_dir=data_dir)
        self._clipboard_tk = ClipboardToolkit(db_path=db_path, memory_dir=data_dir)

        # Load soul.md for persona customization
        soul_path = Path.home() / ".nudge" / "soul.md"
        persona = "You are Nudge, a helpful voice assistant. Be concise — 1-2 sentences."
        if soul_path.exists():
            persona = (
                soul_path.read_text(encoding="utf-8", errors="replace").strip()
                or "You are Nudge, a helpful voice assistant. Be concise — 1-2 sentences."
            )

        self._agent = Agent(
            name="nudge",
            model=create_llm(self._config),
            instructions=Instructions(
                persona=persona,
                instructions=[
                    "Respond naturally as if speaking to the user.",
                    "Use tools when the user asks to create tasks, set alarms, save notes, etc.",
                    "When copying to clipboard, confirm what was copied.",
                ],
            ),
            toolkits=[
                self._task_tk,
                self._alarm_tk,
                self._knowledge_tk,
                self._link_tk,
                self._clipboard_tk,
            ],
        )

        self._checker = AlarmChecker(
            db_path=db_path,
            notification_title=self._config.notification_title,
        )

    @property
    def config(self) -> NudgeConfig:
        return self._config

    @property
    def stt(self) -> STTProvider:
        return self._stt

    @property
    def checker(self) -> AlarmChecker:
        return self._checker

    # ── Public API ───────────────────────────────────────────────

    async def process_text(self, text: str) -> ProcessingResult:
        """Process a text command. The primary interface for all transports."""
        session = VoiceSession()
        session.set_text(text)
        return await self._run_pipeline(session, text)

    async def process_audio(self, audio: bytes, sample_rate: int = 16000) -> ProcessingResult:
        """Transcribe audio then process as text."""
        session = VoiceSession()
        session.set_audio(audio)
        t0 = time.time()

        try:
            transcription = await self._stt.transcribe_bytes(audio, sample_rate=sample_rate)
            text = transcription.text.strip()

            if not text:
                result = ProcessingResult(
                    text="",
                    response="",
                    duration_ms=int((time.time() - t0) * 1000),
                )
                session.set_result(result)
                self._track_session(session)
                return result

            session.set_text(text)
            return await self._run_pipeline(session, text, t0=t0, from_audio=True)

        except Exception as e:
            logger.error("Audio processing failed: %s", e)
            result = ProcessingResult(
                text="",
                error=str(e),
                duration_ms=int((time.time() - t0) * 1000),
            )
            session.set_result(result)
            self._track_session(session)
            return result

    async def _run_pipeline(
        self,
        session: VoiceSession,
        text: str,
        t0: float | None = None,
        from_audio: bool = False,
    ) -> ProcessingResult:
        """Classify intent and run agent. Logs the given session (preserving audio metadata)."""
        t0 = t0 or time.time()

        try:
            t_stt = time.time()  # after STT

            t_intent_start = time.time()
            intent = await self._router.classify(text)
            t_intent = time.time()

            # Handle launch intent directly — no agent needed
            if intent.intent == "launch":
                response = self._handle_launch(text)
                result = ProcessingResult(
                    text=text,
                    intent=intent.intent,
                    confidence=intent.confidence,
                    response=response,
                    stt_ms=int((t_stt - t0) * 1000) if from_audio else 0,
                    intent_ms=int((t_intent - t_intent_start) * 1000),
                    duration_ms=int((time.time() - t0) * 1000),
                )
                session.set_result(result)
                self._track_session(session)
                return result

            response = await self._agent.run_once(text)
            t_agent = time.time()

            result = ProcessingResult(
                text=text,
                intent=intent.intent,
                confidence=intent.confidence,
                response=response,
                stt_ms=int((t_stt - t0) * 1000) if from_audio else 0,
                intent_ms=int((t_intent - t_intent_start) * 1000),
                agent_ms=int((t_agent - t_intent) * 1000),
                duration_ms=int((t_agent - t0) * 1000),
            )
        except Exception as e:
            logger.error("Processing failed: %s", e)
            result = ProcessingResult(
                text=text,
                error=str(e),
                duration_ms=int((time.time() - t0) * 1000),
            )

        session.set_result(result)
        self._track_session(session)
        return result

    def _handle_launch(self, text: str) -> str:
        """Parse launch command and execute."""
        from nudge.tools.launcher import launch_app

        # Remove common prefixes
        clean = text.lower()
        for prefix in ["open ", "launch ", "start ", "run "]:
            if clean.startswith(prefix):
                clean = clean[len(prefix) :]
                break

        if not clean.strip():
            from nudge.tools.launcher import list_available_apps

            available = list_available_apps()
            if available:
                return f"Which app? Available: {', '.join(available)}"
            return "Which app would you like to open?"

        # Split on "and", "with", "to" to separate app from prompt
        prompt = ""
        for sep in [" and ", " with ", " to "]:
            if sep in clean:
                parts = clean.split(sep, 1)
                clean = parts[0].strip()
                prompt = parts[1].strip()
                break

        return launch_app(clean, prompt)

    async def transcribe(self, audio: bytes, sample_rate: int = 16000) -> str:
        """Transcribe audio without processing. Useful for preview."""
        result = await self._stt.transcribe_bytes(audio, sample_rate=sample_rate)
        return result.text.strip()

    # ── Data access for host apps ────────────────────────────────

    async def get_tasks(self, status: str = "pending") -> list[dict[str, Any]]:
        return await self._task_tk.query_all_tasks(status)

    async def get_alarms(self) -> list[dict[str, Any]]:
        return await self._alarm_tk.query_all_pending_alarms()

    def get_notes(self, limit: int = 20) -> list[dict[str, object]]:
        return self._knowledge_tk.query_recent(limit)

    def get_recent_sessions(self, limit: int = 20) -> list[VoiceSession]:
        return list(reversed(self._sessions[-limit:]))

    # ── Lifecycle ────────────────────────────────────────────────

    async def shutdown(self) -> None:
        """Clean shutdown — close connections, stop checker."""
        await self._checker.stop()
        if hasattr(self._stt, "close") and callable(getattr(self._stt, "close", None)):
            result = self._stt.close()
            if hasattr(result, "__await__"):
                await result

    # ── Logging ──────────────────────────────────────────────────

    _MAX_SESSIONS = 100

    def _track_session(self, session: VoiceSession) -> None:
        """Log to JSONL, release audio buffer, keep in-memory list capped."""
        self._log_session(session)
        session.clear_audio()
        self._sessions.append(session)
        if len(self._sessions) > self._MAX_SESSIONS:
            self._sessions = self._sessions[-self._MAX_SESSIONS :]

    def _log_session(self, session: VoiceSession) -> None:
        try:
            with open(self._log_path, "a") as f:
                f.write(json.dumps(session.to_log_dict()) + "\n")
        except Exception as e:
            logger.debug("Session log failed: %s", e)
