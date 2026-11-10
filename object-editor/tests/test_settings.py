"""Startup preferences survive restarts without affecting asset operations."""
from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from backlands_editor import settings


class SettingsTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name)
        self.preferences = self.directory / "config" / "settings.json"
        self.project = self.directory / "assets"
        self.project.mkdir()
        self.settings_patch = mock.patch.object(settings, "_settings_path", return_value=self.preferences)
        self.settings_patch.start()

    def tearDown(self):
        self.settings_patch.stop()
        self.temporary.cleanup()

    def write_preferences(self, value):
        self.preferences.parent.mkdir(exist_ok=True)
        self.preferences.write_text(json.dumps(value), encoding="utf-8")

    def test_roundtrip_preserves_selected_otfi_and_other_preferences(self):
        self.write_preferences({"zoom": 6})
        selected = self.project / "Game.otfi"
        selected.write_text("DatSpr\n", encoding="utf-8")

        settings.remember_project(selected)

        self.assertEqual(settings.load_last_project(), selected.resolve())
        self.assertEqual(json.loads(self.preferences.read_text(encoding="utf-8")),
                         {"zoom": 6, "last_project": str(selected.resolve())})

    def test_directory_roundtrip(self):
        settings.remember_project(self.project)
        self.assertEqual(settings.load_last_project(), self.project.resolve())

    def test_missing_stale_and_invalid_preferences_allow_startup(self):
        self.assertIsNone(settings.load_last_project())
        for value in ([], {"last_project": 1}, {"last_project": ""},
                      {"last_project": "relative/assets"},
                      {"last_project": str(self.directory / "missing")},
                      {"last_project": "invalid\x00path"}):
            with self.subTest(value=value):
                self.write_preferences(value)
                self.assertIsNone(settings.load_last_project())
        self.preferences.write_bytes(b"\xff invalid JSON")
        self.assertIsNone(settings.load_last_project())

    def test_bad_preferences_can_be_replaced_after_successful_open(self):
        self.preferences.parent.mkdir()
        self.preferences.write_text("broken JSON", encoding="utf-8")
        settings.remember_project(self.project)
        self.assertEqual(settings.load_last_project(), self.project.resolve())

    def test_preferences_failure_keeps_previous_file_and_removes_staging(self):
        self.write_preferences({"zoom": 4})
        previous = self.preferences.read_bytes()
        with mock.patch.object(settings.os, "replace", side_effect=PermissionError("locked")):
            settings.remember_project(self.project)
        self.assertEqual(self.preferences.read_bytes(), previous)
        self.assertEqual(list(self.preferences.parent.iterdir()), [self.preferences])

    def test_permissions_are_nonfatal_for_read_and_write(self):
        with mock.patch.object(Path, "read_text", side_effect=PermissionError("locked")):
            self.assertIsNone(settings.load_last_project())
        with mock.patch.object(Path, "mkdir", side_effect=PermissionError("locked")):
            settings.remember_project(self.project)
        self.assertFalse(self.preferences.exists())

    def test_invalid_project_does_not_replace_previous_preferences(self):
        self.write_preferences({"zoom": 4})
        settings.remember_project(self.directory / "missing.otfi")
        self.assertEqual(json.loads(self.preferences.read_text()), {"zoom": 4})

    def test_startup_explicit_path_wins_even_when_missing(self):
        settings.remember_project(self.project)
        requested = self.directory / "missing.otfi"
        self.assertEqual(settings.startup_project(requested, self.directory), requested)

    def test_startup_recent_project_wins_over_game_default(self):
        default = self.directory / "assets" / "860" / "Tibia.otfi"
        default.parent.mkdir()
        default.touch()
        selected = self.project / "custom.otfi"
        selected.touch()
        settings.remember_project(selected)
        self.assertEqual(settings.startup_project(root=self.directory), selected.resolve())

    def test_startup_tries_real_defaults_in_order_after_stale_recent(self):
        self.write_preferences({"last_project": str(self.directory / "removed.otfi")})
        defaults = [self.directory / relative for relative in (
            "assets/860/Tibia.otfi", "assets/Tibia.otfi", "assets/Backlands.otfi")]
        for candidate in defaults:
            candidate.parent.mkdir(exist_ok=True)
            candidate.touch()
        for candidate in defaults:
            self.assertEqual(settings.startup_project(root=self.directory), candidate.resolve())
            candidate.unlink()
        self.assertIsNone(settings.startup_project(root=self.directory))

    def test_startup_does_not_select_demo_assets(self):
        demo = self.directory / "object-editor" / "examples" / "farm" / "Tibia.otfi"
        demo.parent.mkdir(parents=True)
        demo.touch()
        self.assertIsNone(settings.startup_project(root=self.directory))


if __name__ == "__main__":
    unittest.main()
