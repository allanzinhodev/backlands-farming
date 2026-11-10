"""Project operations for a native 16-pixel DAT/SPR asset set.

Sheets keep each animation, pattern and layer separate. Importing them appends
sprites instead of changing IDs shared by other objects.
"""
from __future__ import annotations

import copy
import json
import os
from pathlib import Path

from PIL import Image, PngImagePlugin

from .formats import (
    MAX_SPRITES, DatFile, FormatOptions, SpriteFile, Thing,
    read_dat, read_otfi, read_spr, write_dat, write_otfi, write_spr,
)
from .server_project import MANIFEST_NAME, ServerFiles
from .transactions import atomic_write_files

SPRITE_SIZE = 16
MAX_IMAGE_PIXELS = 16_777_216
MAX_IMAGE_DIMENSION = 8192


def _check_options(options: FormatOptions) -> None:
    if options.sprite_size != SPRITE_SIZE:
        raise ValueError("Este editor exige sprites nativas de 16x16 pixels. Converta os arquivos de 32px antes de abri-los.")
    options.validate()


def _safe_path(directory: Path, name: str) -> Path:
    """Resolve a project-relative filename without following an escaping link."""
    relative = Path(name)
    if not name or any(character in name for character in ("\r", "\n", ":")) or relative.is_absolute() or relative.drive:
        raise ValueError(f"O caminho deve ser relativo à pasta do projeto: {name!r}.")
    base = directory.resolve()
    candidate = (base / relative).resolve()
    try:
        canonical_relative = candidate.relative_to(base)
    except ValueError as exc:
        raise ValueError(f"O arquivo está fora da pasta do projeto: {name!r}.") from exc
    if candidate == base or canonical_relative.parts[0].lower() == ".backups":
        raise ValueError(f"Nome de arquivo reservado ou inválido: {name!r}.")
    return candidate


def _otfi_filenames(path: Path) -> tuple[str, str]:
    names = {"metadata-file": "Tibia.dat", "sprites-file": "Tibia.spr"}
    in_section = False
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        # Use the same section and comment rules as formats.read_otfi(). The
        # caller already validated that section before reading its filenames.
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if not line[0].isspace():
            in_section = line.strip().rstrip(":") == "DatSpr"
            continue
        if not in_section:
            continue
        key, colon, value = line.strip().partition(":")
        key = key.strip()
        if colon and key in names:
            value = value.strip()
            if value.startswith(('"', "'")) and len(value) >= 2 and value[-1] == value[0]:
                value = value[1:-1]
            if not value or "\n" in value or "\r" in value:
                raise ValueError(f"Nome inválido em {path.name}: {key}.")
            names[key] = value
    return names["metadata-file"], names["sprites-file"]


def _default_file(directory: Path, default: str, suffix: str) -> str:
    if (directory / default).is_file():
        return default
    candidates = sorted(directory.glob("*" + suffix))
    if len(candidates) == 1:
        return candidates[0].name
    if len(candidates) > 1:
        raise ValueError(f"Há vários arquivos {suffix}; use um .otfi para indicar o par correto.")
    return default


def _check_image_size(width: int, height: int) -> None:
    if width < 1 or height < 1 or max(width, height) > MAX_IMAGE_DIMENSION or width * height > MAX_IMAGE_PIXELS:
        raise ValueError(f"Imagem muito grande: limite de {MAX_IMAGE_PIXELS:,} pixels e {MAX_IMAGE_DIMENSION}px por lado.")


def _open_png(path: str | Path) -> Image.Image:
    with Image.open(path) as source:
        if source.format != "PNG":
            raise ValueError("Selecione uma imagem PNG.")
        _check_image_size(*source.size)
        source.load()
        return source.convert("RGBA")


