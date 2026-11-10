"""Best-effort local preferences for the asset editor.

Preferences must never prevent opening or saving game assets. Only successful
project operations should call ``remember_project``.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import tempfile


def _settings_path() -> Path:
    if os.name == "nt":
        local = os.environ.get("LOCALAPPDATA")
        base = Path(local) if local else Path.home() / "AppData" / "Local"
        return base / "Backlands" / "AssetStudio" / "settings.json"
    config = os.environ.get("XDG_CONFIG_HOME")
    base = Path(config) if config else Path.home() / ".config"
    return base / "backlands" / "asset-studio" / "settings.json"


def _read_settings(path: Path) -> dict:
    try:
        settings = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError, UnicodeError):
        return {}
    return settings if isinstance(settings, dict) else {}


def load_last_project() -> Path | None:
    """Return the last opened project when it still exists."""
    try:
        value = _read_settings(_settings_path()).get("last_project")
        if not isinstance(value, str) or not value.strip():
            return None
        path = Path(value).expanduser()
        if not path.is_absolute():
            return None
        if path.is_dir() or (path.suffix.lower() == ".otfi" and path.is_file()):
            return path.resolve()
    except (OSError, ValueError, RuntimeError):
        pass
    return None


def startup_project(explicit: Path | None = None, root: Path | None = None) -> Path | None:
    """Choose explicit input, recent project, then the game's standard assets.

    Explicit paths remain selected even if unavailable so the interface can
    report the user's requested path instead of silently opening another one.
    """
    if explicit is not None:
        return Path(explicit)
    previous = load_last_project()
    if previous is not None:
        return previous
    game_root = Path(root) if root is not None else Path(__file__).resolve().parents[2]
    for relative in ("assets/860/Tibia.otfi", "assets/Tibia.otfi", "assets/Backlands.otfi"):
        candidate = game_root / relative
        try:
            if candidate.is_file():
                return candidate.resolve()
        except (OSError, ValueError, RuntimeError):
            continue
    return None


def remember_project(path: str | Path) -> None:
    """Remember a successful open/save without letting preference errors escape."""
    temporary = None
    try:
        project = Path(path).expanduser().resolve()
        if not (project.is_dir() or (project.suffix.lower() == ".otfi" and project.is_file())):
            return
        destination = _settings_path()
        settings = _read_settings(destination)
        settings["last_project"] = str(project)
        destination.parent.mkdir(parents=True, exist_ok=True)
        # A temporary file in the same directory keeps replacement atomic and
        # protects the previous preferences if writing or replacement fails.
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=destination.parent,
            prefix=".settings-", suffix=".tmp", delete=False,
        ) as stream:
            temporary = Path(stream.name)
            json.dump(settings, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, destination)
    except (OSError, ValueError, RuntimeError):
        pass
    finally:
        if temporary is not None:
            try:
                temporary.unlink(missing_ok=True)
            except OSError:
                pass
