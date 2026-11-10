"""Exercise files, pixel order, and preservation independently of the UI."""
from __future__ import annotations

from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest import mock

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from backlands_editor import project as project_module
from backlands_editor.formats import FormatOptions, FrameGroup
from backlands_editor.project import Project

DAT_SIGNATURE = 0x4C2C7993
SPR_SIGNATURE = 0x4C220594
COLORS = ((255, 0, 0, 255), (0, 255, 0, 255),
          (0, 0, 255, 255), (255, 255, 0, 255))


def make_fixture(directory: Path, *, with_otfi: bool = True,
                 sprite_size: int = 16, bad_id: bool = False) -> tuple[bytes, bytes]:
    """Four solid SPR tiles and a 2x2 DAT item, with hand-built byte layouts."""
    header = struct.pack("<I4H", DAT_SIGNATURE, 100, 1, 1, 1)
    item = b"\xff" + bytes((2, 2, 32, 1, 1, 1, 1, 1))
    item += struct.pack("<HHHH", 1, 2, 3, 99 if bad_id else 4)
    basic = b"\xff" + bytes((1, 1, 1, 1, 1, 1, 1)) + struct.pack("<H", 1)
    dat = header + item + basic * 3
    spr_header = struct.pack("<IH", SPR_SIGNATURE, 4)
    base = len(spr_header) + 4 * 4
    body = bytearray()
    offsets = []
    for color in COLORS:
        offsets.append(base + len(body))
        encoded = struct.pack("<HH", 0, 256) + bytes(color[:3]) * 256
        body += b"\xff\x00\xff" + struct.pack("<H", len(encoded)) + encoded
    spr = spr_header + struct.pack("<IIII", *offsets) + body
    (directory / "Assets.dat").write_bytes(dat)
    (directory / "Assets.spr").write_bytes(spr)
    if with_otfi:
        (directory / "Assets.otfi").write_text(
            "DatSpr\n  extended: false\n  transparency: false\n"
            "  frame-durations: false\n  frame-groups: false\n"
            "  metadata-file: Assets.dat\n  sprites-file: Assets.spr\n"
            f"  sprite-size: {sprite_size}\n  sprite-data-size: {sprite_size * sprite_size * 4}\n",
            encoding="utf-8")
    return dat, bytes(spr)


class ProjectTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name)
        self.original_dat, self.original_spr = make_fixture(self.directory)

    def tearDown(self):
        self.temporary.cleanup()

    def project(self) -> Project:
        return Project.load(self.directory)

    def test_load_keeps_signatures_category_ids_and_real_16px_pixels(self):
        project = self.project()
        self.assertEqual(project.options.sprite_size, 16)
        self.assertEqual(project.dat.signature, DAT_SIGNATURE)
        self.assertEqual(project.spr.signature, SPR_SIGNATURE)
        self.assertEqual([[thing.id for thing in category] for category in project.dat.categories],
                         [[100], [1], [1], [1]])
        self.assertEqual(len(project.spr), 4)
        self.assertEqual(project.spr.get(1), bytes(COLORS[0]) * 256)

    def test_otfi_filenames_allow_inline_comments_quotes_and_spacing(self):
        otfi = self.directory / "Assets.otfi"
        text = otfi.read_text(encoding="utf-8")
        text = text.replace("  metadata-file: Assets.dat", '  metadata-file  : "Assets.dat" # dados')
        text = text.replace("  sprites-file: Assets.spr", "  sprites-file: 'Assets.spr' # sprites")
        otfi.write_text(text, encoding="utf-8-sig")

        project = self.project()

        self.assertEqual((project.dat_name, project.spr_name), ("Assets.dat", "Assets.spr"))
        self.assertEqual(project.dat.signature, DAT_SIGNATURE)
        self.assertEqual(project.spr.get(1), bytes(COLORS[0]) * 256)
        project.save()
        self.assertEqual(self.project().dat_name, "Assets.dat")

    def test_otfi_other_sections_cannot_override_datspr_filenames(self):
        otfi = self.directory / "Assets.otfi"
        text = otfi.read_text(encoding="utf-8")
        text = ("OtherBefore\n  metadata-file: ../wrong.dat\n  sprites-file: wrong.spr\n"
                + text + "OtherAfter\n  metadata-file: ../escape.dat\n  sprites-file: missing.spr\n")
        otfi.write_text(text, encoding="utf-8")

        project = self.project()

        self.assertEqual((project.dat_name, project.spr_name), ("Assets.dat", "Assets.spr"))
        self.assertEqual(project.dat.signature, DAT_SIGNATURE)
        self.assertEqual(project.spr.signature, SPR_SIGNATURE)

    def test_multitile_render_anchors_first_sprite_at_bottom_right(self):
        project = self.project()
        image = project.render_thing(project.dat.categories[0][0])
        self.assertEqual(image.size, (32, 32))
        self.assertEqual(image.getpixel((24, 24)), COLORS[0])
        self.assertEqual(image.getpixel((8, 24)), COLORS[1])
        self.assertEqual(image.getpixel((24, 8)), COLORS[2])
        self.assertEqual(image.getpixel((8, 8)), COLORS[3])

    def test_open_without_metadata_needs_explicit_format_options(self):
        (self.directory / "Assets.otfi").unlink()
        # Canonical names let the explicit-options import discover the pair.
        (self.directory / "Assets.dat").rename(self.directory / "Tibia.dat")
        (self.directory / "Assets.spr").rename(self.directory / "Tibia.spr")
        with self.assertRaises(ValueError):
            Project.load(self.directory)
        project = Project.load(self.directory, options=FormatOptions())
        self.assertEqual(project.dat.signature, DAT_SIGNATURE)

    def test_32px_or_undeclared_dimensions_rejected(self):
        make_fixture(self.directory, sprite_size=32)
        with self.assertRaises(ValueError):
            self.project()
        make_fixture(self.directory)
        otfi = self.directory / "Assets.otfi"
        otfi.write_text(otfi.read_text(encoding="utf-8").replace("  sprite-size: 16\n", ""), encoding="utf-8")
        with self.assertRaises(ValueError):
            self.project()

    def test_missing_sprite_reference_rejected_during_load(self):
        make_fixture(self.directory, bad_id=True)
        with self.assertRaises(ValueError):
            self.project()

    def test_sprite_sheet_import_preserves_empty_tiles_and_row_major_order(self):
        project = self.project()
        sheet = Image.new("RGBA", (32, 32))
        # Top left blank; the remaining three distinct tiles must keep their IDs.
        sheet.paste(COLORS[1], (16, 0, 32, 16))
        sheet.paste(COLORS[2], (0, 16, 16, 32))
        sheet.paste(COLORS[3], (16, 16, 32, 32))
        path = self.directory / "sheet.png"
        sheet.save(path)
        ids = project.import_sprite_sheet(path)
        self.assertEqual(ids, [5, 6, 7, 8])
        self.assertEqual(project.spr.get(5), bytes(1024))
        for sprite_id, color in zip(ids[1:], COLORS[1:]):
            self.assertEqual(project.spr.get(sprite_id), bytes(color) * 256)

    def test_bad_sheet_dimensions_do_not_append_partial_sprites(self):
        project = self.project()
        path = self.directory / "bad.png"
        Image.new("RGBA", (17, 32), COLORS[0]).save(path)
        with self.assertRaises(ValueError):
            project.import_sprite_sheet(path)
        self.assertEqual(len(project.spr), 4)

    def test_replacement_keeps_sprite_id_and_other_objects(self):
        project = self.project()
        original_ids = list(project.dat.categories[0][0].groups[0].sprites)
        path = self.directory / "replacement.png"
        replacement = (90, 80, 70, 255)
        Image.new("RGBA", (16, 16), replacement).save(path)
        project.replace_sprite(path, 2)
        self.assertEqual(len(project.spr), 4)
        self.assertEqual(project.spr.get(2), bytes(replacement) * 256)
        self.assertEqual(project.spr.get(1), bytes(COLORS[0]) * 256)
        self.assertEqual(project.dat.categories[0][0].groups[0].sprites, original_ids)

    def test_object_sheet_preserves_layers_patterns_frames_and_tile_order(self):
        project = self.project()
        item = project.dat.categories[0][0]
        group = FrameGroup(width=2, height=1, layers=2, pattern_x=2,
                           pattern_y=2, pattern_z=1, frames=2,
                           sprites=[1, 2] * 16)
        item.groups = [group]
        path = self.directory / "object.png"
        project.export_thing_sheet(item, path)
        with Image.open(path) as image:
            self.assertEqual(image.size, (128, 64))
            # Every 32px object cell is reversed relative to raw DAT X order.
            for row in range(4):
                for column in range(4):
                    self.assertEqual(image.getpixel((column * 32 + 8, row * 16 + 8)), COLORS[1])
                    self.assertEqual(image.getpixel((column * 32 + 24, row * 16 + 8)), COLORS[0])
        project.import_thing_sheet(item, path)
        rendered = project.render_thing(item, layer=0)
        self.assertEqual(rendered.getpixel((8, 8)), COLORS[1])
        self.assertEqual(rendered.getpixel((24, 8)), COLORS[0])
        self.assertEqual(group.expected_count(), 32)
        self.assertEqual(len(group.sprites), 32)

    def test_save_preserves_names_signatures_and_creates_original_backups(self):
        project = self.project()
        project.save()
        self.assertEqual((self.directory / "Assets.dat").read_bytes(), self.original_dat)
        self.assertEqual((self.directory / "Assets.spr").read_bytes(), self.original_spr)
        backups = self.directory / ".backups"
        self.assertTrue(backups.is_dir())
        self.assertTrue(any(p.read_bytes() == self.original_dat for p in backups.rglob("Assets.dat")))
        self.assertTrue(any(p.read_bytes() == self.original_spr for p in backups.rglob("Assets.spr")))
        reloaded = self.project()
        self.assertEqual(reloaded.dat.signature, DAT_SIGNATURE)
        self.assertEqual(reloaded.spr.signature, SPR_SIGNATURE)

    def test_save_as_does_not_change_original_files(self):
        project = self.project()
        destination = self.directory / "exported"
        project.save(destination)
        self.assertTrue((destination / "Assets.otfi").exists())
        exported = Project.load(destination)
        self.assertEqual(exported.dat.categories[0][0].groups[0].sprites, [1, 2, 3, 4])
        self.assertEqual((self.directory / "Assets.dat").read_bytes(), self.original_dat)
        self.assertEqual((self.directory / "Assets.spr").read_bytes(), self.original_spr)

    def test_appending_objects_does_not_renumber_existing_ids(self):
        project = self.project()
        new_item = project.add_thing(0)
        new_outfit = project.add_thing(1)
        self.assertEqual(new_item.id, 101)
        self.assertEqual(new_outfit.id, 2)
        self.assertEqual(project.dat.categories[0][0].id, 100)
        self.assertEqual(project.dat.categories[0][0].groups[0].sprites, [1, 2, 3, 4])

    def test_failed_save_restores_entire_original_pair_and_metadata(self):
        for failed_name in ("Assets.spr", "Assets.otfi"):
            with self.subTest(failed_name=failed_name):
                project = self.project()
                project.dat.signature = 0x12345678
                project.spr.set(1, bytes((12, 34, 56, 255)) * 256)
                names = ("Assets.dat", "Assets.spr", "Assets.otfi")
                originals = {name: (self.directory / name).read_bytes() for name in names}
                real_replace = project_module.os.replace
                did_fail = False

                def fail_one_commit(source, target):
                    nonlocal did_fail
                    if not did_fail and Path(target).name == failed_name:
                        did_fail = True
                        raise OSError("Simulated disk write failure")
                    return real_replace(source, target)

                with mock.patch.object(project_module.os, "replace", side_effect=fail_one_commit):
                    with self.assertRaises(OSError):
                        project.save()
                self.assertTrue(did_fail)
                for name in names:
                    self.assertEqual((self.directory / name).read_bytes(), originals[name])
                self.assertFalse(list(self.directory.glob(".backlands-stage-*")))

    def test_failed_first_save_removes_new_partial_files(self):
        project = self.project()
        destination = self.directory / "failed-export"
        real_replace = project_module.os.replace

        def fail_sprite_commit(source, target):
            if Path(target).name == "Assets.spr":
                raise OSError("Simulated disk write failure")
            return real_replace(source, target)

        with mock.patch.object(project_module.os, "replace", side_effect=fail_sprite_commit):
            with self.assertRaises(OSError):
                project.save(destination)
        self.assertFalse((destination / "Assets.dat").exists())
        self.assertFalse((destination / "Assets.spr").exists())
        self.assertFalse((destination / "Assets.otfi").exists())
        self.assertEqual(project.directory, self.directory.resolve())

    def test_partial_alpha_import_is_explicit_and_atomic(self):
        project = self.project()
        path = self.directory / "partial-alpha.png"
        Image.new("RGBA", (16, 16), (90, 80, 70, 127)).save(path)
        with self.assertRaises(ValueError):
            project.import_sprite_sheet(path)
        self.assertEqual(len(project.spr), 4)
        project.options.transparency = True
        sprite_ids = project.import_sprite_sheet(path)
        self.assertEqual(sprite_ids, [5])
        self.assertEqual(project.spr.get(5), bytes((90, 80, 70, 127)) * 256)

    def test_invalid_references_are_rejected_before_touching_disk(self):
        project = self.project()
        project.dat.categories[0][0].groups[0].sprites[0] = 9999
        with self.assertRaises(ValueError):
            project.save()
        self.assertEqual((self.directory / "Assets.dat").read_bytes(), self.original_dat)
        self.assertEqual((self.directory / "Assets.spr").read_bytes(), self.original_spr)
        self.assertFalse((self.directory / ".backups").exists())

    def test_duplicate_objects_keep_independent_layouts(self):
        project = self.project()
        original = project.dat.categories[0][0]
        duplicate = project.add_thing(0, duplicate=original)
        duplicate.groups[0].sprites[0] = 0
        duplicate.groups[0].resize(frames=2)
        self.assertEqual(original.groups[0].sprites, [1, 2, 3, 4])
        self.assertEqual(original.groups[0].frames, 1)
        self.assertEqual(duplicate.id, 101)

    def test_project_file_paths_cannot_escape_save_directory(self):
        project = self.project()
        project.dat_name = "../escaped.dat"
        destination = self.directory / "export"
        with self.assertRaises(ValueError):
            project.save(destination)
        self.assertFalse((self.directory / "escaped.dat").exists())


if __name__ == "__main__":
    unittest.main()
