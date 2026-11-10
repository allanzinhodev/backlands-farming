"""Lossless server item metadata, separate from DAT/Sprite frame groups.

The OTB writer preserves the root, unknown attributes and untouched item nodes.
The XML editor replaces only a selected item span (splitting ranges if needed).
The repository's server uses ClientID as its item ID; legacy OTB ServerID is
exposed separately so callers never have to assume the two are interchangeable.
"""
from __future__ import annotations

import codecs
from dataclasses import dataclass, field
from pathlib import Path
import re
import struct
import xml.etree.ElementTree as ET
from xml.parsers import expat


class ServerItemsError(ValueError):
    """Malformed or unsafe server item metadata."""


def _integer(value: int, maximum: int, label: str, minimum: int = 0) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or not minimum <= value <= maximum:
        raise ServerItemsError(f"{label} deve estar entre {minimum} e {maximum}.")
    return value


@dataclass
class OtbAttribute:
    code: int
    data: bytes


def _read_attributes(data: bytes) -> list[OtbAttribute]:
    attributes = []
    position = 0
    while position < len(data):
        if len(data) - position < 3:
            raise ServerItemsError("Atributo OTB truncado.")
        code, size = struct.unpack_from("<BH", data, position)
        position += 3
        if size > len(data) - position:
            raise ServerItemsError("Conteúdo de atributo OTB truncado.")
        attributes.append(OtbAttribute(code, data[position:position + size]))
        position += size
    return attributes


def _write_attributes(attributes: list[OtbAttribute]) -> bytes:
    result = bytearray()
    for attribute in attributes:
        _integer(attribute.code, 255, "Código do atributo OTB")
        if not isinstance(attribute.data, bytes) or len(attribute.data) > 65535:
            raise ServerItemsError("Conteúdo do atributo OTB inválido ou maior que 65535 bytes.")
        result.extend(struct.pack("<BH", attribute.code, len(attribute.data)))
        result.extend(attribute.data)
    return bytes(result)


def _escape(data: bytes) -> bytes:
    return data.replace(b"\xfd", b"\xfd\xfd").replace(b"\xfe", b"\xfd\xfe").replace(b"\xff", b"\xfd\xff")


@dataclass
class _OtbNode:
    payload: bytes
    raw: bytes
    prefix: bytes
    children: list["_OtbNode"] = field(default_factory=list)


def _read_node(data: bytes, position: int, depth: int = 0) -> tuple[_OtbNode, int]:
    if depth > 64:
        raise ServerItemsError("Árvore OTB profunda demais.")
    if position >= len(data) or data[position] != 0xFE:
        raise ServerItemsError("Início de nó OTB ausente.")
    start = position
    position += 1
    payload = bytearray()
    children = []
    prefix_end = None
    while position < len(data):
        value = data[position]
        if value == 0xFD:
            if children:
                raise ServerItemsError("Propriedades OTB depois de um nó filho.")
            position += 1
            if position >= len(data):
                raise ServerItemsError("Escape OTB truncado.")
            payload.append(data[position])
            position += 1
        elif value == 0xFE:
            if prefix_end is None:
                prefix_end = position
            child, position = _read_node(data, position, depth + 1)
            children.append(child)
        elif value == 0xFF:
            if not payload:
                raise ServerItemsError("Nó OTB sem tipo.")
            if prefix_end is None:
                prefix_end = position
            position += 1
            return _OtbNode(bytes(payload), data[start:position], data[start:prefix_end], children), position
        else:
            if children:
                raise ServerItemsError("Propriedades OTB depois de um nó filho.")
            payload.append(value)
            position += 1
    raise ServerItemsError("Nó OTB sem terminador.")


