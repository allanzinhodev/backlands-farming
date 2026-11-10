"""Lossless animation edits for the classic DAT frame-group layout.

One frame is a contiguous block containing every tile, layer and pattern.
Operations build a checked replacement before changing an existing group.
The only additional classic group types are outfit idle (0) and walking (1).
"""
from __future__ import annotations

import copy
from dataclasses import replace
import random

from .formats import DatFile, FormatError, FormatOptions, FrameGroup, Thing


GROUP_NAMES = {0: "Parado / padrão", 1: "Andando"}
DEFAULT_DURATION = (150, 150)


def validate_animation(group: FrameGroup, *, required: bool = True) -> None:
    if group.animation_mode not in (0, 1):
        raise FormatError("Modo deve ser 0 (assíncrono) ou 1 (síncrono).")
    if not isinstance(group.loop_count, int) or not -0x80000000 <= group.loop_count <= 0x7FFFFFFF:
        raise FormatError("Ciclos devem caber em 32 bits com sinal.")
    if not isinstance(group.start_frame, int) or not -1 <= group.start_frame <= min(127, group.frames - 1):
        raise FormatError("Quadro inicial deve ser -1 (aleatório) ou um quadro entre 0 e 127 existente.")
    if not group.durations and not required:
        return
    if len(group.durations) != group.frames:
        raise FormatError("Informe uma duração mínima e máxima para cada quadro.")
    for pair in group.durations:
        if len(pair) != 2 or any(type(value) is not int for value in pair):
            raise FormatError("Cada duração exige dois números inteiros em milissegundos.")
        minimum, maximum = pair
        if not 0 <= minimum <= maximum <= 0xFFFFFFFF:
            raise FormatError("Durações exigem 0 ≤ mínimo ≤ máximo ≤ 4294967295 ms.")


def validate_group_types(thing: Thing) -> None:
    """Check semantic edits without silently dropping a conflicting group."""
    if thing.category != 1:
        if len(thing.groups) != 1:
            raise FormatError("Somente criaturas podem ter grupos adicionais neste DAT.")
        return
    types = [group.group_type for group in thing.groups]
    if any(value not in GROUP_NAMES for value in types):
        raise FormatError("Criaturas aceitam os grupos 0 (parado) e 1 (andando).")
    if len(types) != len(set(types)):
        raise FormatError("Já existe um grupo desse tipo. Use um parado e um andando.")


def enable_frame_groups(dat: DatFile, options: FormatOptions) -> bool:
    """Enable the wire extension, preserving every legacy frame and reference."""
    if options.frame_groups:
        return False
    # Preflight the whole affected category before changing the shared options.
    for thing in dat.categories[1]:
        if len(thing.groups) != 1 or thing.groups[0].group_type != 0:
            raise FormatError("A conversão exige um único grupo padrão por criatura.")
        _check_group(thing.groups[0])
    options.frame_groups = True
    return True


def enable_frame_durations(dat: DatFile, options: FormatOptions) -> bool:
    """Seed *all* existing animations before the new extension is serialized."""
    if options.frame_durations:
        return False
    prepared = []
    for category in dat.categories:
        for thing in category:
            for group in thing.groups:
                if group.frames <= 1:
                    continue
                durations = list(group.durations) or [DEFAULT_DURATION] * group.frames
                candidate = replace(group, durations=durations)
                _check_group(candidate)
                validate_animation(candidate)
                prepared.append((group, durations))
    for group, durations in prepared:
        group.durations = durations
    options.frame_durations = True
    return True


def create_group(thing: Thing, options: FormatOptions, source: int = 0, *, duplicate: bool = False) -> int:
    if thing.category != 1 or not options.frame_groups:
        raise FormatError("Ative grupos de criaturas para criar um grupo parado ou andando.")
    validate_group_types(thing)
    if not 0 <= source < len(thing.groups):
        raise FormatError("Grupo de origem inexistente.")
    available = set(GROUP_NAMES) - {group.group_type for group in thing.groups}
    if not available:
        raise FormatError("A criatura já possui os grupos parado e andando.")
    original = thing.groups[source]
    _check_group(original)
    new = copy.deepcopy(original)
    new.group_type = min(available)
    if not duplicate:
        new.frames = 1
        new.sprites = [0] * new.expected_count()
        new.durations = []
        new.animation_mode = new.loop_count = new.start_frame = 0
    thing.groups.append(new)
    return len(thing.groups) - 1


def remove_group(thing: Thing, index: int) -> int:
    if len(thing.groups) <= 1:
        raise FormatError("Preserve ao menos um grupo no objeto.")
    if not 0 <= index < len(thing.groups):
        raise FormatError("Grupo inexistente.")
    del thing.groups[index]
    return min(index, len(thing.groups) - 1)


def _check_group(group: FrameGroup) -> None:
    if len(group.sprites) != group.expected_count():
        raise FormatError("Número de sprites incompatível com as dimensões do grupo.")
    validate_animation(group, required=bool(group.durations))