class Project:
    def __init__(
        self, dat: DatFile, spr: SpriteFile, options: FormatOptions | None = None,
        directory: str | Path | None = None, dat_name: str = "Tibia.dat",
        spr_name: str = "Tibia.spr", otfi_name: str = "Tibia.otfi",
    ) -> None:
        self.dat = dat
        self.spr = spr
        self.options = options if options is not None else FormatOptions()
        _check_options(self.options)
        self.directory = Path(directory).resolve() if directory is not None else None
        self.dat_name = dat_name
        self.spr_name = spr_name
        self.otfi_name = otfi_name
        self.server_files = ServerFiles()

    @classmethod
    def new(cls, options: FormatOptions | None = None) -> "Project":
        options = copy.deepcopy(options) if options is not None else FormatOptions()
        _check_options(options)
        dat = DatFile()
        dat.categories[0].append(Thing(id=100, category=0))
        return cls(dat, SpriteFile(), options)

    @classmethod
    def load(cls, path: str | Path, options: FormatOptions | None = None) -> "Project":
        selected = Path(path).resolve()
        otfi = None
        if selected.is_dir():
            directory = selected
            candidates = sorted(directory.glob("*.otfi"))
            if len(candidates) > 1:
                raise ValueError("Há vários arquivos .otfi nesta pasta; selecione o arquivo desejado.")
            if candidates:
                otfi = candidates[0]
        elif selected.is_file() and selected.suffix.lower() == ".otfi":
            otfi = selected
            directory = selected.parent
        else:
            raise ValueError("Selecione uma pasta de projeto ou um arquivo .otfi existente.")
        if otfi is not None:
            declared = read_otfi(otfi)
            _check_options(declared)
            if options is not None and options != declared:
                raise ValueError("As opções informadas diferem das opções declaradas no .otfi.")
            options = declared
            dat_name, spr_name = _otfi_filenames(otfi)
            otfi_name = otfi.name
        else:
            if options is None:
                raise ValueError("A pasta não contém .otfi. Informe explicitamente as opções e confirme sprites de 16x16 pixels.")
            _check_options(options)
            dat_name = _default_file(directory, "Tibia.dat", ".dat")
            spr_name = _default_file(directory, "Tibia.spr", ".spr")
            otfi_name = Path(dat_name).with_suffix(".otfi").name
        dat_path = _safe_path(directory, dat_name)
        spr_path = _safe_path(directory, spr_name)
        project = cls(
            read_dat(dat_path.read_bytes(), options), read_spr(spr_path.read_bytes(), options),
            copy.deepcopy(options), directory, dat_name, spr_name, otfi_name,
        )
        project.validate()
        project.server_files = ServerFiles.discover(directory)
        return project

    def validate(self) -> None:
        """Reject broken IDs and structures before anything is written."""
        _check_options(self.options)
        if len(self.dat.categories) != 4:
            raise ValueError("O DAT deve conter as quatro categorias de objetos.")
        if len(self.spr) > min(MAX_SPRITES, 0xFFFFFFFF if self.options.extended else 0xFFFF):
            raise ValueError("A quantidade de sprites excede o formato selecionado; ative IDs estendidos.")
        for category, things in enumerate(self.dat.categories):
            first_id = 100 if category == 0 else 1
            if first_id + len(things) - 1 > 0xFFFF:
                raise ValueError("A quantidade de objetos excede o limite de IDs do DAT.")
            for offset, thing in enumerate(things):
                label = f"Categoria {category}, objeto {thing.id}"
                if thing.category != category or thing.id != first_id + offset:
                    raise ValueError(f"{label}: os IDs devem ser contínuos e pertencer à categoria correta.")
                if not thing.groups or len(thing.groups) > 255:
                    raise ValueError(f"{label}: quantidade inválida de grupos.")
                if len(thing.groups) != 1 and not (self.options.frame_groups and category == 1):
                    raise ValueError(f"{label}: grupos adicionais exigem frame-groups em um outfit.")
                codes = [attribute.code for attribute in thing.attributes]
                if len(codes) != len(set(codes)):
                    raise ValueError(f"{label}: atributo duplicado.")
                for group in thing.groups:
                    dimensions = [group.width, group.height, group.layers, group.pattern_x, group.pattern_y, group.pattern_z, group.frames]
                    if any(type(value) is not int or not 1 <= value <= 255 for value in dimensions):
                        raise ValueError(f"{label}: dimensões, camadas, padrões e quadros devem estar entre 1 e 255.")
                    if len(group.sprites) != group.expected_count():
                        raise ValueError(f"{label}: número de referências de sprites incompatível com as dimensões.")
                    for sprite_id in group.sprites:
                        if type(sprite_id) is not int or not 0 <= sprite_id <= len(self.spr):
                            raise ValueError(f"{label}: referência a uma sprite inexistente ({sprite_id}).")
        # The binary writers validate flag payloads, animation data and ranges.
        write_dat(self.dat, self.options)

    def save(self, directory: str | Path | None = None) -> Path:
        destination = Path(directory).resolve() if directory is not None else self.directory
        if destination is None:
            raise ValueError("Escolha uma pasta para salvar o projeto.")
        names = (self.dat_name, self.spr_name, self.otfi_name)
        targets = [_safe_path(destination, name) for name in names]
        if len({str(path).casefold() for path in targets}) != 3:
            raise ValueError("DAT, SPR e OTFI precisam ter caminhos diferentes.")
        self.validate()
        payloads = (
            write_dat(self.dat, self.options), write_spr(self.spr, self.options),
            write_otfi(self.options, self.dat_name, self.spr_name).encode("utf-8"),
        )
        # Parse the complete pair before staging or touching existing files.
        read_dat(payloads[0], self.options)
        read_spr(payloads[1], self.options)
        linked = self.server_files
        if self.directory is not None and destination != self.directory and linked.configured:
            linked = linked.for_export(destination)
        entries = list(zip(targets, payloads))
        manifest = linked.manifest_bytes(destination)
        if manifest is not None:
            entries.append((_safe_path(destination, MANIFEST_NAME), manifest))
        entries.extend(linked.pending_writes())
        def preflight():
            for name, target in zip(names, targets):
                if _safe_path(destination, name) != target:
                    raise ValueError("O caminho do projeto mudou durante o salvamento.")
            linked.check_conflicts()
        atomic_write_files(entries, destination, preflight=preflight)
        linked.mark_saved()
        self.server_files = linked
        self.directory = destination
        return destination

    def _check_rgba(self, image: Image.Image) -> None:
        if not self.options.transparency and any(image.getchannel("A").histogram()[1:255]):
            raise ValueError("O PNG contém transparência parcial. Use alfa 0/255 ou crie um projeto com transparência RGBA.")

    def _check_capacity(self, count: int) -> None:
        if len(self.spr) + count > min(MAX_SPRITES, 0xFFFFFFFF if self.options.extended else 0xFFFF):
            raise ValueError("As novas sprites excedem o limite de IDs; use um projeto com IDs estendidos.")

    def import_sprite_sheet(self, path: str | Path) -> list[int]:
        image = _open_png(path)
        if image.width % SPRITE_SIZE or image.height % SPRITE_SIZE:
            raise ValueError("A largura e a altura do PNG devem ser múltiplos exatos de 16 pixels.")
        self._check_rgba(image)
        self._check_capacity(image.width * image.height // (SPRITE_SIZE * SPRITE_SIZE))
        tiles = [
            image.crop((x, y, x + SPRITE_SIZE, y + SPRITE_SIZE)).tobytes()
            for y in range(0, image.height, SPRITE_SIZE)
            for x in range(0, image.width, SPRITE_SIZE)
        ]
        return [self.spr.append(tile) for tile in tiles]

    def replace_sprite(self, path: str | Path, sprite_id: int) -> None:
        if type(sprite_id) is not int or not 1 <= sprite_id <= len(self.spr):
            raise ValueError("Escolha uma sprite existente; a sprite 0 é reservada para transparência.")
        image = _open_png(path)
        if image.size != (SPRITE_SIZE, SPRITE_SIZE):
            raise ValueError("Uma sprite deve ter exatamente 16x16 pixels; o editor não redimensiona a imagem.")
        self._check_rgba(image)
        self.spr.set(sprite_id, image.tobytes())

    def render_thing(
        self, thing: Thing, group: int = 0, frame: int = 0,
        pattern_x: int = 0, pattern_y: int = 0, pattern_z: int = 0,
        layer: int | None = None,
    ) -> Image.Image:
        if not 0 <= group < len(thing.groups):
            raise ValueError("Grupo inexistente.")
        shape = thing.groups[group]
        for value, count in ((frame, shape.frames), (pattern_x, shape.pattern_x), (pattern_y, shape.pattern_y), (pattern_z, shape.pattern_z)):
            if not 0 <= value < count:
                raise ValueError("Quadro ou padrão inexistente.")
        if layer is not None and not 0 <= layer < shape.layers:
            raise ValueError("Camada inexistente.")
        _check_image_size(shape.width * SPRITE_SIZE, shape.height * SPRITE_SIZE)
        image = Image.new("RGBA", (shape.width * SPRITE_SIZE, shape.height * SPRITE_SIZE))
        for selected_layer in range(shape.layers) if layer is None else (layer,):
            for y in range(shape.height):
                for x in range(shape.width):
                    index = shape.sprite_index(x, y, selected_layer, pattern_x, pattern_y, pattern_z, frame)
                    sprite = Image.frombytes("RGBA", (SPRITE_SIZE, SPRITE_SIZE), self.spr.get(shape.sprites[index]))
                    image.alpha_composite(sprite, ((shape.width - 1 - x) * SPRITE_SIZE, (shape.height - 1 - y) * SPRITE_SIZE))
        return image

    def export_thing_sheet(self, thing: Thing, path: str | Path, group: int = 0) -> None:
        if not 0 <= group < len(thing.groups):
            raise ValueError("Grupo inexistente.")
        shape = thing.groups[group]
        width = shape.width * SPRITE_SIZE * shape.pattern_x * shape.layers
        height = shape.height * SPRITE_SIZE * shape.frames * shape.pattern_z * shape.pattern_y
        _check_image_size(width, height)
        sheet = Image.new("RGBA", (width, height))
        for frame in range(shape.frames):
            for pz in range(shape.pattern_z):
                for py in range(shape.pattern_y):
                    row = (frame * shape.pattern_z + pz) * shape.pattern_y + py
                    for px in range(shape.pattern_x):
                        for layer in range(shape.layers):
                            tile = self.render_thing(thing, group, frame, px, py, pz, layer)
                            sheet.paste(tile, ((px * shape.layers + layer) * shape.width * SPRITE_SIZE, row * shape.height * SPRITE_SIZE))
        metadata = PngImagePlugin.PngInfo()
        metadata.add_text("backlands-sheet", json.dumps({
            "sprite-size": SPRITE_SIZE, "width": shape.width, "height": shape.height,
            "layers": shape.layers, "pattern-x": shape.pattern_x, "pattern-y": shape.pattern_y,
            "pattern-z": shape.pattern_z, "frames": shape.frames,
            "columns": "pattern-x, layer", "rows": "frame, pattern-z, pattern-y",
        }))
        sheet.save(path, format="PNG", pnginfo=metadata)

    def import_thing_sheet(self, thing: Thing, path: str | Path, group: int = 0) -> list[int]:
        if not 0 <= group < len(thing.groups):
            raise ValueError("Grupo inexistente.")
        shape = thing.groups[group]
        image = _open_png(path)
        expected = (
            shape.width * SPRITE_SIZE * shape.pattern_x * shape.layers,
            shape.height * SPRITE_SIZE * shape.frames * shape.pattern_z * shape.pattern_y,
        )
        if image.size != expected:
            raise ValueError(f"A folha deste grupo deve ter exatamente {expected[0]}x{expected[1]} pixels.")
        self._check_rgba(image)
        tiles: list[tuple[int, bytes]] = []
        for frame in range(shape.frames):
            for pz in range(shape.pattern_z):
                for py in range(shape.pattern_y):
                    row = (frame * shape.pattern_z + pz) * shape.pattern_y + py
                    for px in range(shape.pattern_x):
                        for layer in range(shape.layers):
                            col = px * shape.layers + layer
                            for y in range(shape.height):
                                for x in range(shape.width):
                                    left = (col * shape.width + shape.width - 1 - x) * SPRITE_SIZE
                                    top = (row * shape.height + shape.height - 1 - y) * SPRITE_SIZE
                                    tile = image.crop((left, top, left + SPRITE_SIZE, top + SPRITE_SIZE))
                                    index = shape.sprite_index(x, y, layer, px, py, pz, frame)
                                    tiles.append((index, tile.tobytes()))
        self._check_capacity(len(tiles))
        references = list(shape.sprites)
        added = []
        for index, pixels in tiles:
            sprite_id = self.spr.append(pixels)
            added.append(sprite_id)
            references[index] = sprite_id
        shape.sprites = references
        return added

    def add_thing(self, category: int, duplicate: Thing | None = None) -> Thing:
        if category not in range(4):
            raise ValueError("Categoria inválida.")
        things = self.dat.categories[category]
        new_id = (100 if category == 0 else 1) + len(things)
        if new_id > 0xFFFF:
            raise ValueError("O limite de IDs desta categoria foi atingido.")
        if duplicate is None:
            thing = Thing(id=new_id, category=category)
        else:
            if duplicate.category != category:
                raise ValueError("A cópia deve pertencer à mesma categoria.")
            thing = copy.deepcopy(duplicate)
            thing.id = new_id
            thing.category = category
        things.append(thing)
        return thing
