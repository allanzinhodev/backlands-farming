"""Real hidden-Tk checks for pending XML and ClientID-bound server editing."""
from __future__ import annotations

from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

try:
    import tkinter as tk
except ImportError:
    tk = None

if tk is not None:
    from backlands_editor.gui import Editor
    from backlands_editor.project import Project
    from backlands_editor.server_items import OtbFile
    from backlands_editor.server_project import ServerFiles


def attribute(code, data):
    return bytes((code,)) + struct.pack("<H", len(data)) + data


def node(payload):
    escaped = b"".join((b"\xfd" if value in (253, 254, 255) else b"") + bytes((value,))
                       for value in payload)
    return b"\xfe" + escaped + b"\xff"


def server_fixture():
    # SID 400 deliberately differs from CID 100. Bit 30 and attribute 0x90 are
    # unknown to the panel and must survive edits to its known checkboxes.
    item = bytes((1,)) + struct.pack("<I", (1 << 30) | (1 << 0))
    item += attribute(0x10, struct.pack("<H", 400))
    item += attribute(0x11, struct.pack("<H", 100))
    item += attribute(0x14, struct.pack("<H", 150))
    item += attribute(0x90, b"unknown\xfd\xfe\xff")
    root = node(bytes((0,)) + struct.pack("<I", 0))
    return b"OTBI" + root[:-1] + node(item) + b"\xff"


XML = b'''<?xml version="1.0" encoding="utf-8"?>
<items>
    <!-- keep this catalog comment -->
    <item fromid="100" toid="101" name="client range">
        <attribute key="weight" value="10" />
    </item>
    <item id="400" name="legacy ID is another item" />
</items>
'''


