"""Configuration model — Pydantic validated, loaded from YAML + env."""

from __future__ import annotations

from pathlib import Path

import yaml
from pydantic import BaseModel, Field

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
    intents: dict[str, str] = Field(
        default_factory=lambda: {
            "task": "user wants to create or manage a todo item",
            "alarm": "user wants to set a timer or alarm",
            "note": "user wants to save or recall information",
            "query": "user is asking a question",
            "link": "user wants to save or look up a URL",
            "clipboard": "user wants to copy something to clipboard",
        }
    )

    @classmethod
    def load(cls, path: Path | None = None) -> NudgeConfig:
        """Load from YAML file, falling back to defaults."""
        p = path or CONFIG_FILE
        if p.exists():
            with open(p) as f:
                data = yaml.safe_load(f) or {}
            return cls(**data)
        return cls()

    def save(self, path: Path | None = None) -> Path:
        """Save to YAML file."""
        p = path or CONFIG_FILE
        p.parent.mkdir(parents=True, exist_ok=True)
        with open(p, "w") as f:
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
