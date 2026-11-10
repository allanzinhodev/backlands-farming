"""Associations between one visual project and the server's item catalogs."""
from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import struct

from .server_items import ItemsXml, OtbFile

MANIFEST_NAME = "backlands-project.json"


class ServerFiles:
    """Keep edits in memory until the visual project is saved successfully.

    The server in this repository uses client IDs for XML lookup. Legacy OTB
    server IDs are retained as metadata and are never used to select XML nodes.
    """

    def __init__(self, xml_path: Path | None = None, otb_path: Path | None = None):
        self.xml_path = Path(xml_path).resolve() if xml_path else None
        self.otb_path = Path(otb_path).resolve() if otb_path else None
        self.xml = None
        self.otb = None
        self.issues = []
        self._originals = {}
        self._edited_xml = self._edited_otb = False
        self._manifest = {}
        self._manifest_error = None
        self._names = {}

    @property
    def configured(self):
        return bool(self.xml_path or self.otb_path or self._manifest)

    @classmethod
    def associate(cls, xml_path: Path | None, otb_path: Path | None) -> "ServerFiles":
        result = cls(xml_path, otb_path)
        result._load(strict=True)
        return result

    @classmethod
    def discover(cls, directory: Path) -> "ServerFiles":
        directory = directory.resolve()
        manifest = directory / MANIFEST_NAME
        if manifest.exists():
            result = cls()
            try:
                settings = json.loads(manifest.read_text(encoding="utf-8"))
                if not isinstance(settings, dict) or settings.get("version") != 1:
                    raise ValueError("Versão do projeto de assets não suportada.")
                server = settings.get("server", {})
                if not isinstance(server, dict) or server.get("id-mode", "client") != "client":
                    raise ValueError("Este servidor usa o ClientID para os itens XML.")
                def resolve(key):
                    value = server.get(key)
                    if value is None:
                        return None
                    if not isinstance(value, str) or not value.strip() or "\x00" in value:
                        raise ValueError(f"Caminho inválido: {key}.")
                    return (directory / value).resolve()
                result.xml_path = resolve("items-xml")
                result.otb_path = resolve("items-otb")
                result._manifest = settings
                result._load(strict=False)
            except (OSError, ValueError) as error:
                result._manifest_error = str(error)
                result.issues.append(f"Associação inválida: {error}")
            return result
        candidates = [directory]
        candidates.extend(parent / "server" / "data" / "items" for parent in (directory, *directory.parents))
        for candidate in candidates:
            xml, otb = candidate / "items.xml", candidate / "items.otb"
            if xml.is_file() or otb.is_file():
                result = cls(xml if xml.is_file() else None, otb if otb.is_file() else None)
                result._load(strict=False)
                return result
        return cls()

    def _load(self, strict):
        for kind, parser in (("xml", ItemsXml), ("otb", OtbFile)):
            path = getattr(self, f"{kind}_path")
            if not path:
                continue
            try:
                data = path.read_bytes()
                catalog = parser.from_bytes(data)
                setattr(self, kind, catalog)
                self._originals[path] = data
            except (OSError, ValueError) as error:
                if strict:
                    raise ValueError(f"Não foi possível associar {path}: {error}") from error
                self.issues.append(f"{path.name}: {error}")
        self.refresh_names()

    def refresh_names(self):
        self._names = self.xml.names_by_id() if self.xml else {}

    def item_name(self, client_id):
        return self._names.get(client_id)

    def xml_item(self, client_id):
        return self.xml.find(client_id) if self.xml else None

    def otb_items(self, client_id):
        return self.otb.find_client(client_id) if self.otb else []

    def update_xml(self, client_id, fragment):
        if self.xml is None:
            raise ValueError("Associe um items.xml válido primeiro.")
        before = self.xml.to_bytes()
        self.xml.update_item(client_id, fragment)
        self._edited_xml = self._edited_xml or before != self.xml.to_bytes()
        self.refresh_names()

    def update_otb(self, client_id, group, flags, attributes=None):
        matches = self.otb_items(client_id)
        if len(matches) != 1:
            raise ValueError("O ClientID deve ter exatamente um registro no OTB para ser editado.")
        if type(group) is not int or not 0 <= group <= 14 or type(flags) is not int or not 0 <= flags <= 0xFFFFFFFF:
            raise ValueError("Grupo OTB deve estar entre 0 e 14; flags devem caber em 32 bits.")
        # Validate the complete candidate before changing the loaded record.
        candidate = copy.deepcopy(matches[0])
        candidate.group, candidate.flags = group, flags
        for code, value in (attributes or {}).items():
            if code in (0x10, 0x11):
                raise ValueError("Os IDs associados são preservados; não altere ServerID ou ClientID.")
            if value is None:
                candidate.attributes = [attr for attr in candidate.attributes if attr.code != code]
            else:
                expected = {0x14: 2, 0x21: 2, 0x2A: 4, 0x2B: 1, 0x2D: 2}.get(code)
                if expected is not None and len(value) != expected:
                    raise ValueError(f"O atributo OTB 0x{code:02X} exige {expected} bytes.")
                candidate.set_attribute(code, value)
        original = matches[0]
        changed = original.to_bytes() != candidate.to_bytes()
        original.group, original.flags = candidate.group, candidate.flags
        original.attributes = candidate.attributes
        self._edited_otb = self._edited_otb or changed

    def copy_for_edit(self, client_id):
        """Copy only the selected mutable record; catalog spans are immutable."""
        candidate = copy.copy(self)
        candidate._originals = dict(self._originals)
        candidate._manifest = copy.deepcopy(self._manifest)
        candidate.issues = list(self.issues)
        if self.xml is not None:
            # XML edits replace the text and rebuild indexes, never mutate spans.
            candidate.xml = copy.copy(self.xml)
        if self.otb is not None:
            candidate.otb = copy.copy(self.otb)
            candidate.otb.records = [copy.deepcopy(record) if record.client_id == client_id else record
                                     for record in self.otb.records]
        return candidate

    def for_export(self, directory):
        """Save As bundles independent server catalogs alongside exported visuals."""
        candidate = copy.copy(self)
        candidate._originals = {}
        candidate._manifest = copy.deepcopy(self._manifest)
        for kind in ("xml", "otb"):
            catalog = getattr(self, kind)
            if catalog is None:
                if getattr(self, f"{kind}_path") is not None:
                    raise ValueError("Reassocie os arquivos ausentes antes de exportar o projeto.")
                continue
            path = (directory / "server-items" / f"items.{kind}").resolve()
            setattr(candidate, f"{kind}_path", path)
            candidate._originals[path] = path.read_bytes() if path.exists() else None
            setattr(candidate, f"_edited_{kind}", True)
        return candidate

    def create_missing(self, client_id, name="novo item"):
        if not 100 <= client_id <= 65535:
            raise ValueError("Itens visuais usam IDs entre 100 e 65535.")
        if self.xml is None or self.otb is None:
            raise ValueError("Associe items.xml e items.otb válidos antes de criar registros.")
        missing_xml = self.xml.find(client_id) is None
        missing_otb = not self.otb.find_client(client_id)
        if missing_otb and self.otb.find_server(client_id) is not None:
            raise ValueError("O ServerID legado está ocupado; a criação não pode sobrescrever outro registro.")
        # XML serialization validates the name/encoding before mutating either catalog.
        if missing_xml:
            self.xml.create_item(client_id, name)
            self._edited_xml = True
        if missing_otb:
            self.otb.create_item(client_id, client_id, group=0, flags=0)
            self._edited_otb = True
        self.refresh_names()

    def sync_otb(self, thing):
        """Explicitly copy the DAT's supported physical flags to its OTB record."""
        if thing.category != 0:
            raise ValueError("Somente itens têm registros OTB.")
        matches = self.otb_items(thing.id)
        if len(matches) != 1:
            raise ValueError("Crie um único registro OTB para este ClientID primeiro.")
        record = matches[0]
        attrs = {attribute.code: attribute.values for attribute in thing.attributes}
        mapping = {12: 0, 14: 1, 15: 2, 25: 3, 7: 4, 16: 5, 5: 7,
                   20: 15, 17: 16, 18: 17, 19: 18, 31: 23, 6: 26}
        flags = record.flags
        for code, bit in mapping.items():
            flags = flags | (1 << bit) if code in attrs else flags & ~(1 << bit)
        flags = flags & ~(1 << 6) if 13 in attrs else flags | (1 << 6)
        flags = flags | (1 << 14) if 8 in attrs or 9 in attrs else flags & ~(1 << 14)
        flags = flags | (1 << 24) if any(g.frames > 1 for g in thing.groups) else flags & ~(1 << 24)
        top_order = 1 if 1 in attrs else 2 if 2 in attrs else 3 if 3 in attrs else 0
        flags = flags | (1 << 13) if top_order else flags & ~(1 << 13)
        group = 1 if 0 in attrs else 2 if 4 in attrs else 12 if 10 in attrs else 11 if 11 in attrs else 0
        payloads = {0x14: None, 0x2A: None, 0x21: None, 0x2B: bytes((top_order,)) if top_order else None}
        if 0 in attrs:
            payloads[0x14] = struct.pack("<H", attrs[0][0])
        if 21 in attrs:
            payloads[0x2A] = struct.pack("<HH", *attrs[21])
        if 28 in attrs:
            payloads[0x21] = struct.pack("<H", attrs[28][0])
        self.update_otb(thing.id, group, flags, payloads)

    def manifest_bytes(self, directory):
        if self._manifest_error:
            raise ValueError(self._manifest_error + " Associe os arquivos novamente antes de salvar.")
        if not self.configured:
            return None
        settings = copy.deepcopy(self._manifest)
        settings["version"] = 1
        server = settings.setdefault("server", {})
        def relative(path):
            if path is None:
                return None
            try:
                return Path(os.path.relpath(path, directory)).as_posix()
            except ValueError:
                return str(path)
        server.update({"id-mode": "client", "items-xml": relative(self.xml_path), "items-otb": relative(self.otb_path)})
        return (json.dumps(settings, ensure_ascii=False, indent=2) + "\n").encode("utf-8")

    def pending_writes(self):
        writes = []
        for kind, parser in (("xml", ItemsXml), ("otb", OtbFile)):
            if not getattr(self, f"_edited_{kind}"):
                continue
            catalog = getattr(self, kind)
            path = getattr(self, f"{kind}_path")
            data = catalog.to_bytes()
            parser.from_bytes(data)
            if data != self._originals.get(path):
                writes.append((path, data))
        self.check_conflicts()
        return writes

    def check_conflicts(self):
        for kind in ("xml", "otb"):
            if getattr(self, f"_edited_{kind}"):
                path = getattr(self, f"{kind}_path")
                current = path.read_bytes() if path.exists() else None
                if current != self._originals.get(path):
                    raise ValueError(f"{path.name} foi alterado fora do editor. Reassocie os arquivos antes de salvar.")

    def mark_saved(self):
        for kind in ("xml", "otb"):
            if getattr(self, f"_edited_{kind}"):
                path = getattr(self, f"{kind}_path")
                self._originals[path] = getattr(self, kind).to_bytes()
                setattr(self, f"_edited_{kind}", False)