@unittest.skipIf(tk is None, "Tkinter não está instalado")
class ServerEditorInteractionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            cls.root = tk.Tk()
            cls.root.withdraw()
        except tk.TclError as error:
            raise unittest.SkipTest(f"Interface gráfica indisponível: {error}") from error

    @classmethod
    def tearDownClass(cls):
        cls.root.destroy()

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name).resolve()
        self.xml_path = self.directory / "items.xml"
        self.otb_path = self.directory / "items.otb"
        self.xml_path.write_bytes(XML)
        self.otb_path.write_bytes(server_fixture())
        project = Project.new()
        project.add_thing(0)
        project.server_files = ServerFiles.associate(self.xml_path, self.otb_path)
        self.errors = []
        self.editor = Editor(self.root)
        self.root.report_callback_exception = lambda kind, value, trace: self.errors.append(value)
        self.editor.install_project(project)
        self.root.update()
        self.assertEqual(self.editor.thing.id, 100)
        self.assertFalse(self.editor.server_panel.pending)

    def tearDown(self):
        self.editor.stop_animation()
        self.root.update_idletasks()
        for child in self.root.winfo_children():
            child.destroy()
        self.root.configure(menu="")
        self.temporary.cleanup()
        self.assertEqual(self.errors, [], "Unexpected Tk callback errors")

    def edit_xml(self, fragment):
        panel = self.editor.server_panel
        panel.xml_text.delete("1.0", "end")
        panel.xml_text.insert("1.0", fragment)
        self.root.update()
        self.assertTrue(panel.pending)
        self.assertTrue(self.editor.pending)

    def test_panel_selects_xml_by_client_id_even_when_legacy_server_id_differs(self):
        editor = self.editor
        panel = editor.server_panel
        self.assertIn('id="100"', panel.xml_text.get("1.0", "end-1c"))
        self.assertIn('name="client range"', panel.xml_text.get("1.0", "end-1c"))
        self.assertNotIn("legacy ID", panel.xml_text.get("1.0", "end-1c"))
        self.assertIn("ServerID 400 / ClientID 100", panel.message.get())
        self.assertEqual(editor.objects.item("100", "values")[1], "client range")

    def test_invalid_pending_xml_blocks_item_switch_and_preserves_text(self):
        editor = self.editor
        invalid = '<item id="100" name="incomplete">'
        self.edit_xml(invalid)
        with mock.patch("backlands_editor.server_ui.messagebox.showerror") as error:
            editor.objects.selection_set("101")
            self.root.update()
        error.assert_called_once()
        self.assertEqual(editor.thing.id, 100)
        self.assertEqual(editor.objects.selection(), ("100",))
        self.assertEqual(editor.server_panel.xml_text.get("1.0", "end-1c"), invalid)
        self.assertTrue(editor.server_panel.pending)
        self.assertEqual(editor.project.server_files.xml.to_bytes(), XML)

    def test_invalid_pending_xml_blocks_save_before_any_project_write(self):
        self.edit_xml('<item id="100"><attribute')
        with mock.patch("backlands_editor.server_ui.messagebox.showerror") as error:
            with mock.patch.object(self.editor.project, "save") as save:
                self.assertFalse(self.editor.save())
        error.assert_called_once()
        save.assert_not_called()
        self.assertEqual(self.xml_path.read_bytes(), XML)
        self.assertEqual(self.otb_path.read_bytes(), server_fixture())

    def test_changing_xml_id_is_rejected_and_memory_remains_unchanged(self):
        self.edit_xml('<item id="101" name="wrong item" />')
        with mock.patch("backlands_editor.server_ui.messagebox.showerror") as error:
            self.assertFalse(self.editor.apply_properties())
        error.assert_called_once()
        self.assertEqual(self.editor.project.server_files.xml.to_bytes(), XML)

    def test_editing_range_member_changes_only_selected_client_id(self):
        editor = self.editor
        self.edit_xml('<item id="100" name="edited client"><attribute key="weight" value="20" /></item>')
        self.assertTrue(editor.apply_properties())
        linked = editor.project.server_files
        self.assertEqual(linked.xml_item(100).name, "edited client")
        self.assertEqual(linked.xml_item(101).name, "client range")
        self.assertEqual(linked.xml_item(400).name, "legacy ID is another item")
        self.assertIn(b"<!-- keep this catalog comment -->", linked.xml.to_bytes())
        self.assertEqual(editor.objects.item("100", "values")[1], "edited client")
        self.assertEqual(self.xml_path.read_bytes(), XML, "Apply only edits memory")

    def test_otb_checkbox_and_known_property_removal_preserve_unknown_bits_and_fields(self):
        editor = self.editor
        panel = editor.server_panel
        panel.flags[0].set(False)
        panel.flags[7].set(True)
        panel.properties[0x14][0].set(False)
        self.assertTrue(editor.apply_properties())
        linked = editor.project.server_files
        record = linked.otb_items(100)[0]
        self.assertEqual(record.flags, (1 << 30) | (1 << 7))
        self.assertEqual(record.get_attribute(0x90), b"unknown\xfd\xfe\xff")
        self.assertIsNone(record.get_attribute(0x14))
        self.assertEqual((record.server_id, record.client_id), (400, 100))
        self.assertEqual(linked.xml.to_bytes(), XML, "Unchanged XML range must not split")
        roundtrip = OtbFile.from_bytes(linked.otb.to_bytes()).find_client(100)[0]
        self.assertEqual(roundtrip.flags, record.flags)
        self.assertEqual(roundtrip.get_attribute(0x90), b"unknown\xfd\xfe\xff")

    def test_invalid_otb_property_does_not_partially_apply_valid_xml(self):
        editor = self.editor
        self.edit_xml('<item id="100" name="must stay pending" />')
        enabled, value = editor.server_panel.properties[0x14]
        enabled.set(True)
        value.set("not a number")
        with mock.patch("backlands_editor.server_ui.messagebox.showerror") as error:
            self.assertFalse(editor.apply_properties())
        error.assert_called_once()
        self.assertTrue(editor.server_panel.pending)
        self.assertEqual(editor.project.server_files.xml.to_bytes(), XML)
        self.assertEqual(editor.project.server_files.otb.to_bytes(), server_fixture())

    def test_only_unchecking_known_property_queues_and_saves_otb_removal(self):
        editor = self.editor
        editor.server_panel.properties[0x14][0].set(False)
        self.assertTrue(editor.apply_properties())
        linked = editor.project.server_files
        self.assertFalse(linked._edited_xml)
        self.assertTrue(linked._edited_otb)
        self.assertEqual([path for path, _data in linked.pending_writes()], [self.otb_path])

        # Save an existing visual project association, avoiding preference writes
        # and keeping every output inside this test's temporary directory.
        editor.project.directory = self.directory / "assets"
        editor.project.save()

        record = OtbFile.load(self.otb_path).find_client(100)[0]
        self.assertIsNone(record.get_attribute(0x14))
        self.assertEqual(record.get_attribute(0x90), b"unknown\xfd\xfe\xff")
        self.assertEqual(self.xml_path.read_bytes(), XML)
        self.assertFalse(editor.project.server_files._edited_otb)

    def test_both_missing_associations_can_be_repaired_one_file_at_a_time(self):
        editor = self.editor
        missing = ServerFiles(self.directory / "moved" / "items.xml",
                              self.directory / "moved" / "items.otb")
        missing._load(strict=False)
        self.assertEqual(len(missing.issues), 2)
        editor.project.server_files = missing
        editor.server_panel.refresh()

        with mock.patch("backlands_editor.server_ui.filedialog.askopenfilename",
                        side_effect=[str(self.xml_path), str(self.otb_path)]) as picker:
            editor.server_panel.associate("xml")
            self.root.update()
            linked = editor.project.server_files
            self.assertEqual(linked.xml_path, self.xml_path)
            self.assertIsNotNone(linked.xml)
            self.assertIsNone(linked.otb_path)
            editor.server_panel.associate("otb")
            self.root.update()

        self.assertEqual(picker.call_count, 2)
        linked = editor.project.server_files
        self.assertEqual((linked.xml_path, linked.otb_path), (self.xml_path, self.otb_path))
        self.assertEqual(linked.xml_item(100).name, "client range")
        self.assertEqual(linked.otb_items(100)[0].server_id, 400)
        self.assertEqual(linked.issues, [])

    def test_otb_controls_are_disabled_when_client_id_has_no_record(self):
        editor = self.editor
        editor.objects.selection_set("101")
        self.root.update()
        panel = editor.server_panel
        self.assertEqual(editor.thing.id, 101)
        self.assertEqual(str(panel.group_combo.cget("state")), "disabled")
        self.assertTrue(panel.otb_widgets)
        for widget in panel.otb_widgets:
            self.assertEqual(str(widget.cget("state")), "disabled")
        self.assertEqual(str(panel.xml_text.cget("state")), "normal")
        self.assertFalse(panel.pending)


if __name__ == "__main__":
    unittest.main()
