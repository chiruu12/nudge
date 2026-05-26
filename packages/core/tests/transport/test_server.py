"""Tests for the HTTP server transport."""

from __future__ import annotations

from io import BytesIO
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from nudge.core.session import ProcessingResult
from nudge.transport.server import create_app


@pytest.fixture
def mock_engine():
    engine = MagicMock()
    engine.process_text = AsyncMock()
    engine.transcribe = AsyncMock()
    engine.get_tasks = AsyncMock(return_value=[])
    engine.get_alarms = AsyncMock(return_value=[])
    engine.get_notes = MagicMock(return_value=[])
    engine.get_recent_sessions = MagicMock(return_value=[])
    engine.shutdown = AsyncMock()
    engine.checker = MagicMock()
    engine.checker.run_forever = AsyncMock()
    engine.checker.stop = AsyncMock()
    return engine


@pytest.fixture
def client(mock_engine):
    with (
        patch("nudge.transport.server.NudgeConfig") as mock_config_cls,
        patch("nudge.transport.server.NudgeEngine", return_value=mock_engine),
        patch("nudge.transport.server.setup_logging"),
    ):
        mock_config_cls.load.return_value = MagicMock()
        app = create_app()
        with TestClient(app, raise_server_exceptions=False) as c:
            yield c


class TestHealth:
    def test_health(self, client: TestClient) -> None:
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"
        assert "version" in data


class TestCors:
    def test_nextjs_dev_origin_can_call_api(self, client: TestClient) -> None:
        resp = client.options(
            "/api/process",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "POST",
            },
        )

        assert resp.status_code == 200
        assert resp.headers["access-control-allow-origin"] == "http://localhost:3000"


class TestProcessText:
    def test_process_text(self, client: TestClient, mock_engine: MagicMock) -> None:
        result = ProcessingResult(
            text="buy milk",
            intent="task",
            confidence=0.95,
            response="Task created: buy milk",
            duration_ms=42,
        )
        mock_engine.process_text.return_value = result

        resp = client.post("/api/process", json={"text": "buy milk"})

        assert resp.status_code == 200
        data = resp.json()
        assert data["text"] == "buy milk"
        assert data["intent"] == "task"
        assert data["response"] == "Task created: buy milk"
        mock_engine.process_text.assert_called_once_with("buy milk")

    def test_process_text_empty(self, client: TestClient) -> None:
        resp = client.post("/api/process", json={"text": "   "})
        assert resp.status_code == 422

    def test_process_text_missing_field(self, client: TestClient) -> None:
        resp = client.post("/api/process", json={})
        assert resp.status_code == 422


class TestTranscribeAudio:
    def test_transcribe_audio(self, client: TestClient, mock_engine: MagicMock) -> None:
        mock_engine.transcribe.return_value = "buy milk tomorrow"

        audio_data = b"\x00\x01\x02" * 100
        resp = client.post(
            "/api/transcribe",
            files={"file": ("audio.wav", BytesIO(audio_data), "audio/wav")},
        )

        assert resp.status_code == 200
        assert resp.json() == {"text": "buy milk tomorrow"}
        mock_engine.transcribe.assert_called_once()

    def test_transcribe_empty_file(self, client: TestClient) -> None:
        resp = client.post(
            "/api/transcribe",
            files={"file": ("empty.wav", BytesIO(b""), "audio/wav")},
        )
        assert resp.status_code == 422
        assert "Empty audio file" in resp.json()["detail"]

    def test_transcribe_no_file(self, client: TestClient) -> None:
        resp = client.post("/api/transcribe")
        assert resp.status_code == 422


class TestListEndpoints:
    def test_list_tasks(self, client: TestClient, mock_engine: MagicMock) -> None:
        mock_engine.get_tasks.return_value = [
            {"id": 1, "text": "buy milk", "status": "pending"},
        ]

        resp = client.get("/api/tasks")

        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 1
        assert data[0]["text"] == "buy milk"

    def test_list_alarms(self, client: TestClient, mock_engine: MagicMock) -> None:
        mock_engine.get_alarms.return_value = [
            {"id": 1, "time": "08:00", "label": "standup"},
        ]

        resp = client.get("/api/alarms")

        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 1
        assert data[0]["label"] == "standup"

    def test_list_notes(self, client: TestClient, mock_engine: MagicMock) -> None:
        mock_engine.get_notes.return_value = [
            {"content": "API needs OAuth2", "timestamp": None, "file": "note1.md"},
        ]

        resp = client.get("/api/notes")

        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 1
        assert data[0]["content"] == "API needs OAuth2"

    def test_history_empty(self, client: TestClient, mock_engine: MagicMock) -> None:
        mock_engine.get_recent_sessions.return_value = []

        resp = client.get("/api/history")

        assert resp.status_code == 200
        assert resp.json() == []
        mock_engine.get_recent_sessions.assert_called_once_with(limit=50)
