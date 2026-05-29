"""Tests for named link handler — save/open/copy/list/remove."""

from __future__ import annotations

from pathlib import Path

import pytest

from nudge.tools.named_links import (
    copy_link,
    handle_link_command,
    list_links,
    open_link,
    remove_link,
    save_link,
)


@pytest.fixture
def links_path(tmp_path: Path) -> Path:
    return tmp_path / "links.json"


class TestSaveLink:
    def test_save_new(self, links_path: Path) -> None:
        result = save_link("LinkedIn", "https://linkedin.com/in/me", links_path)
        assert "Saved" in result
        assert "linkedin.com" in result

    def test_save_update(self, links_path: Path) -> None:
        save_link("LinkedIn", "https://linkedin.com/in/old", links_path)
        result = save_link("LinkedIn", "https://linkedin.com/in/new", links_path)
        assert "Updated" in result
        assert "new" in result

    def test_save_invalid_url(self, links_path: Path) -> None:
        result = save_link("bad", "not-a-url", links_path)
        assert "Invalid URL" in result

    def test_save_empty_name(self, links_path: Path) -> None:
        result = save_link("", "https://example.com", links_path)
        assert "Need a name" in result

    def test_save_normalizes_key(self, links_path: Path) -> None:
        save_link("My LinkedIn Profile", "https://linkedin.com/in/me", links_path)
        result = open_link("my linkedin profile", links_path, opener=lambda u: None)
        assert "Opened" in result


class TestOpenLink:
    def test_open_existing(self, links_path: Path) -> None:
        save_link("GitHub", "https://github.com/chiruu12", links_path)
        opened_urls: list[str] = []
        result = open_link("GitHub", links_path, opener=opened_urls.append)
        assert "Opened" in result
        assert opened_urls == ["https://github.com/chiruu12"]

    def test_open_missing(self, links_path: Path) -> None:
        result = open_link("Nope", links_path)
        assert "No link named" in result

    def test_open_suggests_alternatives(self, links_path: Path) -> None:
        save_link("GitHub", "https://github.com", links_path)
        result = open_link("gitlab", links_path)
        assert "GitHub" in result


class TestCopyLink:
    def test_copy_existing(self, links_path: Path) -> None:
        save_link("Docs", "https://docs.example.com", links_path)
        copied: list[str] = []
        result = copy_link("Docs", links_path, copier=copied.append)
        assert "Copied" in result
        assert copied == ["https://docs.example.com"]

    def test_copy_missing(self, links_path: Path) -> None:
        result = copy_link("Nope", links_path, copier=lambda u: None)
        assert "No link named" in result


class TestListLinks:
    def test_list_empty(self, links_path: Path) -> None:
        result = list_links(links_path)
        assert "No saved links" in result

    def test_list_populated(self, links_path: Path) -> None:
        save_link("A", "https://a.com", links_path)
        save_link("B", "https://b.com", links_path)
        result = list_links(links_path)
        assert "2 link(s)" in result
        assert "a.com" in result
        assert "b.com" in result


class TestRemoveLink:
    def test_remove_existing(self, links_path: Path) -> None:
        save_link("Temp", "https://temp.com", links_path)
        result = remove_link("Temp", links_path)
        assert "Removed" in result
        assert "No saved links" in list_links(links_path)

    def test_remove_missing(self, links_path: Path) -> None:
        result = remove_link("Nope", links_path)
        assert "No link named" in result


