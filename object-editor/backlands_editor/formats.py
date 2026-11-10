"""Strict, lossless codecs for the project's 8.60 DAT and 16×16 SPR files.

The binary layouts follow ObjectBuilder's MetadataReader5/MetadataWriter5 and
SpriteReader. Feature switches are explicit: they cannot be inferred reliably
from the signatures. Sprite IDs start at one; zero always means transparent.
"""

from __future__ import annotations

from dataclasses import dataclass, field, replace
from itertools import product
from pathlib import Path
import re
import struct


SPRITE_SIZE = 16
SPRITE_BYTES = SPRITE_SIZE * SPRITE_SIZE * 4
MAX_SPRITES_PER_GROUP = 262_144
MAX_SPRITES = 2_000_000
CATEGORY_NAMES = ("Itens", "Outfits", "Efeitos", "Projéteis")
CATEGORY_STARTS = (100, 1, 1, 1)


class FormatError(ValueError):
    """An unsupported or damaged asset was rejected before it could be saved."""


@dataclass
class FormatOptions:
    extended: bool = False
    transparency: bool = False
    frame_durations: bool = False
    frame_groups: bool = False
    sprite_size: int = SPRITE_SIZE

    def validate(self) -> None:
        if self.sprite_size != SPRITE_SIZE:
            raise FormatError("Este editor exige sprites de 16×16 pixels (sprite-size: 16).")
        for name in ("extended", "transparency", "frame_durations", "frame_groups"):
            if not isinstance(getattr(self, name), bool):
                raise FormatError(f"Opção {name} deve ser true ou false.")


# Codes are the on-disk 8.60 codes, without the 10.10 flag shift.
FLAG_SPECS = {
    0: ("Chão", ("Velocidade",)),
    1: ("Borda de chão", ()),
    2: ("Embaixo", ()),
    3: ("Em cima", ()),
    4: ("Contêiner", ()),
    5: ("Empilhável", ()),
    6: ("Usar sempre", ()),
    7: ("Uso múltiplo", ()),
    8: ("Escrita", ("Limite de caracteres",)),
    9: ("Escrita única", ("Limite de caracteres",)),
    10: ("Recipiente de fluido", ()),
    11: ("Fluido", ()),
    12: ("Bloqueia passagem", ()),
    13: ("Imóvel", ()),
    14: ("Bloqueia projéteis", ()),
    15: ("Bloqueia caminho", ()),
    16: ("Coletável", ()),
    17: ("Pendurável", ()),
    18: ("Vertical", ()),
    19: ("Horizontal", ()),
    20: ("Rotacionável", ()),
    21: ("Luz", ("Intensidade", "Cor")),
    22: ("Não ocultar", ()),
    23: ("Translúcido", ()),
    24: ("Deslocamento", ("X", "Y")),
    25: ("Elevação", ("Altura",)),
    26: ("Corpo deitado", ()),
    27: ("Animar sempre", ()),
    28: ("Minimapa", ("Cor",)),
    29: ("Ajuda de lente", ("Valor",)),
    30: ("Chão completo", ()),
    31: ("Ignorar olhar", ()),
    32: ("Roupa", ("Slot",)),
    33: ("Mercado", ("Categoria", "Negociar como", "Exibir como", "Nome", "Vocação", "Nível")),
    34: ("Usável", ("Valor",)),
    35: ("Embrulhável", ()),
    36: ("Desembrulhável", ()),
    37: ("Efeito superior", ()),
}
_FLAG_FORMATS = {code: "H" * len(fields) for code, (_, fields) in FLAG_SPECS.items()}
_FLAG_FORMATS[24] = "hh"


@dataclass
class Attribute:
    code: int
    values: tuple = ()


_DIMENSIONS = ("width", "height", "layers", "pattern_x", "pattern_y", "pattern_z", "frames")