@dataclass
class OtbItem:
    group: int
    flags: int
    attributes: list[OtbAttribute] = field(default_factory=list)
    _node: _OtbNode | None = field(default=None, repr=False)

    def get_attribute(self, code: int) -> bytes | None:
        # TFS processes attributes in order, so the last occurrence wins.
        return next((attribute.data for attribute in reversed(self.attributes) if attribute.code == code), None)

    def set_attribute(self, code: int, data: bytes) -> None:
        _integer(code, 255, "Código do atributo OTB")
        if not isinstance(data, bytes) or len(data) > 65535:
            raise ServerItemsError("Conteúdo do atributo OTB inválido.")
        if code in (0x10, 0x11) and len(data) != 2:
            raise ServerItemsError("IDs do OTB precisam conter dois bytes.")
        for attribute in reversed(self.attributes):
            if attribute.code == code:
                attribute.data = data
                return
        self.attributes.append(OtbAttribute(code, data))

    def _get_id(self, code: int) -> int | None:
        data = self.get_attribute(code)
        if data is None:
            return None
        if len(data) != 2:
            raise ServerItemsError("ID OTB com tamanho inválido.")
        return struct.unpack("<H", data)[0]

    @property
    def server_id(self) -> int | None:
        return self._get_id(0x10)

    @server_id.setter
    def server_id(self, value: int) -> None:
        self.set_attribute(0x10, struct.pack("<H", _integer(value, 65535, "ServerID", 1)))

    @property
    def client_id(self) -> int | None:
        return self._get_id(0x11)

    @client_id.setter
    def client_id(self, value: int) -> None:
        self.set_attribute(0x11, struct.pack("<H", _integer(value, 65535, "ClientID", 1)))

    def to_bytes(self) -> bytes:
        _integer(self.group, 255, "Grupo OTB")
        _integer(self.flags, 0xFFFFFFFF, "Flags OTB")
        # Also validate attributes modified directly by a caller.
        self.server_id
        self.client_id
        payload = bytes((self.group,)) + struct.pack("<I", self.flags) + _write_attributes(self.attributes)
        if self._node is not None and payload == self._node.payload:
            return self._node.raw
        children = b"" if self._node is None else b"".join(child.raw for child in self._node.children)
        return b"\xfe" + _escape(payload) + children + b"\xff"


class OtbFile:
    def __init__(self, signature: bytes, root: _OtbNode, records: list[OtbItem]) -> None:
        self.signature = signature
        self._root = root
        self.records = records
        self.root_flags = struct.unpack_from("<I", root.payload, 1)[0]
        self.root_attributes = _read_attributes(root.payload[5:])

    @classmethod
    def load(cls, path: str | Path) -> "OtbFile":
        return cls.from_bytes(Path(path).read_bytes())

    @classmethod
    def from_bytes(cls, data: bytes) -> "OtbFile":
        if len(data) < 11:
            raise ServerItemsError("Cabeçalho OTB truncado.")
        root, end = _read_node(data, 4)
        if end != len(data):
            raise ServerItemsError("Dados extras depois da árvore OTB.")
        if len(root.payload) < 5:
            raise ServerItemsError("Cabeçalho raiz OTB truncado.")
        records = []
        for node in root.children:
            if len(node.payload) < 5:
                raise ServerItemsError("Registro OTB truncado.")
            record = OtbItem(node.payload[0], struct.unpack_from("<I", node.payload, 1)[0],
                             _read_attributes(node.payload[5:]), node)
            record.server_id
            record.client_id
            records.append(record)
        return cls(data[:4], root, records)

    def find_client(self, client_id: int) -> list[OtbItem]:
        return [record for record in self.records if record.client_id == client_id]

    def find_server(self, server_id: int) -> OtbItem | None:
        return next((record for record in self.records if record.server_id == server_id), None)

    def create_item(self, server_id: int, client_id: int, group: int = 0, flags: int = 0) -> OtbItem:
        _integer(server_id, 65535, "ServerID", 1)
        _integer(client_id, 65535, "ClientID", 1)
        if self.find_server(server_id) is not None or self.find_client(client_id):
            raise ServerItemsError("Já existe um registro OTB com esse ServerID ou ClientID.")
        record = OtbItem(group, flags)
        record.server_id = server_id
        record.client_id = client_id
        record.to_bytes()
        self.records.append(record)
        return record

    def to_bytes(self) -> bytes:
        if not isinstance(self.signature, bytes) or len(self.signature) != 4:
            raise ServerItemsError("Identificador OTB deve conter quatro bytes.")
        _integer(self.root_flags, 0xFFFFFFFF, "Flags da raiz OTB")
        payload = bytes((self._root.payload[0],)) + struct.pack("<I", self.root_flags) + _write_attributes(self.root_attributes)
        prefix = self._root.prefix if payload == self._root.payload else b"\xfe" + _escape(payload)
        return self.signature + prefix + b"".join(record.to_bytes() for record in self.records) + b"\xff"


