"""Configuration model — Pydantic validated, loaded from YAML + env."""

from __future__ import annotations

import logging
from pathlib import Path

import yaml
from pydantic import BaseModel, Field, ValidationError

logger = logging.getLogger(__name__)

CONFIG_DIR = Path.home() / ".nudge"
CONFIG_FILE = CONFIG_DIR / "config.yaml"
DATA_DIR = CONFIG_DIR / "data"
LOG_DIR = CONFIG_DIR / "logs"


class NudgeConfig(BaseModel):
    stt_provider: str = "groq"
    llm_provider: str = "groq"
    llm_tier: str = "standard"
    hotkey: str = "cmd+shift+n"
    sample_rate: int = 16000
    notification_title: str = "Nudge"
    data_dir: str = str(DATA_DIR)
    log_dir: str = str(LOG_DIR)
    hosted_stt: bool = False
    api_base_url: str = "https://api.nudge.dev"
    stt_timeout_s: float = Field(default=30.0, gt=0)
    intent_timeout_s: float = Field(default=10.0, gt=0)
    agent_timeout_s: float = Field(default=30.0, gt=0)
    min_confidence: float = Field(default=0.3, ge=0.0, le=1.0)
    max_text_length: int = Field(default=10_000, gt=0)
    intents: dict[str, str] = Field(
        default_factory=lambda: {
            "task": (
                "user wants to create, complete, or manage a todo/task."
                " No specific time. (e.g. 'add task buy milk', 'I need to do X')"
            ),
            "alarm": (
                "user wants a timed reminder. MUST mention a specific time or duration."
                " (e.g. 'remind me at 3pm', 'in 5 minutes', 'wake me at 7am')"
            ),
            "note": (
                "user wants to save, recall, or search information"
                " (e.g. remember that, what do I know about)"
            ),
            "query": "user is asking a general question (e.g. what is, how do I)",
            "link": (
                "user wants to save, open, copy, or remove a named URL"
                " (e.g. save my github as, open my linkedin)"
            ),
            "clipboard": "user wants to copy text to clipboard",
            "launch": "user wants to open a coding tool or app (e.g. open codex)",
        }
    )

    @classmethod
    def load(cls, path: Path | None = None) -> NudgeConfig:
        """Load from YAML file, using defaults only when no file exists."""
        p = path or CONFIG_FILE
        if p.exists():
            try:
                with open(p, encoding="utf-8") as f:
                    data = yaml.safe_load(f) or {}
                return cls(**data)
            except (OSError, UnicodeError, yaml.YAMLError, TypeError, ValidationError) as e:
                logger.error("Invalid config file %s: %s", p, e)
                raise ValueError(f"Invalid Nudge configuration in {p}: {e}") from e
        return cls()

    def save(self, path: Path | None = None) -> Path:
        """Save to YAML file."""
        p = path or CONFIG_FILE
        p.parent.mkdir(parents=True, exist_ok=True)
        with open(p, "w", encoding="utf-8") as f:
            yaml.dump(self.model_dump(), f, default_flow_style=False, sort_keys=False)
        return p

    @classmethod
    def from_preset(cls, name: str) -> NudgeConfig:
        """Load a preset config by name from bundled presets."""
        import importlib.resources as resources

        try:
            ref = resources.files("nudge.presets").joinpath(f"{name}.yaml")
            data = yaml.safe_load(ref.read_text()) or {}
        except (FileNotFoundError, TypeError):
            raise FileNotFoundError(f"Preset '{name}' not found. Available: default, fast, offline")
        return cls(**data)