@dataclass
class FrameGroup:
    width: int = 1
    height: int = 1
    exact_size: int = SPRITE_SIZE
    layers: int = 1
    pattern_x: int = 1
    pattern_y: int = 1
    pattern_z: int = 1
    frames: int = 1
    sprites: list[int] = field(default_factory=lambda: [0])
    group_type: int = 0
    animation_mode: int = 0
    loop_count: int = 0
    start_frame: int = 0
    durations: list[tuple[int, int]] = field(default_factory=list)

    def expected_count(self) -> int:
        count = 1
        for name in _DIMENSIONS:
            value = getattr(self, name)
            if not isinstance(value, int) or not 1 <= value <= 255:
                raise FormatError(f"Dimensão {name} deve estar entre 1 e 255.")
            count *= value
            if count > MAX_SPRITES_PER_GROUP:
                raise FormatError(f"Um grupo não pode ter mais de {MAX_SPRITES_PER_GROUP} sprites.")
        return count

    def sprite_index(self, x: int, y: int, layer: int, px: int, py: int, pz: int, frame: int) -> int:
        coordinates = (x, y, layer, px, py, pz, frame)
        for value, name in zip(coordinates, _DIMENSIONS):
            if not isinstance(value, int) or not 0 <= value < getattr(self, name):
                raise IndexError(f"Coordenada {name} fora do grupo: {value}.")
        return ((((((frame * self.pattern_z + pz) * self.pattern_y + py)
                    * self.pattern_x + px) * self.layers + layer)
                  * self.height + y) * self.width + x)

    def resize(self, **dimensions: int) -> None:
        """Resize in place, retaining sprite references at surviving coordinates."""
        allowed = {*_DIMENSIONS, "exact_size"}
        if set(dimensions) - allowed:
            raise TypeError("Dimensões desconhecidas: " + ", ".join(set(dimensions) - allowed))
        new = replace(self, **dimensions)
        if not isinstance(new.exact_size, int) or not 1 <= new.exact_size <= 255:
            raise FormatError("Tamanho exato deve estar entre 1 e 255.")
        new.sprites = [0] * new.expected_count()
        if len(self.sprites) != self.expected_count():
            raise FormatError("Quantidade de sprites não corresponde às dimensões do grupo.")
        ranges = [range(min(getattr(self, name), getattr(new, name))) for name in _DIMENSIONS]
        for coordinates in product(*ranges):
            new.sprites[new.sprite_index(*coordinates)] = self.sprites[self.sprite_index(*coordinates)]
        new.durations = list(self.durations[:new.frames])
        if new.durations:
            new.durations.extend([(100, 100)] * (new.frames - len(new.durations)))
        if new.start_frame >= new.frames:
            new.start_frame = 0
        for name in _DIMENSIONS:
            setattr(self, name, getattr(new, name))
        self.sprites = new.sprites
        self.durations = new.durations
        self.start_frame = new.start_frame
        self.exact_size = new.exact_size


@dataclass
class Thing:
    id: int
    category: int
    attributes: list[Attribute] = field(default_factory=list)
    groups: list[FrameGroup] = field(default_factory=lambda: [FrameGroup()])


@dataclass
class DatFile:
    signature: int = 0x4C2C7993
    categories: list[list[Thing]] = field(default_factory=lambda: [[], [], [], []])


class _Reader:
    def __init__(self, data: bytes, context: str):
        self.data = data
        self.pos = 0
        self.context = context

    def take(self, size: int) -> bytes:
        if size < 0 or self.pos + size > len(self.data):
            raise FormatError(f"{self.context} truncado no byte {self.pos} (faltam {size} bytes).")
        value = self.data[self.pos:self.pos + size]
        self.pos += size
        return value

    def unpack(self, fmt: str):
        values = struct.unpack("<" + fmt, self.take(struct.calcsize("<" + fmt)))
        return values[0] if len(values) == 1 else values


def _pack(fmt: str, *values) -> bytes:
    try:
        return struct.pack("<" + fmt, *values)
    except (struct.error, TypeError, OverflowError) as exc:
        raise FormatError(f"Valor inválido para {fmt}: {values!r}.") from exc


def _options(options: FormatOptions | None) -> FormatOptions:
    options = options if options is not None else FormatOptions()
    options.validate()
    return options