@dataclass
class _XmlEntry:
    start: int
    end: int
    first: int
    last: int
    attributes: dict[str, str]


def _tag_end(text: str, start: int) -> int:
    quote = None
    for position in range(start, len(text)):
        value = text[position]
        if quote is not None:
            if value == quote:
                quote = None
        elif value in ('"', "'"):
            quote = value
        elif value == ">":
            return position + 1
    raise ServerItemsError("Tag XML sem terminador.")


def _rewrite_identity(fragment: str, first: int, last: int) -> str:
    """Change only identity attributes in the opening tag, preserving its body."""
    match = re.match(r"<item\b", fragment)
    if match is None:
        raise ServerItemsError("O fragmento deve começar com <item>.")
    position = match.end()
    removals = []
    while position < len(fragment):
        before = position
        while fragment[position].isspace():
            position += 1
        if fragment[position] in "/>":
            break
        attribute = re.match(r"[\w:.-]+", fragment[position:])
        if attribute is None:
            raise ServerItemsError("Atributo XML inválido.")
        name = attribute.group()
        position += len(name)
        while fragment[position].isspace():
            position += 1
        if fragment[position] != "=":
            raise ServerItemsError("Atributo XML sem valor.")
        position += 1
        while fragment[position].isspace():
            position += 1
        quote = fragment[position]
        if quote not in ('"', "'"):
            raise ServerItemsError("Valor XML deve estar entre aspas.")
        position = fragment.index(quote, position + 1) + 1
        if name in ("id", "fromid", "toid"):
            removals.append((before, position))
    for start, end in reversed(removals):
        fragment = fragment[:start] + fragment[end:]
    identity = f' id="{first}"' if first == last else f' fromid="{first}" toid="{last}"'
    return fragment[:match.end()] + identity + fragment[match.end():]


def _reject_doctype(*_args) -> None:
    raise ServerItemsError("DTD e entidades externas não são permitidos em items.xml.")


def _decode_xml(data: bytes) -> tuple[str, str, bytes]:
    if data.startswith(codecs.BOM_UTF8):
        encoding, bom, payload = "utf-8", codecs.BOM_UTF8, data[3:]
    elif data.startswith(codecs.BOM_UTF16_LE):
        encoding, bom, payload = "utf-16-le", codecs.BOM_UTF16_LE, data[2:]
    elif data.startswith(codecs.BOM_UTF16_BE):
        encoding, bom, payload = "utf-16-be", codecs.BOM_UTF16_BE, data[2:]
    elif data.startswith(b"\x00<\x00?"):
        encoding, bom, payload = "utf-16-be", b"", data
    elif data.startswith(b"<\x00?\x00"):
        encoding, bom, payload = "utf-16-le", b"", data
    else:
        declaration = re.match(br"\s*<\?xml\s[^?]*\bencoding\s*=\s*(['\"])([^'\"]+)\1", data[:512])
        encoding = declaration.group(2).decode("ascii") if declaration else "utf-8"
        bom, payload = b"", data
    try:
        return payload.decode(encoding), encoding, bom
    except (LookupError, UnicodeError) as exc:
        raise ServerItemsError(f"Codificação XML inválida: {encoding}.") from exc