def _replace_frames(group: FrameGroup, order: list[int | None], *, durations: bool = False, start_index: int | None = None) -> None:
    _check_group(group)
    count = len(order)
    candidate = replace(group, frames=count)
    candidate.expected_count()  # Enforces frame and allocation limits before copying.
    if any(index is not None and (type(index) is not int or not 0 <= index < group.frames) for index in order):
        raise FormatError("Quadro de origem inexistente.")
    block = len(group.sprites) // group.frames
    references = []
    for index in order:
        references.extend([0] * block if index is None else group.sprites[index * block:(index + 1) * block])
    original_durations = list(group.durations) or [DEFAULT_DURATION] * group.frames
    timings = ([DEFAULT_DURATION if index is None else original_durations[index] for index in order]
               if durations or group.durations else [])
    start = group.start_frame
    if start >= 0:
        # A duplicate must not steal the original start-frame reference.
        start = start_index if start_index is not None else order.index(start) if start in order else min(start, count - 1)
        # DAT stores start_frame in a signed byte even when there are 255 frames.
        if start > 127:
            raise FormatError("A operação levaria o quadro inicial além do limite 127 do DAT.")
    candidate.sprites, candidate.durations, candidate.start_frame = references, timings, start
    validate_animation(candidate, required=bool(timings))
    group.frames, group.sprites = count, references
    group.durations, group.start_frame = timings, start


def insert_frame(group: FrameGroup, index: int, *, duplicate: int | None = None, durations: bool = False) -> int:
    if type(index) is not int or not 0 <= index <= group.frames:
        raise FormatError("Posição do novo quadro inexistente.")
    order = list(range(group.frames))
    order.insert(index, duplicate)
    start = group.start_frame + (index <= group.start_frame) if group.start_frame >= 0 else None
    _replace_frames(group, order, durations=durations, start_index=start)
    return index


def duplicate_frame(group: FrameGroup, index: int, *, durations: bool = False) -> int:
    if type(index) is not int or not 0 <= index < group.frames:
        raise FormatError("Quadro inexistente.")
    # Insert after the original to retain an unambiguous start-frame mapping.
    return insert_frame(group, index + 1, duplicate=index, durations=durations)


def remove_frame(group: FrameGroup, index: int, *, durations: bool = False) -> int:
    if group.frames <= 1:
        raise FormatError("Preserve ao menos um quadro no grupo.")
    if type(index) is not int or not 0 <= index < group.frames:
        raise FormatError("Quadro inexistente.")
    order = list(range(group.frames))
    del order[index]
    _replace_frames(group, order, durations=durations)
    return min(index, group.frames - 1)


def move_frame(group: FrameGroup, source: int, destination: int, *, durations: bool = False) -> int:
    if any(type(index) is not int or not 0 <= index < group.frames for index in (source, destination)):
        raise FormatError("Quadro inexistente.")
    order = list(range(group.frames))
    order.insert(destination, order.pop(source))
    _replace_frames(group, order, durations=durations)
    return destination


class AnimationPlayback:
    """Preview timing, including random ranges, finite loops and ping-pong.

    Synchronous groups share the monotonic clock phase. Their duration range
    midpoint provides a stable timeline; asynchronous groups sample each range.
    """
    def __init__(self, group: FrameGroup, *, timed: bool, now_ms: int = 0, selected_frame: int = 0):
        self.group = group
        self.timed = timed and group.frames > 1
        self.direction = 1
        self.loops = 0
        self.remaining = None
        if self.timed and group.animation_mode == 1:
            durations = [max(16, (low + high) // 2) for low, high in group.durations]
            phase = now_ms % sum(durations)
            self.frame = 0
            while phase >= durations[self.frame]:
                phase -= durations[self.frame]
                self.frame += 1
            self.remaining = durations[self.frame] - phase
        elif self.timed:
            self.frame = random.randrange(group.frames) if group.start_frame == -1 else group.start_frame
        else:
            self.frame = selected_frame % group.frames

    def delay(self) -> int:
        if self.remaining is not None:
            delay, self.remaining = self.remaining, None
            return delay
        if not self.timed:
            return 150
        low, high = self.group.durations[self.frame]
        return max(16, (low + high) // 2 if self.group.animation_mode == 1 else random.randint(low, high))

    def advance(self) -> bool:
        group = self.group
        if group.frames == 1:
            return False
        if self.timed and group.loop_count < 0:
            candidate = self.frame + self.direction
            if not 0 <= candidate < group.frames:
                self.direction *= -1
                candidate = self.frame + self.direction
            self.frame = candidate
            return True
        if self.frame + 1 < group.frames:
            self.frame += 1
            return True
        self.loops += 1
        if self.timed and group.loop_count > 0 and self.loops >= group.loop_count:
            return False
        self.frame = 0
        return True
