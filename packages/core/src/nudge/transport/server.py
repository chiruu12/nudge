"""Server transport — expose NudgeEngine over HTTP."""

from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager
from importlib.metadata import version as pkg_version

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator

from nudge.core.config import NudgeConfig
from nudge.core.engine import NudgeEngine
from nudge.core.logging import setup_logging

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
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type"],
    )

    @server.get("/health")
    async def health():
        return {"status": "ok", "version": pkg_version("nudge-ai")}

    @server.post("/api/process")
    async def process_text(body: TextInput):
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
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Transcription failed: {e}")
        return {"text": text}

    @server.get("/api/tasks")
    async def list_tasks():
        return await server.state.engine.get_tasks()

    @server.get("/api/alarms")
    async def list_alarms():
        return await server.state.engine.get_alarms()

    @server.get("/api/notes")
    async def list_notes(limit: int = 20):
        return server.state.engine.get_notes(limit=max(1, min(limit, 100)))

    @server.get("/api/history")
    async def get_history():
        sessions = server.state.engine.get_recent_sessions(limit=50)
        return [s.to_log_dict() for s in sessions]

    return server