class XmlItem:
    def __init__(self, owner: "ItemsXml", item_id: int) -> None:
        self._owner = owner
        self.id = item_id

    @property
    def name(self) -> str:
        return self._owner._by_id[self.id].attributes.get("name", "")

    @property
    def article(self) -> str:
        return self._owner._by_id[self.id].attributes.get("article", "")

    @property
    def plural(self) -> str:
        return self._owner._by_id[self.id].attributes.get("plural", "")

    def to_fragment(self) -> str:
        entry = self._owner._by_id[self.id]
        fragment = self._owner._text[entry.start:entry.end]
        return fragment if entry.first == entry.last else _rewrite_identity(fragment, self.id, self.id)


class ItemsXml:
    @classmethod
    def load(cls, path: str | Path) -> "ItemsXml":
        return cls.from_bytes(Path(path).read_bytes())

    @classmethod
    def from_bytes(cls, data: bytes) -> "ItemsXml":
        result = cls()
        result._original = data
        result._text, result._encoding, result._bom = _decode_xml(data)
        result._original_text = result._text
        result._scan()
        return result

    def _scan(self) -> None:
        # Feed UTF-8 explicitly, regardless of the original declaration. Expat's
        # byte offsets are converted incrementally to Python character offsets.
        data = self._text.encode("utf-8")
        parser = expat.ParserCreate(encoding="utf-8")
        parser.StartDoctypeDeclHandler = _reject_doctype
        parser.ExternalEntityRefHandler = _reject_doctype
        depth = 0
        pending = None
        entries = []
        previous_byte = previous_char = 0

        def character_offset(byte_offset: int) -> int:
            nonlocal previous_byte, previous_char
            previous_char += len(data[previous_byte:byte_offset].decode("utf-8"))
            previous_byte = byte_offset
            return previous_char

        def start(name, attributes):
            nonlocal depth, pending
            if depth == 0:
                if name != "items":
                    raise ServerItemsError("A raiz de items.xml deve ser <items>.")
                self._root_start = character_offset(parser.CurrentByteIndex)
                self._root_open_end = _tag_end(self._text, self._root_start)
            elif depth == 1 and name == "item":
                position = character_offset(parser.CurrentByteIndex)
                try:
                    if "id" in attributes:
                        if "fromid" in attributes or "toid" in attributes:
                            raise ValueError("IDs e intervalos misturados")
                        first = last = int(attributes["id"])
                    else:
                        first, last = int(attributes["fromid"]), int(attributes["toid"])
                    _integer(first, 65535, "ID XML", 1)
                    # Existing TFS data has an inverted 22328..22323 range.
                    # TFS skips it (id <= toId); retain the text and index no IDs.
                    _integer(last, 65535, "ID XML", 1)
                except (KeyError, ValueError) as exc:
                    raise ServerItemsError("Item XML com ID ou intervalo inválido.") from exc
                opening_end = _tag_end(self._text, position)
                self_closing = self._text[position:opening_end].rstrip().endswith("/>")
                pending = (_XmlEntry(position, 0, first, last, dict(attributes)), opening_end, self_closing)
            depth += 1

        def end(name):
            nonlocal depth, pending
            depth -= 1
            if depth == 1 and name == "item" and pending is not None:
                entry, opening_end, self_closing = pending
                entry.end = opening_end if self_closing else _tag_end(self._text, character_offset(parser.CurrentByteIndex))
                entries.append(entry)
                pending = None
            elif depth == 0:
                self._root_close = character_offset(parser.CurrentByteIndex)

        parser.StartElementHandler = start
        parser.EndElementHandler = end
        try:
            parser.Parse(data, True)
        except expat.ExpatError as exc:
            raise ServerItemsError(f"items.xml inválido: {exc}.") from exc
        self._entries = entries
        self._by_id = {item_id: entry for entry in entries for item_id in range(entry.first, entry.last + 1)}

    def find(self, item_id: int) -> XmlItem | None:
        return XmlItem(self, item_id) if item_id in self._by_id else None

    def names_by_id(self) -> dict[int, str]:
        return {item_id: entry.attributes.get("name", "") for item_id, entry in self._by_id.items()}

    def _replace(self, start: int, end: int, replacement: str) -> None:
        previous = self._text
        self._text = previous[:start] + replacement + previous[end:]
        try:
            self._scan()
            # Validate representability before changing the editor's state.
            self._text.encode(self._encoding)
        except (ServerItemsError, UnicodeError) as exc:
            self._text = previous
            self._scan()
            if isinstance(exc, UnicodeError):
                raise ServerItemsError(f"O texto não pode ser salvo na codificação {self._encoding}.") from exc
            raise

    def update_item(self, item_id: int, xml_fragment: str) -> None:
        entry = self._by_id.get(item_id)
        if entry is None:
            raise ServerItemsError(f"Item {item_id} não existe no XML; crie-o explicitamente.")
        fragment = xml_fragment.strip()
        # Validating as a complete items document disallows declarations, DTDs,
        # extra roots and malformed nested attributes without expanding entities.
        validated = ItemsXml.from_bytes(("<items>" + fragment + "</items>").encode("utf-8"))
        if len(validated._entries) != 1 or validated._entries[0].start != len("<items>") or validated._entries[0].end != len("<items>") + len(fragment):
            raise ServerItemsError("Forneça exatamente um elemento <item>.")
        parsed = validated._entries[0]
        if parsed.first != item_id or parsed.last != item_id or "id" not in parsed.attributes:
            raise ServerItemsError("O fragmento deve manter o mesmo id, sem intervalo.")
        source = self._text[entry.start:entry.end]
        if fragment == (source if entry.first == entry.last else _rewrite_identity(source, item_id, item_id)):
            return
        line_start = self._text.rfind("\n", 0, entry.start) + 1
        indent = self._text[line_start:entry.start]
        if not indent.isspace():
            indent = ""
        newline = "\r\n" if "\r\n" in self._text else "\n"
        pieces = []
        if item_id > entry.first:
            pieces.append(_rewrite_identity(source, entry.first, item_id - 1))
        pieces.append(fragment)
        if item_id < entry.last:
            pieces.append(_rewrite_identity(source, item_id + 1, entry.last))
        self._replace(entry.start, entry.end, (newline + indent).join(pieces))

    def create_item(self, item_id: int, name: str = "novo item") -> XmlItem:
        _integer(item_id, 65535, "ID XML", 1)
        if item_id in self._by_id:
            raise ServerItemsError(f"Item {item_id} já existe no XML.")
        fragment = ET.tostring(ET.Element("item", {"id": str(item_id), "name": name}), encoding="unicode")
        newline = "\r\n" if "\r\n" in self._text else "\n"
        opening = self._text[self._root_start:self._root_open_end]
        if opening.rstrip().endswith("/>"):
            replacement = opening.rstrip()[:-2] + ">" + newline + "\t" + fragment + newline + "</items>"
            self._replace(self._root_start, self._root_open_end, replacement)
        else:
            prefix = "" if self._text[:self._root_close].endswith(("\n", "\r")) else newline
            self._replace(self._root_close, self._root_close, prefix + "\t" + fragment + newline)
        return XmlItem(self, item_id)

    def to_bytes(self) -> bytes:
        if self._text == self._original_text:
            return self._original
        try:
            return self._bom + self._text.encode(self._encoding)
        except (LookupError, UnicodeError) as exc:
            raise ServerItemsError(f"Não foi possível salvar a codificação XML {self._encoding}.") from exc