def read_dat(data: bytes, options: FormatOptions | None = None) -> DatFile:
    options = _options(options)
    reader = _Reader(data, "DAT")
    signature = reader.unpack("I")
    counts = reader.unpack("HHHH")
    if counts[0] < 99:
        raise FormatError("DAT inválido: o último ID de item deve ser pelo menos 99.")
    dat = DatFile(signature)
    for category, last_id in enumerate(counts):
        for thing_id in range(CATEGORY_STARTS[category], last_id + 1):
            reader.context = f"DAT ({CATEGORY_NAMES[category]} #{thing_id})"
            attrs = []
            while True:
                code = reader.unpack("B")
                if code == 255:
                    break
                if code not in FLAG_SPECS:
                    raise FormatError(f"{reader.context}: atributo desconhecido 0x{code:02X} no byte {reader.pos - 1}.")
                if len(attrs) >= 255:
                    raise FormatError(f"{reader.context}: lista de atributos sem terminador.")
                if code == 33:
                    prefix = reader.unpack("HHH")
                    name = reader.take(reader.unpack("H")).decode("latin-1")
                    suffix = reader.unpack("HH")
                    values = (*prefix, name, *suffix)
                else:
                    fmt = _FLAG_FORMATS[code]
                    values = struct.unpack("<" + fmt, reader.take(struct.calcsize("<" + fmt)))
                attrs.append(Attribute(code, values))
            grouped = options.frame_groups and category == 1
            group_count = reader.unpack("B") if grouped else 1
            if not group_count:
                raise FormatError(f"{reader.context}: nenhum grupo de animação.")
            groups = []
            for _ in range(group_count):
                group_type = reader.unpack("B") if grouped else 0
                width, height = reader.unpack("BB")
                exact_size = reader.unpack("B") if width > 1 or height > 1 else SPRITE_SIZE
                layers, px, py, pz, frames = reader.unpack("BBBBB")
                group = FrameGroup(width, height, exact_size, layers, px, py, pz, frames, group_type=group_type)
                count = group.expected_count()
                if not 1 <= exact_size <= 255:
                    raise FormatError(f"{reader.context}: tamanho exato deve estar entre 1 e 255.")
                if frames > 1 and options.frame_durations:
                    group.animation_mode = reader.unpack("B")
                    group.loop_count = reader.unpack("i")
                    group.start_frame = reader.unpack("b")
                    group.durations = [reader.unpack("II") for _ in range(frames)]
                    _validate_animation(group)
                fmt = "I" if options.extended else "H"
                group.sprites = list(struct.unpack("<" + fmt * count, reader.take(struct.calcsize("<" + fmt) * count)))
                groups.append(group)
            dat.categories[category].append(Thing(thing_id, category, attrs, groups))
    if reader.pos != len(data):
        raise FormatError(f"DAT contém {len(data) - reader.pos} bytes extras; confira as opções de formato.")
    return dat


def _validate_animation(group: FrameGroup) -> None:
    if group.animation_mode not in (0, 1):
        raise FormatError("Modo de animação deve ser 0 ou 1.")
    if not -1 <= group.start_frame < group.frames:
        raise FormatError("Frame inicial deve ser -1 (aleatório) ou um frame existente.")
    if len(group.durations) != group.frames:
        raise FormatError("Informe uma duração mínima e máxima para cada frame.")
    for minimum, maximum in group.durations:
        if not 0 <= minimum <= maximum <= 0xFFFFFFFF:
            raise FormatError("Durações exigem 0 ≤ mínimo ≤ máximo ≤ 4294967295 ms.")


