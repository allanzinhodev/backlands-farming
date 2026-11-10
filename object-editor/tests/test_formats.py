"""Binary compatibility checks using fixtures independent of the writer."""
from __future__ import annotations

import itertools
from pathlib import Path
import struct
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from backlands_editor.formats import (
    Attribute, DatFile, FormatError, FormatOptions, FrameGroup, SpriteFile,
    read_dat, read_otfi, read_spr, write_dat, write_otfi, write_spr,
)

DAT_SIGNATURE = 0x4C2C7993
SPR_SIGNATURE = 0x4C220594


def dat_header(items: int = 100, outfits: int = 0, effects: int = 0,
               missiles: int = 0) -> bytes:
    return struct.pack("<I4H", DAT_SIGNATURE, items, outfits, effects, missiles)


def single_thing(sprite_id: int, *, extended: bool = False) -> bytes:
    # FF, width, height, layers, pattern X/Y/Z, frames, sprite ID.
    return b"\xff\x01\x01\x01\x01\x01\x01\x01" + struct.pack(
        "<I" if extended else "<H", sprite_id)


def spr_fixture(payload: bytes, *, alpha: bool = False,
                empty_second: bool = False, extended: bool = False) -> bytes:
    del alpha  # The format stores the RGBA choice in OTFI, never in SPR.
    count = 2 if empty_second else 1
    header = struct.pack("<I", SPR_SIGNATURE) + struct.pack(
        "<I" if extended else "<H", count)
    start = len(header) + count * 4
    offsets = struct.pack("<I", start) + (b"\0" * 4 if empty_second else b"")
    return header + offsets + b"\xff\x00\xff" + struct.pack("<H", len(payload)) + payload


class DatCompatibilityTests(unittest.TestCase):
    def setUp(self):
        self.options = FormatOptions()

    def test_all_four_categories_have_their_own_ids(self):
        fixture = dat_header(101, 1, 1, 1) + b"".join(
            single_thing(i) for i in (1, 2, 3, 4, 5))
        dat = read_dat(fixture, self.options)
        self.assertEqual(dat.signature, DAT_SIGNATURE)
        self.assertEqual([[t.id for t in category] for category in dat.categories],
                         [[100, 101], [1], [1], [1]])
        self.assertEqual([[t.groups[0].sprites[0] for t in category]
                          for category in dat.categories], [[1, 2], [3], [4], [5]])
        self.assertEqual(write_dat(dat, self.options), fixture)

    def test_flag_payloads_and_multitile_exact_size_match_fixed_bytes(self):
        flags = (b"\x00" + struct.pack("<H", 150)
                 + b"\x15" + struct.pack("<HH", 2, 215)
                 + b"\x18" + struct.pack("<hh", -3, 5)
                 + b"\x19" + struct.pack("<H", 7)
                 + b"\x1c" + struct.pack("<H", 80) + b"\xff")
        fixture = (dat_header() + flags
                   + bytes((2, 1, 24, 1, 1, 1, 1, 1)) + struct.pack("<HH", 3, 9))
        dat = read_dat(fixture, self.options)
        item = dat.categories[0][0]
        self.assertEqual({a.code: a.values for a in item.attributes},
                         {0: (150,), 21: (2, 215), 24: (-3, 5), 25: (7,), 28: (80,)})
        self.assertEqual(item.groups[0].exact_size, 24)
        self.assertEqual(item.groups[0].sprites, [3, 9])
        self.assertEqual(write_dat(dat, self.options), fixture)

    def test_market_name_uses_latin1_byte_length(self):
        name = b"Caf\xe9"
        flags = (b"\x21" + struct.pack("<HHHH", 1, 100, 101, len(name))
                 + name + struct.pack("<HH", 2, 30))
        fixture = dat_header() + flags + single_thing(1)
        dat = read_dat(fixture, self.options)
        self.assertIn("Caf\u00e9", dat.categories[0][0].attributes[0].values)
        self.assertEqual(write_dat(dat, self.options), fixture)

    def test_extended_sprite_ids_are_u32(self):
        options = FormatOptions(extended=True)
        fixture = dat_header() + single_thing(70000, extended=True)
        dat = read_dat(fixture, options)
        self.assertEqual(dat.categories[0][0].groups[0].sprites, [70000])
        self.assertEqual(write_dat(dat, options), fixture)

    def test_outfit_groups_and_frame_durations(self):
        options = FormatOptions(frame_groups=True, frame_durations=True)
        # Only the outfit carries a group count/type. Each group has two frames.
        group = (bytes((1, 1, 1, 1, 1, 1, 2)) + struct.pack("<Bib", 1, -1, -1)
                 + struct.pack("<IIII", 100, 150, 200, 250) + struct.pack("<HH", 1, 2))
        fixture = dat_header(100, 1, 1) + single_thing(1) + b"\xff\x02\x00" + group + b"\x01" + group + single_thing(2)
        dat = read_dat(fixture, options)
        groups = dat.categories[1][0].groups
        self.assertEqual([g.group_type for g in groups], [0, 1])
        self.assertEqual(groups[0].durations, [(100, 150), (200, 250)])
        self.assertEqual(groups[0].loop_count, -1)
        self.assertEqual(groups[0].start_frame, -1)
        self.assertEqual(write_dat(dat, options), fixture)

    def test_corrupt_dat_rejected_before_returning_partial_project(self):
        valid = dat_header() + single_thing(1)
        corruptions = {
            "truncated header": valid[:11],
            "truncated sprite ID": valid[:-1],
            "missing flags terminator": dat_header() + b"\x01" * 16,
            "unknown flag": dat_header() + b"\x26" + single_thing(1),
            "zero width": dat_header() + b"\xff\x00\x01\x01\x01\x01\x01\x01",
            "unconsumed trailing bytes": valid + b"\x00",
        }
        for label, data in corruptions.items():
            with self.subTest(label=label), self.assertRaises(FormatError):
                read_dat(data, self.options)

    def test_layout_index_order_and_resize_preserve_coordinates(self):
        group = FrameGroup(width=2, height=2, layers=2, pattern_x=2,
                           pattern_y=2, pattern_z=2, frames=2,
                           sprites=list(range(1, 129)))
        expected = 0
        for frame, pz, py, px, layer, y, x in itertools.product(range(2), repeat=7):
            self.assertEqual(group.sprite_index(x, y, layer, px, py, pz, frame), expected)
            expected += 1
        group.resize(width=3)
        self.assertEqual(group.expected_count(), 192)
        self.assertEqual(len(group.sprites), 192)
        expected = 1
        for frame, pz, py, px, layer, y in itertools.product(range(2), repeat=6):
            for x in range(3):
                actual = group.sprites[group.sprite_index(x, y, layer, px, py, pz, frame)]
                self.assertEqual(actual, 0 if x == 2 else expected)
                if x != 2:
                    expected += 1


