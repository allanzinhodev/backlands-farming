"""Server associations and coordinated Project saves, using private fixtures."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import struct
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from backlands_editor import transactions
from backlands_editor.formats import Attribute, FrameGroup, Thing
from backlands_editor.project import Project
from backlands_editor.server_items import ItemsXml, OtbFile
from backlands_editor.server_project import MANIFEST_NAME, ServerFiles


def _escaped(data: bytes) -> bytes:
    return b"".join((b"\xfd" if value >= 253 else b"") + bytes((value,)) for value in data)


def _otb_record(server_id: int, client_id: int) -> bytes:
    # Unknown flag bit 31 and attribute 0x90 must survive edits and DAT sync.
    payload = b"\x00" + struct.pack("<I", 0x80000100)
    payload += b"\x10\x02\x00" + struct.pack("<H", server_id)
    payload += b"\x11\x02\x00" + struct.pack("<H", client_id)
    payload += b"\x90\x03\x00\xfd\xfe\xff"
    return b"\xfe" + _escaped(payload) + b"\xff"


def make_otb(*pairs: tuple[int, int]) -> bytes:
    version = struct.pack("<III", 3, 20, 1) + b"Test OTB".ljust(128, b"\0")
    root = b"\xfe\x00\x00\x00\x00\x00\x01\x8c\x00" + _escaped(version)
    return b"\0\0\0\0" + root + b"".join(_otb_record(*pair) for pair in pairs) + b"\xff"


SERVER_XML = (b'<?xml version="1.0" encoding="utf-8"?>\r\n<items>\r\n'
              b'\t<!-- preserved outside selected range -->\r\n'
              b'\t<item fromid="100" toid="102" article="a" name="flower" custom="keep">\r\n'
              b'\t\t<attribute key="weight" value="10" /><unknown preserve="yes" />\r\n'
              b'\t</item>\r\n'
              b'\t<item id="400" name="legacy ID must not select this" />\r\n'
              b'</items>\r\n')


def make_visual_files(directory: Path) -> dict[Path, bytes]:
    directory.mkdir(parents=True, exist_ok=True)
    header = struct.pack("<I4H", 0x4C2C7993, 102, 0, 0, 0)
    # Three single-frame 16px item slots, all using transparent sprite zero.
    thing = b"\xff\x01\x01\x01\x01\x01\x01\x01\x00\x00"
    files = {
        directory / "Assets.dat": header + thing * 3,
        directory / "Assets.spr": struct.pack("<IH", 0x4C220594, 0),
        directory / "Assets.otfi": (
            "DatSpr\n  extended: false\n  transparency: false\n"
            "  frame-durations: false\n  frame-groups: false\n"
            "  metadata-file: Assets.dat\n  sprites-file: Assets.spr\n"
            "  sprite-size: 16\n  sprite-data-size: 1024\n").encode(),
    }
    for path, data in files.items():
        path.write_bytes(data)
    return files


class ServerProjectTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        self.repo = self.root / "game"
        self.assets = self.repo / "assets" / "860"
        self.server = self.repo / "server" / "data" / "items"
        self.visual_originals = make_visual_files(self.assets)
        self.server.mkdir(parents=True)
        self.xml_path = self.server / "items.xml"
        self.otb_path = self.server / "items.otb"
        self.xml_path.write_bytes(SERVER_XML)
        self.otb_original = make_otb((400, 100), (401, 101), (402, 102))
        self.otb_path.write_bytes(self.otb_original)

    def tearDown(self):
        self.temporary.cleanup()

    def project(self) -> Project:
        return Project.load(self.assets)

    def assert_no_stages(self):
        self.assertFalse(list(self.root.rglob(".backlands-stage-*")))

    def assert_server_originals(self):
        self.assertEqual(self.xml_path.read_bytes(), SERVER_XML)
        self.assertEqual(self.otb_path.read_bytes(), self.otb_original)

    def edit_xml(self, project: Project, selected: int = 101):
        linked = project.server_files
        linked.update_xml(selected, linked.xml_item(selected).to_fragment().replace('name="flower"', 'name="red flower"'))

    def edit_everything(self, project: Project):
        project.dat.categories[0][0].attributes = [Attribute(0, (150,))]
        sprite_id = project.spr.append(bytes((10, 20, 30, 255)) * 256)
        project.dat.categories[0][0].groups[0].sprites = [sprite_id]
        project.options.extended = True
        self.edit_xml(project)
        project.server_files.update_otb(100, 1, 0x80000141, {0x14: struct.pack("<H", 150)})

    def test_new_project_has_empty_association(self):
        project = Project.new()
        self.assertFalse(project.server_files.configured)
        self.assertIsNone(project.server_files.manifest_bytes(self.assets))
        self.assertEqual(project.server_files.pending_writes(), [])

    def test_auto_association_uses_client_id_for_xml_despite_different_legacy_id(self):
        project = self.project()
        linked = project.server_files
        self.assertEqual(linked.xml_path, self.xml_path)
        self.assertEqual(linked.otb_path, self.otb_path)
        self.assertEqual(linked.otb_items(100)[0].server_id, 400)
        self.assertEqual(linked.xml_item(100).name, "flower")
        self.assertEqual(linked.item_name(100), "flower")
        self.assertEqual(linked.xml_item(400).name, "legacy ID must not select this")
        self.assertEqual(linked.pending_writes(), [])
        self.assertFalse((self.assets / MANIFEST_NAME).exists())
        self.assert_server_originals()

    def test_manifest_is_relative_and_keeps_links_when_whole_game_moves(self):
        project = self.project()
        project.save()
        manifest = json.loads((self.assets / MANIFEST_NAME).read_bytes())
        self.assertEqual(manifest["version"], 1)
        self.assertEqual(manifest["server"]["id-mode"], "client")
        self.assertEqual(manifest["server"]["items-xml"], "../../server/data/items/items.xml")
        self.assertEqual(manifest["server"]["items-otb"], "../../server/data/items/items.otb")
        moved = self.root / "moved-game"
        shutil.copytree(self.repo, moved)
        moved_project = Project.load(moved / "assets" / "860")
        self.assertEqual(moved_project.server_files.xml_path, moved / "server/data/items/items.xml")
        self.assertEqual(moved_project.server_files.item_name(100), "flower")
        self.assert_server_originals()

    def test_manifest_has_precedence_and_preserves_unknown_settings(self):
        custom = self.repo / "custom"
        custom.mkdir()
        custom_xml = custom / "items.xml"
        custom_otb = custom / "items.otb"
        custom_xml.write_bytes(b'<items><item id="100" name="custom catalog" /></items>')
        custom_otb.write_bytes(make_otb((700, 100)))
        settings = {
            "version": 1, "future-setting": {"keep": [1, 2]},
            "server": {"id-mode": "client", "items-xml": "../../custom/items.xml",
                       "items-otb": "../../custom/items.otb", "future-server": "keep"},
        }
        (self.assets / MANIFEST_NAME).write_text(json.dumps(settings), encoding="utf-8")
        project = self.project()
        self.assertEqual(project.server_files.item_name(100), "custom catalog")
        self.assertEqual(project.server_files.otb_items(100)[0].server_id, 700)
        project.save()
        saved = json.loads((self.assets / MANIFEST_NAME).read_bytes())
        self.assertEqual(saved["future-setting"], settings["future-setting"])
        self.assertEqual(saved["server"]["future-server"], "keep")

    def test_visual_save_does_not_replace_or_back_up_untouched_server_files(self):
        project = self.project()
        original_stats = {path: path.stat().st_mtime_ns for path in (self.xml_path, self.otb_path)}
        replacements = []
        real_replace = transactions.os.replace

        def record_replace(source, target):
            replacements.append(Path(target))
            return real_replace(source, target)

        with mock.patch.object(transactions.os, "replace", side_effect=record_replace):
            project.save()
        self.assertNotIn(self.xml_path, replacements)
        self.assertNotIn(self.otb_path, replacements)
        self.assertFalse((self.server / ".backups").exists())
        for path, timestamp in original_stats.items():
            self.assertEqual(path.stat().st_mtime_ns, timestamp)
        self.assert_server_originals()
        self.assert_no_stages()

    def test_noop_range_edit_does_not_back_up_or_rewrite_server_catalog(self):
        project = self.project()
        linked = project.server_files
        linked.update_xml(101, linked.xml_item(101).to_fragment())
        self.assertEqual(linked.pending_writes(), [])
        project.save()
        self.assertFalse((self.server / ".backups").exists())
        self.assert_server_originals()

    def test_xml_range_edit_stays_in_memory_until_save_and_preserves_siblings(self):
        project = self.project()
        self.edit_xml(project)
        self.assertEqual(project.server_files.item_name(101), "red flower")
        self.assertEqual([project.server_files.xml_item(i).name for i in (100, 102)], ["flower", "flower"])
        self.assert_server_originals()
        project.save()
        saved = ItemsXml.load(self.xml_path)
        self.assertEqual([saved.find(i).name for i in (100, 101, 102)], ["flower", "red flower", "flower"])
        self.assertIn(b'<!-- preserved outside selected range -->', self.xml_path.read_bytes())
        self.assertEqual(saved.find(100).to_fragment().count('preserve="yes"'), 1)
        xml_backups = list((self.server / ".backups").glob("*/items.xml"))
        self.assertEqual(len(xml_backups), 1)
        self.assertEqual(xml_backups[0].read_bytes(), SERVER_XML)
        self.assertFalse(list((self.server / ".backups").glob("*/items.otb")))
        self.assertEqual(self.otb_path.read_bytes(), self.otb_original)
        self.assertEqual(project.server_files.pending_writes(), [])

    def test_otb_edit_preserves_ids_unknown_data_and_backups_then_clears_pending(self):
        project = self.project()
        project.server_files.update_otb(100, 2, 0xA0000040, {0x14: struct.pack("<H", 200)})
        self.assertEqual(project.server_files.pending_writes(), [(self.otb_path, project.server_files.otb.to_bytes())])
        self.assert_server_originals()
        project.save()
        saved = OtbFile.load(self.otb_path)
        selected = saved.find_client(100)[0]
        self.assertEqual((selected.server_id, selected.client_id, selected.group, selected.flags), (400, 100, 2, 0xA0000040))
        self.assertEqual(selected.get_attribute(0x90), b"\xfd\xfe\xff")
        self.assertEqual(selected.get_attribute(0x14), struct.pack("<H", 200))
        self.assertEqual(self.xml_path.read_bytes(), SERVER_XML)
        self.assertEqual(project.server_files.pending_writes(), [])
        copies = list((self.server / ".backups").glob("*/items.otb"))
        self.assertEqual(len(copies), 1)
        self.assertEqual(copies[0].read_bytes(), self.otb_original)

    def test_save_as_copies_server_links_and_pending_edits_without_changing_originals(self):
        project = self.project()
        destination = self.root / "export" / "new-assets"
        self.edit_xml(project)
        project.save(destination)
        self.assertEqual(project.directory, destination)
        exported = Project.load(destination)
        self.assertEqual(exported.server_files.xml_path, destination / "server-items/items.xml")
        self.assertEqual(exported.server_files.otb_path, destination / "server-items/items.otb")
        self.assertEqual(exported.server_files.item_name(101), "red flower")
        manifest = json.loads((destination / MANIFEST_NAME).read_bytes())
        self.assertEqual(manifest["server"]["items-xml"], "server-items/items.xml")
        self.assertEqual(manifest["server"]["items-otb"], "server-items/items.otb")
        for path, data in self.visual_originals.items():
            self.assertEqual(path.read_bytes(), data)
        self.assertFalse((self.assets / MANIFEST_NAME).exists())
        self.assert_server_originals()
        self.assertFalse((self.server / ".backups").exists())

    def test_external_change_rejects_save_before_dat_or_manifest_is_touched(self):
        project = self.project()
        self.edit_everything(project)
        external = SERVER_XML + b"<!-- changed outside -->"
        self.xml_path.write_bytes(external)
        with mock.patch.object(transactions.os, "replace") as replace:
            with self.assertRaisesRegex(ValueError, "fora do editor"):
                project.save()
        replace.assert_not_called()
        for path, data in self.visual_originals.items():
            self.assertEqual(path.read_bytes(), data)
        self.assertEqual(self.xml_path.read_bytes(), external)
        self.assertEqual(self.otb_path.read_bytes(), self.otb_original)
        self.assertFalse((self.assets / MANIFEST_NAME).exists())
        self.assertFalse((self.assets / ".backups").exists())
        self.assert_no_stages()

    def test_external_change_during_staging_is_rejected_before_replacements(self):
        project = self.project()
        self.edit_everything(project)
        external = SERVER_XML + b"<!-- concurrent edit during staging -->"
        real_fsync = transactions.os.fsync
        changed = False

        def change_once(descriptor):
            nonlocal changed
            if not changed:
                changed = True
                self.xml_path.write_bytes(external)
            return real_fsync(descriptor)

        with mock.patch.object(transactions.os, "fsync", side_effect=change_once):
            with mock.patch.object(transactions.os, "replace") as replace:
                with self.assertRaisesRegex(ValueError, "fora do editor"):
                    project.save()
        replace.assert_not_called()
        self.assertTrue(changed)
        for path, data in self.visual_originals.items():
            self.assertEqual(path.read_bytes(), data)
        self.assertEqual(self.xml_path.read_bytes(), external)
        self.assertEqual(self.otb_path.read_bytes(), self.otb_original)
        self.assert_no_stages()

    def test_late_server_failure_rolls_back_every_visual_and_server_file_and_manifest(self):
        for failed_name in ("items.xml", "items.otb"):
            with self.subTest(failed_name=failed_name):
                # Baseline has a manifest too, so its restoration is checked.
                project = self.project()
                project.save()
                paths = [*self.visual_originals, self.assets / MANIFEST_NAME, self.xml_path, self.otb_path]
                originals = {path: path.read_bytes() for path in paths}
                self.edit_everything(project)
                real_replace = transactions.os.replace
                failed = False
                attempted = []

                def fail_once(source, target):
                    nonlocal failed
                    target = Path(target)
                    attempted.append(target)
                    if target.name == failed_name and not failed:
                        failed = True
                        raise OSError("server catalog locked")
                    return real_replace(source, target)

                with mock.patch.object(transactions.os, "replace", side_effect=fail_once):
                    with self.assertRaisesRegex(OSError, "server catalog locked"):
                        project.save()
                self.assertTrue(failed)
                self.assertIn(self.assets / "Assets.dat", attempted)
                self.assertIn(self.assets / "Assets.spr", attempted)
                self.assertIn(self.assets / MANIFEST_NAME, attempted)
                for path, data in originals.items():
                    self.assertEqual(path.read_bytes(), data, str(path))
                    backups = list((path.parent / ".backups").glob("*/" + path.name))
                    self.assertTrue(any(backup.read_bytes() == data for backup in backups), str(path))
                self.assertTrue(project.server_files.pending_writes(), "failed save must retain in-memory edits")
                self.assert_no_stages()

    def test_first_save_failure_removes_new_manifest_and_preserves_original_files(self):
        project = self.project()
        self.edit_everything(project)
        real_replace = transactions.os.replace
        failed = False

        def fail_once(source, target):
            nonlocal failed
            if Path(target) == self.xml_path and not failed:
                failed = True
                raise OSError("XML unavailable")
            return real_replace(source, target)

        with mock.patch.object(transactions.os, "replace", side_effect=fail_once):
            with self.assertRaisesRegex(OSError, "XML unavailable"):
                project.save()
        self.assertFalse((self.assets / MANIFEST_NAME).exists())
        for path, data in self.visual_originals.items():
            self.assertEqual(path.read_bytes(), data)
        self.assert_server_originals()
        self.assert_no_stages()

    def test_missing_configured_file_is_reported_without_blocking_visual_load(self):
        settings = {"version": 1, "server": {"id-mode": "client", "items-xml": "missing/items.xml",
                                               "items-otb": "../../server/data/items/items.otb"}}
        (self.assets / MANIFEST_NAME).write_text(json.dumps(settings), encoding="utf-8")
        project = self.project()
        self.assertEqual(project.dat.categories[0][0].id, 100)
        self.assertEqual(project.options.sprite_size, 16)
        self.assertTrue(project.server_files.issues)
        self.assertIsNone(project.server_files.xml)
        self.assertIsNotNone(project.server_files.otb)
        self.assertIsNone(project.server_files.item_name(100))
        self.assertEqual(project.server_files.pending_writes(), [])
        self.assert_server_originals()

    def test_invalid_manifest_and_broken_catalog_do_not_prevent_visual_load(self):
        manifest = self.assets / MANIFEST_NAME
        for data in (b"{broken json", b'{"version":99}',
                     b'{"version":1,"server":{"id-mode":"server"}}'):
            with self.subTest(data=data):
                manifest.write_bytes(data)
                project = self.project()
                self.assertTrue(project.server_files.issues)
                self.assertEqual(project.dat.categories[0][0].id, 100)
                with self.assertRaises(ValueError):
                    project.save()
                self.assertEqual(manifest.read_bytes(), data)
        manifest.unlink()
        self.xml_path.write_bytes(b"<items><broken>")
        project = self.project()
        self.assertTrue(project.server_files.issues)
        self.assertIsNotNone(project.server_files.otb)
        self.assertIsNone(project.server_files.xml)
        self.assertEqual(project.dat.categories[0][0].id, 100)

    def test_explicit_association_rejects_bad_catalog_without_writing(self):
        missing = self.root / "missing.xml"
        with self.assertRaises(ValueError):
            ServerFiles.associate(missing, self.otb_path)
        with self.assertRaises(ValueError):
            ServerFiles.associate(self.otb_path, self.otb_path)
        self.assert_server_originals()

    def test_create_missing_is_explicit_and_never_overwrites_legacy_collision(self):
        project = self.project()
        added = project.add_thing(0)
        self.assertEqual(added.id, 103)
        linked = project.server_files
        self.assertIsNone(linked.xml_item(103))
        self.assertEqual(linked.otb_items(103), [])
        linked.create_missing(103, "new tool")
        self.assertEqual(linked.item_name(103), "new tool")
        self.assertEqual((linked.otb_items(103)[0].server_id, linked.otb_items(103)[0].client_id), (103, 103))
        linked.create_missing(103, "must keep existing name")
        self.assertEqual(linked.item_name(103), "new tool")
        self.assert_server_originals()
        self.otb_path.write_bytes(make_otb((400, 100), (103, 999)))
        collision = ServerFiles.associate(self.xml_path, self.otb_path)
        original_xml = collision.xml.to_bytes()
        original_otb = collision.otb.to_bytes()
        with self.assertRaises(ValueError):
            collision.create_missing(103)
        self.assertEqual(collision.xml.to_bytes(), original_xml)
        self.assertEqual(collision.otb.to_bytes(), original_otb)

    def test_sync_dat_flags_is_explicit_preserves_unknowns_and_uses_animation(self):
        project = self.project()
        linked = project.server_files
        thing = project.dat.categories[0][0]
        thing.attributes = [Attribute(0, (150,)), Attribute(5), Attribute(12), Attribute(13),
                            Attribute(21, (5, 215)), Attribute(28, (80,))]
        thing.groups = [FrameGroup(frames=2, sprites=[0, 0])]
        self.assertEqual(linked.otb_items(100)[0].flags, 0x80000100)
        linked.sync_otb(thing)
        selected = linked.otb_items(100)[0]
        self.assertEqual(selected.group, 1)
        self.assertTrue(selected.flags & (1 << 0))
        self.assertTrue(selected.flags & (1 << 7))
        self.assertFalse(selected.flags & (1 << 6))
        self.assertTrue(selected.flags & (1 << 24))
        self.assertTrue(selected.flags & (1 << 31))
        self.assertTrue(selected.flags & (1 << 8))
        self.assertEqual(selected.get_attribute(0x14), struct.pack("<H", 150))
        self.assertEqual(selected.get_attribute(0x2A), struct.pack("<HH", 5, 215))
        self.assertEqual(selected.get_attribute(0x21), struct.pack("<H", 80))
        self.assertEqual(selected.get_attribute(0x90), b"\xfd\xfe\xff")
        self.assertEqual((selected.server_id, selected.client_id), (400, 100))
        with self.assertRaises(ValueError):
            linked.sync_otb(Thing(id=1, category=1))
        self.assert_server_originals()

    def test_otb_validation_rejects_id_changes_and_bad_payloads_without_partial_edits(self):
        linked = self.project().server_files
        original = linked.otb.to_bytes()
        invalid = [(-1, 0, {}), (15, 0, {}), (0, -1, {}), (0, 0x100000000, {}),
                   (0, 1, {0x10: struct.pack("<H", 900)}), (0, 1, {0x11: None}),
                   (0, 1, {0x14: b"x"}), (0, 1, {0x21: b"x"}),
                   (0, 1, {0x2A: b"xx"}), (0, 1, {0x2B: b"xx"}),
                   (0, 1, {0x2D: b"x"})]
        for group, flags, attributes in invalid:
            with self.subTest(group=group, flags=flags, attributes=attributes):
                with self.assertRaises(ValueError):
                    linked.update_otb(100, group, flags, attributes)
                self.assertEqual(linked.otb.to_bytes(), original)
                self.assertEqual(linked.pending_writes(), [])
        linked.update_otb(100, 0, 0, {0x14: b"\x96\x00"})
        linked.update_otb(100, 0, 0, {0x14: None})
        self.assertIsNone(linked.otb_items(100)[0].get_attribute(0x14))
        self.assertEqual(linked.otb_items(100)[0].get_attribute(0x90), b"\xfd\xfe\xff")

    def test_candidate_edit_isolated_until_caller_accepts_both_catalogs(self):
        original = self.project().server_files
        xml_before, otb_before = original.xml.to_bytes(), original.otb.to_bytes()
        candidate = original.copy_for_edit(101)
        candidate.update_xml(101, candidate.xml_item(101).to_fragment().replace('name="flower"', 'name="candidate"'))
        candidate.update_otb(101, 2, 64)
        candidate.create_missing(103, "candidate item")
        self.assertEqual(candidate.xml_item(101).name, "candidate")
        self.assertEqual(candidate.otb_items(101)[0].group, 2)
        self.assertEqual(candidate.xml_item(103).name, "candidate item")
        self.assertEqual(original.xml.to_bytes(), xml_before)
        self.assertEqual(original.otb.to_bytes(), otb_before)
        self.assertEqual(original.item_name(101), "flower")
        self.assertEqual(original.pending_writes(), [])
        self.assertIsNone(original.xml_item(103))
        self.assert_server_originals()

    def test_sync_removes_obsolete_known_properties_and_sets_dat_top_order(self):
        linked = self.project().server_files
        thing = Thing(100, 0, [Attribute(0, (150,)), Attribute(21, (5, 215)), Attribute(28, (80,))])
        linked.sync_otb(thing)
        for code in (0x14, 0x2A, 0x21):
            self.assertIsNotNone(linked.otb_items(100)[0].get_attribute(code))
        for top_code, order in ((1, 1), (2, 2), (3, 3)):
            thing.attributes = [Attribute(top_code), Attribute(7)]
            linked.sync_otb(thing)
            record = linked.otb_items(100)[0]
            self.assertEqual(record.group, 0)
            self.assertEqual(record.get_attribute(0x2B), bytes((order,)))
            self.assertTrue(record.flags & (1 << 13))
            self.assertTrue(record.flags & (1 << 4))
            for code in (0x14, 0x2A, 0x21):
                self.assertIsNone(record.get_attribute(code))
        thing.attributes = []
        linked.sync_otb(thing)
        record = linked.otb_items(100)[0]
        self.assertIsNone(record.get_attribute(0x2B))
        self.assertFalse(record.flags & (1 << 13))
        self.assertFalse(record.flags & (1 << 4))
        self.assertEqual(record.get_attribute(0x90), b"\xfd\xfe\xff")
        self.assertTrue(record.flags & (1 << 31))
        self.assert_server_originals()

    def test_failed_save_as_keeps_source_binding_and_leaves_no_partial_export(self):
        project = self.project()
        self.edit_everything(project)
        source_linked = project.server_files
        destination = self.root / "failed-export"
        real_replace = transactions.os.replace
        failed = False

        def fail_once(source, target):
            nonlocal failed
            if Path(target) == destination / "server-items/items.xml" and not failed:
                failed = True
                raise OSError("export server XML unavailable")
            return real_replace(source, target)

        with mock.patch.object(transactions.os, "replace", side_effect=fail_once):
            with self.assertRaisesRegex(OSError, "export server XML unavailable"):
                project.save(destination)
        self.assertTrue(failed)
        self.assertEqual(project.directory, self.assets)
        self.assertIs(project.server_files, source_linked)
        self.assertEqual(project.server_files.xml_path, self.xml_path)
        self.assertTrue(project.server_files.pending_writes())
        for relative in ("Assets.dat", "Assets.spr", "Assets.otfi", MANIFEST_NAME,
                         "server-items/items.xml", "server-items/items.otb"):
            self.assertFalse((destination / relative).exists(), relative)
        self.assert_server_originals()
        for path, data in self.visual_originals.items():
            self.assertEqual(path.read_bytes(), data)
        self.assert_no_stages()


if __name__ == "__main__":
    unittest.main()