def write_dat(dat: DatFile, options: FormatOptions | None = None) -> bytes:
    options = _options(options)
    if len(dat.categories) != 4:
        raise FormatError("DAT deve conter as quatro categorias.")
    counts = [len(things) + CATEGORY_STARTS[category] - 1 for category, things in enumerate(dat.categories)]
    result = bytearray(_pack("IHHHH", dat.signature, *counts))
    for category, things in enumerate(dat.categories):
        for expected_id, thing in enumerate(things, CATEGORY_STARTS[category]):
            if thing.id != expected_id or thing.category != category:
                raise FormatError("IDs DAT devem ser sequenciais dentro de cada categoria.")
            if len(thing.attributes) > 255:
                raise FormatError("Um objeto não pode ter mais de 255 atributos.")
            for attr in thing.attributes:
                if attr.code not in FLAG_SPECS:
                    raise FormatError(f"Atributo desconhecido: {attr.code}.")
                if len(attr.values) != len(FLAG_SPECS[attr.code][1]):
                    raise FormatError(f"Quantidade de valores inválida no atributo {attr.code}.")
                result.extend(_pack("B", attr.code))
                if attr.code == 33:
                    category_id, trade_as, show_as, name, vocation, level = attr.values
                    try:
                        name_bytes = name.encode("latin-1")
                    except (AttributeError, UnicodeEncodeError) as exc:
                        raise FormatError("Nome de mercado deve usar caracteres Latin-1.") from exc
                    result.extend(_pack("HHHH", category_id, trade_as, show_as, len(name_bytes)))
                    result.extend(name_bytes)
                    result.extend(_pack("HH", vocation, level))
                else:
                    result.extend(_pack(_FLAG_FORMATS[attr.code], *attr.values))
            result.append(255)
            grouped = options.frame_groups and category == 1
            if not thing.groups or len(thing.groups) > 255:
                raise FormatError("Um objeto exige entre 1 e 255 grupos.")
            if not grouped and len(thing.groups) != 1:
                raise FormatError("Múltiplos grupos exigem frame-groups em outfits.")
            if grouped:
                result.extend(_pack("B", len(thing.groups)))
            for group in thing.groups:
                count = group.expected_count()
                if len(group.sprites) != count:
                    raise FormatError(f"Objeto #{thing.id}: esperado {count} sprites, recebido {len(group.sprites)}.")
                if grouped:
                    result.extend(_pack("B", group.group_type))
                result.extend(_pack("BB", group.width, group.height))
                if group.width > 1 or group.height > 1:
                    if not 1 <= group.exact_size <= 255:
                        raise FormatError("Tamanho exato deve estar entre 1 e 255.")
                    result.extend(_pack("B", group.exact_size))
                result.extend(_pack("BBBBB", group.layers, group.pattern_x, group.pattern_y, group.pattern_z, group.frames))
                if group.frames > 1 and options.frame_durations:
                    _validate_animation(group)
                    result.extend(_pack("Bib", group.animation_mode, group.loop_count, group.start_frame))
                    for durations in group.durations:
                        result.extend(_pack("II", *durations))
                result.extend(_pack(("I" if options.extended else "H") * count, *group.sprites))
    return bytes(result)


class SpriteFile:
    """Lazy RGBA sprite collection retaining every original compressed record."""

    def __init__(self, signature: int = 0x4C220594, sprites: list[bytes | None] | None = None):
        self.signature = signature
        self.sprites = list(sprites) if sprites is not None else []
        self._records: list[bytes | None] = [None] * len(self.sprites)
        self._source_data: bytes | None = None
        self._source_options: FormatOptions | None = None
        self._source_signature = signature
        self._dirty: set[int] = set(range(1, len(self.sprites) + 1))

    def __len__(self) -> int:
        return len(self.sprites)

    def get(self, sprite_id: int) -> bytes:
        if sprite_id == 0:
            return bytes(SPRITE_BYTES)
        if not isinstance(sprite_id, int) or not 1 <= sprite_id <= len(self):
            raise IndexError(f"Sprite inexistente: {sprite_id}.")
        rgba = self.sprites[sprite_id - 1]
        record = self._records[sprite_id - 1]
        if rgba is None and record is not None:
            rgba = _decode_rle(record[5:], self._source_options.transparency)
            self.sprites[sprite_id - 1] = rgba
        return rgba if rgba is not None else bytes(SPRITE_BYTES)

    def set(self, sprite_id: int, rgba: bytes | None) -> None:
        if not isinstance(sprite_id, int) or not 1 <= sprite_id <= len(self):
            raise IndexError(f"Sprite inexistente ou reservado: {sprite_id}.")
        if rgba is not None:
            rgba = bytes(rgba)
            if len(rgba) != SPRITE_BYTES:
                raise FormatError("Sprite deve ter exatamente 16×16 pixels RGBA (1024 bytes).")
        if self.get(sprite_id) == (rgba if rgba is not None else bytes(SPRITE_BYTES)):
            return
        self.sprites[sprite_id - 1] = rgba
        self._records[sprite_id - 1] = None
        self._dirty.add(sprite_id)

    def append(self, rgba: bytes | None) -> int:
        if len(self) >= MAX_SPRITES:
            raise FormatError(f"Limite de {MAX_SPRITES} sprites atingido.")
        if rgba is not None:
            rgba = bytes(rgba)
            if len(rgba) != SPRITE_BYTES:
                raise FormatError("Sprite deve ter exatamente 16×16 pixels RGBA (1024 bytes).")
        self.sprites.append(rgba)
        self._records.append(None)
        self._dirty.add(len(self))
        return len(self)


