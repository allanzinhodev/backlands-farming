"""Stage and back up related asset files before replacing any originals.

Each destination gets a staging directory on its own filesystem. Backups stay
beside their original files, so a failed save can recover DAT/SPR and associated
server files together even when they live in different directories or drives.
"""
from __future__ import annotations

from collections.abc import Callable
from datetime import datetime
import os
from pathlib import Path
import shutil
import tempfile
import uuid


def _canonical(path: Path) -> Path:
    absolute = Path(path).absolute()
    try:
        if absolute.resolve() != absolute:
            raise ValueError(f"O caminho mudou ou contém um link: {absolute}.")
    except RuntimeError as error:
        raise ValueError(f"O caminho contém um link inválido: {absolute}.") from error
    return absolute


def _check_target(target: Path) -> None:
    _canonical(target)
    if target.exists() and not target.is_file():
        raise ValueError(f"O destino não é um arquivo: {target}.")


def _backup_directory(parent: Path, transaction: str) -> Path:
    directory = parent / ".backups" / transaction
    try:
        directory.resolve().relative_to(parent)
    except (ValueError, RuntimeError) as error:
        raise ValueError(f"A pasta .backups aponta para fora de {parent}.") from error
    return directory


def _copy_synced(source: Path, destination: Path) -> None:
    # Windows requires a writable descriptor for fsync. Sync before copying
    # permissions, since the original may be marked read-only.
    with source.open("rb") as original, destination.open("xb") as copied:
        shutil.copyfileobj(original, copied)
        copied.flush()
        os.fsync(copied.fileno())
    shutil.copystat(source, destination)


def _cleanup_stage(stage: Path, parent: Path) -> None:
    # Never recurse into a target, an ancestor or a link substituted after the
    # allocation. Only the exact directory returned by mkdtemp may be removed.
    try:
        if (stage.parent == parent and parent.resolve() == parent
                and stage.resolve() == stage and not stage.is_symlink()
                and stage.name.startswith(".backlands-stage-")):
            shutil.rmtree(stage, ignore_errors=True)
    except (OSError, RuntimeError):
        pass


def atomic_write_files(
    entries: list[tuple[Path, bytes]], staging_root: Path,
    preflight: Callable[[], None] | None = None,
) -> None:
    """Replace a set of files, restoring touched originals if any write fails.

    Callers supply resolved target paths and fully serialized data. ``preflight``
    runs before any filesystem changes and again after all staging and backups,
    immediately before replacements. It can reject changes made by another app.
    Backups are retained under each target parent's ``.backups/<transaction>``.
    """
    root = _canonical(staging_root)
    if root.exists() and not root.is_dir():
        raise ValueError(f"A pasta de salvamento não é um diretório: {root}.")
    validated: list[tuple[Path, bytes]] = []
    paths: set[str] = set()
    for raw_target, data in entries:
        target = _canonical(raw_target)
        key = str(target).casefold()
        if target == root:
            raise ValueError("A pasta de salvamento também foi usada como arquivo de destino.")
        if key in paths:
            raise ValueError("Os arquivos precisam ter caminhos diferentes.")
        if not isinstance(data, bytes):
            raise TypeError("Os dados de salvamento precisam estar em bytes.")
        _check_target(target)
        paths.add(key)
        validated.append((target, data))
    for target, _ in validated:
        if any(str(parent).casefold() in paths for parent in target.parents):
            raise ValueError("Um arquivo de destino também foi usado como diretório.")
    if preflight is not None:
        preflight()
    if not validated:
        return

    transaction = datetime.now().strftime("%Y%m%d-%H%M%S-%f") + "-" + uuid.uuid4().hex
    stages: dict[Path, Path] = {}
    staged: dict[Path, Path] = {}
    backups: dict[Path, Path | None] = {}
    touched: list[Path] = []
    try:
        # No target is replaced until every payload and original backup exists.
        for index, (target, data) in enumerate(validated):
            _check_target(target)
            parent = target.parent
            parent.mkdir(parents=True, exist_ok=True)
            _canonical(parent)
            if parent not in stages:
                stage = Path(tempfile.mkdtemp(prefix=".backlands-stage-", dir=parent))
                stages[parent] = stage
                _canonical(stage)
            temporary = stages[parent] / str(index)
            with temporary.open("xb") as stream:
                stream.write(data)
                stream.flush()
                os.fsync(stream.fileno())
            staged[target] = temporary

        backup_directories: dict[Path, Path] = {}
        for target, _ in validated:
            _check_target(target)
            backup_directory = _backup_directory(target.parent, transaction)
            if target.exists():
                if target.parent not in backup_directories:
                    backup_directory.parent.mkdir(parents=True, exist_ok=True)
                    _backup_directory(target.parent, transaction)
                    backup_directory.mkdir()
                    backup_directories[target.parent] = backup_directory
                backup = backup_directory / target.name
                _copy_synced(target, backup)
                backups[target] = backup
            else:
                backups[target] = None

        if preflight is not None:
            preflight()
        for target, _ in validated:
            _check_target(target)
            # Include the attempted destination in rollback, since a replace
            # wrapper may raise after the filesystem already performed it.
            touched.append(target)
            os.replace(staged[target], target)
    except Exception as error:
        failures = []
        for target in reversed(touched):
            try:
                _check_target(target)
                backup = backups[target]
                if backup is None:
                    target.unlink(missing_ok=True)
                else:
                    restore = stages[target.parent] / ("restore-" + uuid.uuid4().hex)
                    _copy_synced(backup, restore)
                    os.replace(restore, target)
            except (OSError, ValueError, RuntimeError) as restore_error:
                failures.append(f"{target}: {restore_error}")
        if failures:
            raise OSError(
                "Falha ao salvar e restaurar arquivos. Recupere os originais em .backups. "
                + "; ".join(failures)
            ) from error
        raise
    finally:
        for parent, stage in stages.items():
            _cleanup_stage(stage, parent)
