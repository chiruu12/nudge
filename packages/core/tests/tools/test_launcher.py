"""Tests for launcher toolkit."""

from __future__ import annotations

from unittest.mock import patch

from nudge.tools.launcher import launch_app, list_available_apps


class TestLaunchApp:
    def test_unknown_app(self) -> None:
        result = launch_app("nonexistent_app_xyz")
        assert "Unknown app" in result
        assert "Available" in result

    def test_launch_codex_with_prompt(self) -> None:
        with (
            patch("nudge.tools.launcher.shutil.which", return_value="/usr/bin/codex"),
            patch("nudge.tools.launcher.subprocess.Popen") as mock_popen,
        ):
            result = launch_app("codex", "fix the auth bug")
            mock_popen.assert_called_once_with(["codex", "fix the auth bug"])
            assert "Launched" in result
            assert "Codex" in result

    def test_launch_without_prompt(self) -> None:
        with (
            patch("nudge.tools.launcher.shutil.which", return_value="/usr/bin/codex"),
            patch("nudge.tools.launcher.subprocess.Popen") as mock_popen,
        ):
            result = launch_app("codex")
            mock_popen.assert_called_once_with(["codex"])
            assert "Launched" in result

    def test_app_not_installed(self) -> None:
        with patch("nudge.tools.launcher.shutil.which", return_value=None):
            result = launch_app("codex")
            assert "not installed" in result

    def test_alias_resolution(self) -> None:
        with (
            patch("nudge.tools.launcher.shutil.which", return_value="/usr/bin/claude"),
            patch("nudge.tools.launcher.subprocess.Popen"),
        ):
            result = launch_app("claude code")
            assert "Claude Code" in result

    def test_mac_bundle_fallback(self) -> None:
        with (
            patch("nudge.tools.launcher.shutil.which", return_value=None),
            patch("nudge.tools.launcher.subprocess.Popen") as mock_popen,
            patch("os.path.exists", return_value=True),
        ):
            result = launch_app("cursor")
            mock_popen.assert_called_once()
            assert "Opened" in result or "Cursor" in result

    def test_launch_empty_string(self) -> None:
        result = launch_app("")
        assert "Unknown app" in result

    def test_launch_whitespace(self) -> None:
        result = launch_app("   ")
        assert "Unknown app" in result

    def test_list_available(self) -> None:
        with patch("nudge.tools.launcher.shutil.which") as mock_which:
            mock_which.side_effect = lambda cmd: "/usr/bin/" + cmd if cmd == "codex" else None
            available = list_available_apps()
            assert any("codex" in a.lower() for a in available)