def _decode_rle(payload: bytes, transparency: bool, decode: bool = True) -> bytes | None:
    reader = _Reader(payload, "RLE da sprite")
    pixels = 0
    channels = 4 if transparency else 3
    rgba = bytearray(SPRITE_BYTES) if decode else None
    while reader.pos < len(payload):
        transparent, colored = reader.unpack("HH")
        if transparent + colored == 0:
            raise FormatError("RLE inválido: bloco sem pixels.")
        pixels += transparent
        if pixels + colored > SPRITE_SIZE * SPRITE_SIZE:
            raise FormatError("Sprite excede os 256 pixels de uma imagem 16×16.")
        colors = reader.take(colored * channels)
        if decode:
            if transparency:
                rgba[pixels * 4:(pixels + colored) * 4] = colors
            else:
                for index in range(colored):
                    target = (pixels + index) * 4
                    rgba[target:target + 3] = colors[index * 3:index * 3 + 3]
                    rgba[target + 3] = 255
        pixels += colored
    return bytes(rgba) if decode else None


def _encode_rle(rgba: bytes, transparency: bool) -> bytes:
    if len(rgba) != SPRITE_BYTES:
        raise FormatError("Sprite deve ter 1024 bytes RGBA (16×16 pixels).")
    if not transparency and any(alpha not in (0, 255) for alpha in rgba[3::4]):
        raise FormatError("Alpha parcial exige transparency: true; a imagem não foi alterada.")
    result = bytearray()
    position = 0
    total = SPRITE_SIZE * SPRITE_SIZE

    def blank(index: int) -> bool:
        pixel = rgba[index * 4:index * 4 + 4]
        return pixel == b"\0\0\0\0" if transparency else pixel[3] == 0

    while position < total:
        transparent = 0
        while position < total and blank(position):
            transparent += 1
            position += 1
        start = position
        while position < total and not blank(position):
            position += 1
        colored = position - start
        if not colored:
            break  # A transparent tail is implicit in the SPR format.
        result.extend(_pack("HH", transparent, colored))
        if transparency:
            result.extend(rgba[start * 4:position * 4])
        else:
            for index in range(start, position):
                result.extend(rgba[index * 4:index * 4 + 3])
    return bytes(result)


def read_spr(data: bytes, options: FormatOptions | None = None) -> SpriteFile:
    options = _options(options)
    reader = _Reader(data, "SPR")
    signature = reader.unpack("I")
    count = reader.unpack("I" if options.extended else "H")
    if count > MAX_SPRITES:
        raise FormatError(f"SPR declara mais de {MAX_SPRITES} sprites.")
    addresses = struct.unpack("<" + "I" * count, reader.take(count * 4))
    table_end = reader.pos
    records: dict[int, bytes] = {}
    intervals = []
    for sprite_id, address in enumerate(addresses, 1):
        if not address or address in records:
            continue
        if address < table_end or address + 5 > len(data):
            raise FormatError(f"SPR #{sprite_id}: endereço fora da área de sprites ({address}).")
        length = struct.unpack_from("<H", data, address + 3)[0]
        end = address + 5 + length
        if end > len(data):
            raise FormatError(f"SPR #{sprite_id}: registro truncado.")
        record = data[address:end]
        try:
            _decode_rle(record[5:], options.transparency, decode=False)
        except FormatError as exc:
            raise FormatError(f"SPR #{sprite_id}: {exc}") from exc
        records[address] = record
        intervals.append((address, end))
    previous_end = table_end
    for start, end in sorted(intervals):
        if start < previous_end:
            raise FormatError("SPR contém registros sobrepostos.")
        if start != previous_end:
            raise FormatError("SPR contém bytes sem referência entre os registros.")
        previous_end = end
    if previous_end != len(data):
        raise FormatError("SPR contém bytes extras após os registros; confira o formato.")
    sprites = SpriteFile(signature, [None] * count)
    sprites._records = [records.get(address) for address in addresses]
    sprites._source_data = bytes(data)
    sprites._source_options = replace(options)
    sprites._source_signature = signature
    sprites._dirty.clear()
    return sprites


