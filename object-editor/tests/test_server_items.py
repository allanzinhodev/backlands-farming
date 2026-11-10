"""Independent server metadata fixtures and read-only checks of game resources."""
from __future__ import annotations

import codecs
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from backlands_editor.server_items import (
    ItemsXml, OtbAttribute, OtbFile, ServerItemsError,
)


def escaped(payload: bytes) -> bytes:
    # Deliberately independent of the production encoder.
    return b"".join((b"\xfd" if value in (253, 254, 255) else b"") + bytes((value,)) for value in payload)


def attr(code: int, data: bytes) -> bytes:
    return bytes((code,)) + struct.pack("<H", len(data)) + data


def record(server_id: int, client_id: int, *, group: int = 1, flags: int = 3, unknown: bytes = b"") -> bytes:
    payload = bytes((group,)) + struct.pack("<I", flags)
    payload += attr(0x10, struct.pack("<H", server_id))
    payload += attr(0x11, struct.pack("<H", client_id)) + unknown
    return b"\xfe" + escaped(payload) + b"\xff"


def otb_fixture(*records: bytes) -> bytes:
    # Keep an unnecessary escape before zero to verify byte-preservation.
    root = b"\xfe\xfd\x00" + escaped(struct.pack("<I", 0x00FFFEFD)
        + attr(1, struct.pack("<III", 3, 20, 1) + b"custom\0".ljust(128, b"\0"))
        + attr(0x71, b"\xff\xfe\xfd unknown root"))
    return b"OTBI" + root + b"".join(records) + b"\xff"