class SprCompatibilityTests(unittest.TestCase):
    def setUp(self):
        self.options = FormatOptions()

    def test_fixed_rgb_fixture_and_empty_offset(self):
        payload = struct.pack("<HH", 1, 2) + b"\xff\x00\x00\x00\xff\x00"
        fixture = spr_fixture(payload, empty_second=True)
        spr = read_spr(fixture, self.options)
        self.assertEqual(spr.signature, SPR_SIGNATURE)
        self.assertEqual(len(spr), 2)
        expected = bytes(4) + bytes((255, 0, 0, 255, 0, 255, 0, 255)) + bytes(253 * 4)
        self.assertEqual(spr.get(1), expected)
        self.assertEqual(spr.get(0), bytes(1024))
        self.assertEqual(spr.get(2), bytes(1024))
        self.assertEqual(write_spr(spr, self.options), fixture)

    def test_rgba_fixture_preserves_partial_alpha(self):
        options = FormatOptions(transparency=True)
        payload = struct.pack("<HH", 0, 2) + bytes((9, 8, 7, 127, 6, 5, 4, 255))
        fixture = spr_fixture(payload)
        spr = read_spr(fixture, options)
        self.assertEqual(spr.get(1), payload[4:] + bytes(254 * 4))
        self.assertEqual(write_spr(spr, options), fixture)

    def test_extended_sprite_count_uses_four_byte_header(self):
        options = FormatOptions(extended=True)
        fixture = spr_fixture(struct.pack("<HH", 0, 1) + b"\x03\x02\x01", extended=True)
        spr = read_spr(fixture, options)
        self.assertEqual(len(spr), 1)
        self.assertEqual(spr.get(1)[:4], bytes((3, 2, 1, 255)))
        self.assertEqual(write_spr(spr, options), fixture)

    def test_corrupt_sprite_offsets_and_rle_rejected(self):
        valid = spr_fixture(struct.pack("<HH", 0, 1) + b"\x01\x02\x03")
        corruptions = {
            "truncated index": valid[:9],
            "offset inside index": valid[:6] + struct.pack("<I", 6) + valid[10:],
            "offset past EOF": valid[:6] + struct.pack("<I", len(valid)) + valid[10:],
            "truncated blob": valid[:-1],
            "transparent overflow": spr_fixture(struct.pack("<HH", 257, 0)),
            "colored overflow": spr_fixture(struct.pack("<HH", 255, 2) + bytes(6)),
            "truncated pixel": spr_fixture(struct.pack("<HH", 0, 1) + bytes(2)),
            "truncated run": spr_fixture(b"\x01"),
        }
        for label, data in corruptions.items():
            with self.subTest(label=label), self.assertRaises(FormatError):
                read_spr(data, self.options)

    def test_serializer_rejects_wrong_pixel_buffer_size(self):
        spr = SpriteFile(sprites=[b"\x00" * 1023])
        with self.assertRaises(FormatError):
            write_spr(spr, self.options)

    def test_encoder_matches_independent_rgb_and_rgba_fixtures(self):
        for alpha in (False, True):
            with self.subTest(alpha=alpha):
                options = FormatOptions(transparency=alpha)
                opacity = 127 if alpha else 255
                rgba = bytes(4) + bytes((255, 0, 0, opacity, 0, 255, 0, 255)) + bytes(253 * 4)
                pixels = (bytes((255, 0, 0, opacity, 0, 255, 0, 255))
                          if alpha else bytes((255, 0, 0, 0, 255, 0)))
                expected = spr_fixture(struct.pack("<HH", 1, 2) + pixels, empty_second=True)
                spr = SpriteFile(signature=SPR_SIGNATURE, sprites=[rgba, None])
                self.assertEqual(write_spr(spr, options), expected)

    def test_replacing_sprite_preserves_other_records_color_keys_and_rle(self):
        # Two adjacent runs deliberately differ from the writer's canonical RLE.
        payload = (struct.pack("<HH", 0, 1) + b"\xff\x00\x00"
                   + struct.pack("<HH", 0, 1) + b"\x00\xff\x00")
        fixture = spr_fixture(payload, empty_second=True)
        fixture = fixture[:14] + b"\x01\x02\x03" + fixture[17:]
        spr = read_spr(fixture, self.options)
        spr.set(2, bytes((0, 0, 255, 255)) * 256)
        encoded = write_spr(spr, self.options)
        first, second = struct.unpack_from("<II", encoded, 6)
        original_record = fixture[14:]
        self.assertEqual(first, 14)
        self.assertEqual(second, 14 + len(original_record))
        self.assertEqual(encoded[first:second], original_record)
        expected_second = (b"\xff\x00\xff" + struct.pack("<H", 772)
                           + struct.pack("<HH", 0, 256) + b"\x00\x00\xff" * 256)
        self.assertEqual(encoded[second:], expected_second)
        self.assertEqual(read_spr(encoded, self.options).get(2), bytes((0, 0, 255, 255)) * 256)

    def test_rgb_serialization_rejects_silent_partial_alpha_loss(self):
        spr = SpriteFile(sprites=[bytes((10, 20, 30, 100)) * 256])
        with self.assertRaises(FormatError):
            write_spr(spr, self.options)

    def test_magenta_pixel_is_opaque_regardless_of_record_color_key(self):
        fixture = spr_fixture(struct.pack("<HH", 0, 1) + b"\xff\x00\xff")
        self.assertEqual(read_spr(fixture, self.options).get(1)[:4], bytes((255, 0, 255, 255)))


class OtfiCompatibilityTests(unittest.TestCase):
    def test_metadata_requires_explicit_sprite_size(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Tibia.otfi"
            path.write_text("DatSpr\n  extended: false\n  transparency: false\n"
                            "  frame-durations: false\n  frame-groups: false\n", encoding="utf-8")
            with self.assertRaises(FormatError):
                read_otfi(path)

    def test_writer_declares_real_sprite_dimensions_and_all_features(self):
        text = write_otfi(FormatOptions(extended=True, transparency=True), "Backlands.dat", "Backlands.spr")
        for declaration in ("sprite-size: 16", "sprite-data-size: 1024", "extended: true",
                            "transparency: true", "frame-durations: false", "frame-groups: false",
                            "metadata-file: Backlands.dat", "sprites-file: Backlands.spr"):
            self.assertIn(declaration, text)


if __name__ == "__main__":
    unittest.main()