def write_spr(sprites: SpriteFile, options: FormatOptions | None = None) -> bytes:
    options = _options(options)
    count = len(sprites)
    if count > MAX_SPRITES or (not options.extended and count > 65535):
        raise FormatError("Quantidade de sprites excede o formato; ative extended para mais de 65535 IDs.")
    if (sprites._source_data is not None and not sprites._dirty
            and count == len(sprites._records) and sprites.signature == sprites._source_signature
            and options == sprites._source_options):
        return sprites._source_data
    header = _pack("I" + ("I" if options.extended else "H"), sprites.signature, count)
    table = bytearray(count * 4)
    body = bytearray()
    base = len(header) + len(table)
    preserve_records = sprites._source_options is not None and options.transparency == sprites._source_options.transparency
    for index in range(count):
        record = sprites._records[index] if preserve_records and index + 1 not in sprites._dirty else None
        if record is None:
            payload = _encode_rle(sprites.get(index + 1), options.transparency)
            if not payload:
                continue
            record = b"\xff\x00\xff" + _pack("H", len(payload)) + payload
        struct.pack_into("<I", table, index * 4, base + len(body))
        body.extend(record)
    return header + bytes(table) + bytes(body)


def read_otfi(path: str | Path) -> FormatOptions:
    """Read the DatSpr feature section, requiring the project's explicit size."""
    text = Path(path).read_text(encoding="utf-8-sig")
    values: dict[str, str] = {}
    in_section = False
    found_section = False
    for line_number, raw_line in enumerate(text.splitlines(), 1):
        line = raw_line.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if not line[0].isspace():
            in_section = line.strip().rstrip(":") == "DatSpr"
            found_section = found_section or in_section
            continue
        if in_section:
            match = re.fullmatch(r"\s+([\w-]+)\s*:\s*(.*?)\s*", line)
            if not match:
                raise FormatError(f"OTFI inválido na linha {line_number}.")
            key, value = match.groups()
            if key in values:
                raise FormatError(f"Opção OTFI repetida: {key}.")
            values[key] = value
    if not found_section:
        raise FormatError("OTFI não contém a seção DatSpr.")
    if "sprite-size" not in values:
        raise FormatError("OTFI precisa declarar sprite-size: 16; arquivos de 32×32 não são compatíveis.")
    try:
        size = int(values["sprite-size"])
    except ValueError as exc:
        raise FormatError("sprite-size deve ser 16.") from exc
    switches = {}
    for key in ("extended", "transparency", "frame-durations", "frame-groups"):
        value = values.get(key, "false").lower()
        if value not in ("true", "false"):
            raise FormatError(f"OTFI {key} deve ser true ou false.")
        switches[key.replace("-", "_")] = value == "true"
    if "sprite-data-size" in values and values["sprite-data-size"] != "1024":
        raise FormatError("sprite-data-size deve ser 1024 para sprites 16×16 RGBA.")
    controller = values.get("metadata-controller", "default").strip("\"'")
    if controller != "default":
        raise FormatError(f"metadata-controller não suportado: {controller}.")
    options = FormatOptions(**switches, sprite_size=size)
    options.validate()
    return options


def write_otfi(options: FormatOptions, dat_name: str = "Tibia.dat", spr_name: str = "Tibia.spr") -> str:
    options = _options(options)
    for name in (dat_name, spr_name):
        if not name or any(char in name for char in "\r\n#"):
            raise FormatError("Nome de arquivo OTFI inválido.")
    return ("DatSpr\n"
            f"  extended: {str(options.extended).lower()}\n"
            f"  transparency: {str(options.transparency).lower()}\n"
            f"  frame-durations: {str(options.frame_durations).lower()}\n"
            f"  frame-groups: {str(options.frame_groups).lower()}\n"
            "  sprite-size: 16\n"
            "  sprite-data-size: 1024\n"
            f"  metadata-file: {dat_name}\n"
            f"  sprites-file: {spr_name}\n")
