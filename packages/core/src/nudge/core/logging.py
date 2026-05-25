"""Rotating file logging to ~/.nudge/logs/nudge.log."""

from __future__ import annotations

import logging
from logging.handlers import RotatingFileHandler

from nudge.core.config import LOG_DIR


def setup_logging(level: int = logging.INFO) -> None:
    """Configure package-wide logging with file rotation."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = LOG_DIR / "nudge.log"

    handler = RotatingFileHandler(
        log_file,
        maxBytes=5 * 1024 * 1024,
        backupCount=3,
    )
    handler.setFormatter(
        logging.Formatter(
            "%(asctime)s %(levelname)s %(name)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
    )

    root = logging.getLogger("nudge")
    root.setLevel(level)
    if not root.handlers:
        root.addHandler(handler)

    hive_logger = logging.getLogger("hive")
    hive_logger.setLevel(logging.WARNING)
    if not hive_logger.handlers:
        hive_logger.addHandler(handler)