class TestHandleLinkCommand:
    def test_save_with_as(self, tmp_path: Path) -> None:
        result = handle_link_command(
            "save my LinkedIn as https://linkedin.com/in/me",
            data_dir=tmp_path,
        )
        assert "Saved" in result

    def test_open(self, tmp_path: Path) -> None:
        handle_link_command("save GitHub as https://github.com", data_dir=tmp_path)
        # open_link uses webbrowser by default — we test the parse, not the browser
        result = handle_link_command("list", data_dir=tmp_path)
        assert "GitHub" in result

    def test_copy_strips_my(self, tmp_path: Path) -> None:
        handle_link_command("save Docs as https://docs.example.com", data_dir=tmp_path)
        result = handle_link_command("list links", data_dir=tmp_path)
        assert "Docs" in result

    def test_remove(self, tmp_path: Path) -> None:
        handle_link_command("save Temp as https://temp.com", data_dir=tmp_path)
        result = handle_link_command("delete my Temp", data_dir=tmp_path)
        assert "Removed" in result

    def test_list(self, tmp_path: Path) -> None:
        result = handle_link_command("show links", data_dir=tmp_path)
        assert "No saved links" in result

    def test_unknown_command(self, tmp_path: Path) -> None:
        result = handle_link_command("something weird", data_dir=tmp_path)
        assert "don't understand" in result

    def test_strips_link_suffix(self, tmp_path: Path) -> None:
        handle_link_command("save GitHub as https://github.com", data_dir=tmp_path)
        result = handle_link_command("list links", data_dir=tmp_path)
        assert "GitHub" in result

    def test_save_without_as(self, tmp_path: Path) -> None:
        result = handle_link_command(
            "save Portfolio https://example.com/portfolio",
            data_dir=tmp_path,
        )
        assert "Saved" in result

    def test_open_via_voice(self, tmp_path: Path) -> None:
        handle_link_command("save GitHub as https://github.com", data_dir=tmp_path)
        opened: list[str] = []
        result = handle_link_command(
            "open my GitHub link",
            data_dir=tmp_path,
            opener=opened.append,
        )
        assert "Opened" in result
        assert opened == ["https://github.com"]

    def test_copy_via_voice(self, tmp_path: Path) -> None:
        handle_link_command("save Docs as https://docs.example.com", data_dir=tmp_path)
        copied: list[str] = []
        result = handle_link_command(
            "copy my Docs url",
            data_dir=tmp_path,
            copier=copied.append,
        )
        assert "Copied" in result
        assert copied == ["https://docs.example.com"]


class TestCorruptFileRecovery:
    def test_corrupt_file_backed_up(self, links_path: Path) -> None:
        links_path.parent.mkdir(parents=True, exist_ok=True)
        links_path.write_text("{broken json")
        result = save_link("Test", "https://test.com", links_path)
        assert "Saved" in result
        assert links_path.with_suffix(".json.bak").exists()

    def test_corrupt_file_data_preserved_in_backup(self, links_path: Path) -> None:
        links_path.parent.mkdir(parents=True, exist_ok=True)
        links_path.write_text("{broken json")
        save_link("Test", "https://test.com", links_path)
        backup = links_path.with_suffix(".json.bak")
        assert backup.read_text() == "{broken json"


class TestClipboardSave:
    def test_save_this_derives_name_from_url(self, links_path: Path) -> None:
        def reader() -> str:
            return "https://www.linkedin.com/in/chiruu12/"

        msg = handle_link_command("save this link", data_dir=links_path.parent, reader=reader)
        assert "linkedin" in msg.lower()
        from nudge.tools.named_links import load_links

        assert load_links(links_path)["linkedin"]["url"].endswith("chiruu12/")

    def test_save_this_as_name(self, links_path: Path) -> None:
        def reader() -> str:
            return "check this https://github.com/chiruu12 out"

        msg = handle_link_command("save this as github", data_dir=links_path.parent, reader=reader)
        assert "github" in msg.lower()
        from nudge.tools.named_links import load_links

        assert load_links(links_path)["github"]["url"] == "https://github.com/chiruu12"

    def test_save_clipboard_no_url(self, links_path: Path) -> None:
        def reader() -> str:
            return "just some text, no link"

        msg = handle_link_command("save this", data_dir=links_path.parent, reader=reader)
        assert "copy a link" in msg.lower()