class OtbTests(unittest.TestCase):
    def test_exact_roundtrip_and_ids_are_distinct(self):
        unknown = attr(0x90, b"\xfd\xfe\xff") + attr(0x90, b"second")
        source = otb_fixture(record(400, 100, unknown=unknown), record(401, 100))
        parsed = OtbFile.from_bytes(source)
        self.assertEqual(parsed.signature, b"OTBI")
        self.assertEqual(parsed.root_flags, 0x00FFFEFD)
        self.assertEqual(len(parsed.find_client(100)), 2)
        self.assertEqual(parsed.find_server(400).client_id, 100)
        self.assertIsNone(parsed.find_server(100))
        self.assertEqual(parsed.records[0].get_attribute(0x90), b"second")
        self.assertEqual(parsed.to_bytes(), source)

    def test_changed_item_preserves_unknown_fields_root_and_other_items(self):
        first = record(400, 100, unknown=attr(0x90, b"\xfd\xfe\xff"))
        second = record(401, 101, unknown=attr(0x91, b"other"))
        source = otb_fixture(first, second)
        parsed = OtbFile.from_bytes(source)
        parsed.records[0].flags = 0xFFFEFDFD
        parsed.records[0].group = 0xFE
        parsed.records[0].set_attribute(0x90, b"new\xfd\xfe\xff")
        changed = parsed.to_bytes()
        self.assertTrue(changed.endswith(second + b"\xff"))
        self.assertEqual(changed[:source.index(first)], source[:source.index(first)])
        loaded = OtbFile.from_bytes(changed)
        self.assertEqual(loaded.records[0].flags, 0xFFFEFDFD)
        self.assertEqual(loaded.records[0].group, 0xFE)
        self.assertEqual(loaded.records[0].get_attribute(0x90), b"new\xfd\xfe\xff")
        self.assertEqual(loaded.records[0].server_id, 400)
        self.assertEqual(loaded.records[1].get_attribute(0x91), b"other")

    def test_direct_unknown_attributes_and_nested_nodes_survive(self):
        first = record(100, 100)
        nested = b"\xfe\x7ehello\xff"
        source = otb_fixture(first[:-1] + nested + b"\xff")
        parsed = OtbFile.from_bytes(source)
        self.assertEqual(parsed.to_bytes(), source)
        parsed.records[0].attributes.append(OtbAttribute(0x88, b"new"))
        changed = parsed.to_bytes()
        self.assertIn(nested, changed)
        self.assertEqual(OtbFile.from_bytes(changed).records[0].get_attribute(0x88), b"new")

    def test_creation_is_explicit_and_rejects_collisions(self):
        parsed = OtbFile.from_bytes(otb_fixture(record(400, 100)))
        created = parsed.create_item(101, 101, group=2, flags=64)
        self.assertEqual((created.server_id, created.client_id, created.group, created.flags), (101, 101, 2, 64))
        self.assertEqual(len(OtbFile.from_bytes(parsed.to_bytes()).records), 2)
        for sid, cid in [(400, 200), (200, 100), (0, 300), (65536, 300)]:
            with self.subTest(sid=sid, cid=cid), self.assertRaises(ServerItemsError):
                parsed.create_item(sid, cid)
        self.assertEqual(len(parsed.records), 2)

    def test_truncated_tree_attributes_and_invalid_ranges_are_rejected(self):
        source = otb_fixture(record(400, 100))
        for end in range(len(source)):
            with self.subTest(end=end), self.assertRaises(ServerItemsError):
                OtbFile.from_bytes(source[:end])
        for bad in (source + b"junk", b"\0\0\0\0\xfe\x00\0\0\0\0\x01\x05\0x\xff",
                    otb_fixture(b"\xfe\x01\0\0\0\0\x10\x01\0x\xff")):
            with self.subTest(bad=bad[-20:]), self.assertRaises(ServerItemsError):
                OtbFile.from_bytes(bad)
        parsed = OtbFile.from_bytes(source)
        parsed.records[0].flags = -1
        with self.assertRaises(ServerItemsError):
            parsed.to_bytes()
        with self.assertRaises(ServerItemsError):
            parsed.records[0].set_attribute(0x11, b"one")

    def test_load_path(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "items.otb"
            path.write_bytes(otb_fixture(record(100, 100)))
            self.assertEqual(OtbFile.load(path).find_client(100)[0].server_id, 100)


XML = '''<?xml version="1.0" encoding="UTF-8"?>\r
<items custom="preserved">\r
\t<!-- a fake <item id="9"/> is a comment -->\r
\t<item id="99" name="before" custom="&quot;&gt;" />\r
\t<item fromid='100' toid='104' article="a" name="flower" plural="flowers" custom="keep > this">\r
\t\t<!-- inside the range -->\r
\t\t<attribute key="field" value="poison"><attribute key="ticks" value="5000" /></attribute>\r
\t\t<unknown><![CDATA[<item id="999" />]]></unknown>\r
\t</item>\r
\t<item id="105" name="after"><attribute key="description" value="say &quot;hello&quot;" /></item>\r
\t<extension key="unknown" />\r
</items>\r
'''


class ItemsXmlTests(unittest.TestCase):
    def test_roundtrip_range_lookup_and_special_xml_tokens(self):
        source = XML.encode()
        parsed = ItemsXml.from_bytes(source)
        self.assertEqual(parsed.to_bytes(), source)
        self.assertIsNone(parsed.find(9))
        self.assertIsNone(parsed.find(999))
        item = parsed.find(102)
        self.assertEqual((item.name, item.article, item.plural), ("flower", "a", "flowers"))
        fragment = item.to_fragment()
        self.assertIn('id="102"', fragment)
        self.assertNotIn("fromid", fragment)
        self.assertIn("<!-- inside the range -->", fragment)
        self.assertIn('<attribute key="ticks" value="5000" />', fragment)
        self.assertEqual(parsed.names_by_id()[104], "flower")
        parsed.update_item(102, fragment)
        self.assertEqual(parsed.to_bytes(), source, "applying unchanged range member must not split it")

    def test_range_edit_splits_only_target_and_preserves_outer_text(self):
        parsed = ItemsXml.from_bytes(XML.encode())
        original_item = parsed.find(102)
        old_fragment = original_item.to_fragment()
        parsed.update_item(102, old_fragment.replace('name="flower"', 'name="red flower"'))
        changed = parsed.to_bytes().decode()
        original_range_start = XML.index("\t<item fromid")
        original_after_start = XML.index('\r\n\t<item id="105"')
        self.assertTrue(changed.startswith(XML[:original_range_start]))
        self.assertTrue(changed.endswith(XML[original_after_start:]))
        self.assertIn('fromid="100" toid="101"', changed)
        self.assertIn('fromid="103" toid="104"', changed)
        self.assertEqual(original_item.name, "red flower")
        self.assertEqual([parsed.find(i).name for i in range(100, 105)],
                         ["flower", "flower", "red flower", "flower", "flower"])
        self.assertEqual(changed.count("<!-- inside the range -->"), 3)
        ET.fromstring(changed)

    def test_range_edges_and_single_id_edit(self):
        for selected in (100, 104, 99):
            parsed = ItemsXml.from_bytes(XML.encode())
            fragment = parsed.find(selected).to_fragment()
            parsed.update_item(selected, fragment.replace('name="', 'name="edited '))
            loaded = ItemsXml.from_bytes(parsed.to_bytes())
            self.assertTrue(loaded.find(selected).name.startswith("edited "))
            for item_id in (100, 101, 102, 103, 104):
                if item_id != selected:
                    self.assertEqual(loaded.find(item_id).name, "flower")

    def test_update_validates_identity_single_node_and_does_not_mutate_on_error(self):
        parsed = ItemsXml.from_bytes(XML.encode())
        for fragment in ('<item id="103" name="wrong" />', '<item fromid="102" toid="102" />',
                         '<item id="102" /><item id="103" />', '<item id="102"><broken></item>',
                         '<!--prefix--><item id="102" />', '<item id="102" /><other />',
                         '<!DOCTYPE item [<!ENTITY a "bad">]><item id="102" name="&a;" />'):
            with self.subTest(fragment=fragment), self.assertRaises(ServerItemsError):
                parsed.update_item(102, fragment)
            self.assertEqual(parsed.to_bytes(), XML.encode())
        with self.assertRaises(ServerItemsError):
            parsed.update_item(500, '<item id="500" />')

    def test_creating_metadata_preserves_existing_text_and_escapes_name(self):
        parsed = ItemsXml.from_bytes(XML.encode())
        created = parsed.create_item(106, 'arvore & "flor"')
        self.assertEqual(created.name, 'arvore & "flor"')
        changed = parsed.to_bytes().decode()
        self.assertTrue(changed.startswith(XML[:XML.index("</items>")]))
        self.assertIn("&amp;", changed)
        self.assertIn("&quot;", changed)
        with self.assertRaises(ServerItemsError):
            parsed.create_item(102)
        self.assertEqual(len(parsed.names_by_id()), 8)

    def test_creating_empty_root_with_attributes(self):
        parsed = ItemsXml.from_bytes(b'<?xml version="1.0"?><items custom="yes" />')
        parsed.create_item(100)
        self.assertEqual(ET.fromstring(parsed.to_bytes()).attrib, {"custom": "yes"})
        self.assertEqual(parsed.find(100).name, "novo item")

    def test_encodings_and_bom_are_retained_after_edit(self):
        for encoding, declaration, bom in (("utf-8", "utf-8", b""), ("utf-8", "UTF-8", codecs.BOM_UTF8),
                                          ("iso-8859-1", "iso-8859-1", b""),
                                          ("utf-16-le", "UTF-16", codecs.BOM_UTF16_LE),
                                          ("utf-16-be", "UTF-16", codecs.BOM_UTF16_BE)):
            with self.subTest(encoding=encoding, bom=bom):
                text = f'<?xml version="1.0" encoding="{declaration}"?>\r\n<items><item id="100" name="café" /></items>'
                source = bom + text.encode(encoding)
                parsed = ItemsXml.from_bytes(source)
                self.assertEqual(parsed.to_bytes(), source)
                parsed.update_item(100, '<item id="100" name="açaí" />')
                changed = parsed.to_bytes()
                self.assertTrue(changed.startswith(bom + text[:text.index("<item id")].encode(encoding)))
                self.assertEqual(ItemsXml.from_bytes(changed).find(100).name, "açaí")

    def test_unrepresentable_text_reverts_edit(self):
        source = b'<?xml version="1.0" encoding="ascii"?><items><item id="100" /></items>'
        parsed = ItemsXml.from_bytes(source)
        with self.assertRaises(ServerItemsError):
            parsed.update_item(100, '<item id="100" name="açaí" />')
        self.assertEqual(parsed.to_bytes(), source)

    def test_invalid_xml_dtd_and_ids_are_rejected(self):
        for source in (b'<wrong />', b'<items><item name="missing" /></items>',
                       b'<items><item id="65536" /></items>', b'<items><item id="0" /></items>',
                       b'<!DOCTYPE items SYSTEM "file:///private"><items />',
                       b'<!DOCTYPE items [<!ENTITY x "bad">]><items><item id="100" name="&x;" /></items>'):
            with self.subTest(source=source), self.assertRaises(ServerItemsError):
                ItemsXml.from_bytes(source)

    def test_inverted_range_is_preserved_and_not_indexed_as_in_tfs(self):
        source = b'<items><item fromid="22328" toid="22323" name="existing inverted range" /></items>'
        parsed = ItemsXml.from_bytes(source)
        self.assertEqual(parsed.names_by_id(), {})
        self.assertEqual(parsed.to_bytes(), source)


class ActualGameMetadataTests(unittest.TestCase):
    def test_real_files_read_and_roundtrip_without_writing(self):
        directory = Path(__file__).resolve().parents[2] / "server/data/items"
        if not (directory / "items.otb").is_file() or not (directory / "items.xml").is_file():
            self.skipTest("Recursos opcionais do servidor não estão presentes")
        otb_source = (directory / "items.otb").read_bytes()
        xml_source = (directory / "items.xml").read_bytes()
        otb = OtbFile.from_bytes(otb_source)
        xml = ItemsXml.from_bytes(xml_source)
        self.assertEqual(len(otb.records), 54652)
        self.assertEqual(otb.find_client(100)[0].client_id, 100)
        self.assertEqual(xml.find(108).name, xml.find(109).name)
        self.assertEqual(otb.to_bytes(), otb_source)
        self.assertEqual(xml.to_bytes(), xml_source)
        xml.update_item(108, xml.find(108).to_fragment().replace('name="flowers"', 'name="test flower"'))
        self.assertEqual(xml.find(108).name, "test flower")
        self.assertEqual(xml.find(109).name, "flowers")
        self.assertEqual((directory / "items.otb").read_bytes(), otb_source)
        self.assertEqual((directory / "items.xml").read_bytes(), xml_source)


if __name__ == "__main__":
    unittest.main()
