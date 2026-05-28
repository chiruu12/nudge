"""Server transport — expose NudgeEngine over HTTP."""

from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager
from importlib.metadata import version as pkg_version

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator

from nudge.core.config import NudgeConfig
from nudge.core.engine import NudgeEngine
from nudge.core.logging import setup_logging

logger = logging.getLogger(__name__)

MAX_UPLOAD_BYTES = 10 * 1024 * 1024
LOCAL_WEB_ORIGINS = [
    "http://localhost",
    "http://localhost:3000",
    "http://127.0.0.1",
    "http://127.0.0.1:3000",
]


class TextInput(BaseModel):
    text: str

    @field_validator("text")
    @classmethod
    def not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("text must not be empty")
        return v


class TaskUpdate(BaseModel):
    description: str = ""
    priority: str = ""
    due: str = ""


class NoteUpdate(BaseModel):
    content: str = ""
    tags: str = ""


def create_app() -> FastAPI:
    """Factory — creates a configured FastAPI app with NudgeEngine."""

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        setup_logging()
        config = NudgeConfig.load()
        engine = NudgeEngine(config)
        app.state.engine = engine
        checker_task = asyncio.create_task(engine.checker.run_forever())
        yield
        checker_task.cancel()
        try:
            await checker_task
        except asyncio.CancelledError:
            pass
        await engine.shutdown()

    server = FastAPI(title="Nudge", version=pkg_version("nudge-ai"), lifespan=lifespan)
    server.add_middleware(
        CORSMiddleware,
        allow_origins=LOCAL_WEB_ORIGINS,
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["Content-Type"],
    )

    @server.get("/health")
    async def health():
        return {"status": "ok", "version": pkg_version("nudge-ai")}

    @server.get("/api/config")
    async def get_config():
        cfg = server.state.engine.config
        return {
            "stt_provider": cfg.stt_provider,
            "llm_provider": cfg.llm_provider,
            "llm_tier": cfg.llm_tier,
            "hotkey": cfg.hotkey,
            "version": pkg_version("nudge-ai"),
        }

    @server.post("/api/process")
    async def process_text(body: TextInput):
        max_len = server.state.engine.config.max_text_length
        if len(body.text) > max_len:
            raise HTTPException(status_code=422, detail=f"Text too long (max {max_len} chars)")
        result = await server.state.engine.process_text(body.text)
        return result.model_dump()

    @server.post("/api/transcribe")
    async def transcribe_audio(file: UploadFile = File(...), sample_rate: int = 16000):
        audio_bytes = await file.read(MAX_UPLOAD_BYTES + 1)
        if len(audio_bytes) > MAX_UPLOAD_BYTES:
            raise HTTPException(status_code=413, detail="Audio file too large (max 10 MB)")
        if not audio_bytes:
            raise HTTPException(status_code=422, detail="Empty audio file")
        try:
            text = await server.state.engine.transcribe(audio_bytes, sample_rate=sample_rate)
        except Exception:
            logger.exception("Transcription failed")
            raise HTTPException(status_code=500, detail="Transcription failed. Please try again.")
        return {"text": text}

    @server.post("/api/process-audio")
    async def process_audio(file: UploadFile = File(...), sample_rate: int = 16000):
        audio_bytes = await file.read(MAX_UPLOAD_BYTES + 1)
        if len(audio_bytes) > MAX_UPLOAD_BYTES:
            raise HTTPException(status_code=413, detail="Audio file too large (max 10 MB)")
        if not audio_bytes:
            raise HTTPException(status_code=422, detail="Empty audio file")
        try:
            result = await server.state.engine.process_audio(audio_bytes, sample_rate=sample_rate)
        except Exception:
            logger.exception("Audio processing failed")
            raise HTTPException(
                status_code=500, detail="Audio processing failed. Please try again."
            )
        return result.model_dump()

    # ── Tasks ─────────────────────────────────────────────────

    @server.get("/api/tasks")
    async def list_tasks(status: str = "pending"):
        return await server.state.engine.get_tasks(status=status)

    @server.post("/api/tasks/{task_id}/complete")
    async def complete_task(task_id: str):
        result = await server.state.engine.complete_task(task_id)
        return {"message": result}

    @server.post("/api/tasks/{task_id}/uncomplete")
    async def uncomplete_task(task_id: str):
        result = await server.state.engine.uncomplete_task(task_id)
        return {"message": result}

    @server.put("/api/tasks/{task_id}")
    async def update_task(task_id: str, body: TaskUpdate):
        result = await server.state.engine.update_task(
            task_id,
            description=body.description,
            priority=body.priority,
            due=body.due,
        )
        return {"message": result}

    @server.delete("/api/tasks/{task_id}")
    async def delete_task(task_id: str):
        result = await server.state.engine.delete_task(task_id)
        return {"message": result}

    # ── Alarms ───────────────────────────────────────────────

    @server.get("/api/alarms")
    async def list_alarms():
        return await server.state.engine.get_alarms()

    @server.delete("/api/alarms/{alarm_id}")
    async def cancel_alarm(alarm_id: str):
        result = await server.state.engine.cancel_alarm(alarm_id)
        return {"message": result}

    # ── Notes ────────────────────────────────────────────────

    @server.get("/api/notes")
    async def list_notes(limit: int = 20):
        return server.state.engine.get_notes(limit=max(1, min(limit, 100)))

    @server.get("/api/notes/search")
    async def search_notes(q: str, limit: int = 5):
        result = await server.state.engine.search_notes(q, max(1, min(limit, 20)))
        return {"result": result}

    @server.put("/api/notes/{note_id}")
    async def update_note(note_id: str, body: NoteUpdate):
        result = await server.state.engine.update_note(
            note_id, content=body.content, tags=body.tags
        )
        return {"message": result}

    @server.delete("/api/notes/{note_id}")
    async def delete_note(note_id: str):
        try:
            await server.state.engine.delete_note(note_id)
        except KeyError:
            raise HTTPException(status_code=404, detail="Note not found")
        except Exception:
            logger.exception("delete_note failed")
            raise HTTPException(
                status_code=500, detail="Delete failed. Please try again."
            )
        return {"message": "Deleted."}

    # ── History ──────────────────────────────────────────────

    @server.get("/api/history")
    async def get_history():
        sessions = server.state.engine.get_recent_sessions(limit=50)
        return [s.to_log_dict() for s in sessions]

    return server
