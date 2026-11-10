"""Animation edits checked across complete sprite blocks and independent DAT bytes."""
from __future__ import annotations

import copy
import itertools
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from backlands_editor.animation import (
    AnimationPlayback, create_group, duplicate_frame, enable_frame_durations,
    enable_frame_groups, insert_frame, move_frame, remove_frame, remove_group,
    validate_animation, validate_group_types,
)
from backlands_editor.formats import (
    DatFile, FormatError, FormatOptions, FrameGroup, SpriteFile, Thing,
    read_dat, write_dat,
)
from backlands_editor.project import Project


def legacy_fixture() -> bytes:
    """One two-frame object per category, assembled without the DAT writer."""
    header = struct.pack("<I4H", 0x4C2C7993, 100, 1, 1, 1)
    return header + b"".join(
        b"\xff" + bytes((1, 1, 1, 1, 1, 1, 2)) + struct.pack("<HH", index, index + 1)
        for index in (1, 2, 3, 4)
    )


class AnimationEditTests(unittest.TestCase):
    def group(self):
        # 64 references per frame, covering every coordinate dimension.
        return FrameGroup(width=2, height=2, layers=2, pattern_x=2,
                          pattern_y=2, pattern_z=2, frames=3,
                          sprites=list(range(1, 193)), start_frame=1,
                          durations=[(20, 30), (40, 50), (60, 70)])

    def assert_frame(self, actual, actual_frame, original, original_frame):
        for coordinates in itertools.product(range(2), repeat=6):
            self.assertEqual(actual.sprites[actual.sprite_index(*coordinates, actual_frame)],
                             original.sprites[original.sprite_index(*coordinates, original_frame)])

    def test_duplicate_preserves_every_pattern_layer_tile_and_timing(self):
        group = self.group()
        original = copy.deepcopy(group)
        selected = duplicate_frame(group, 1)
        self.assertEqual((selected, group.frames, group.start_frame), (2, 4, 1))
        for frame, source in enumerate((0, 1, 1, 2)):
            self.assert_frame(group, frame, original, source)
        self.assertEqual(group.durations, [(20, 30), (40, 50), (40, 50), (60, 70)])
        group.sprites[group.sprite_index(1, 1, 1, 1, 1, 1, 2)] = 0
        self.assert_frame(group, 1, original, 1)

    def test_insert_blank_retains_neighbors_and_follows_start_reference(self):
        group = self.group()
        original = copy.deepcopy(group)
        self.assertEqual(insert_frame(group, 1), 1)
        self.assertEqual(group.start_frame, 2)
        self.assertEqual(group.sprites[64:128], [0] * 64)
        self.assert_frame(group, 0, original, 0)
        self.assert_frame(group, 2, original, 1)
        self.assert_frame(group, 3, original, 2)
        self.assertEqual(group.durations[1], (150, 150))

    def test_insert_duplicate_before_source_keeps_original_start_identity(self):
        group = self.group()
        insert_frame(group, 0, duplicate=1)
        self.assertEqual(group.start_frame, 2)

    def test_move_retains_all_coordinates_timings_and_start_identity(self):
        group = self.group()
        original = copy.deepcopy(group)
        self.assertEqual(move_frame(group, 1, 2), 2)
        self.assertEqual(group.start_frame, 2)
        for frame, source in enumerate((0, 2, 1)):
            self.assert_frame(group, frame, original, source)
        self.assertEqual(group.durations, [(20, 30), (60, 70), (40, 50)])

    def test_remove_remaps_start_and_preserves_random_start(self):
        group = self.group()
        original = copy.deepcopy(group)
        self.assertEqual(remove_frame(group, 0), 0)
        self.assertEqual(group.start_frame, 0)
        self.assert_frame(group, 0, original, 1)
        self.assert_frame(group, 1, original, 2)
        self.assertEqual(group.durations, [(40, 50), (60, 70)])
        group.start_frame = -1
        remove_frame(group, 1)
        self.assertEqual((group.frames, group.start_frame), (1, -1))
        with self.assertRaises(FormatError):
            remove_frame(group, 0)
        self.assertEqual(group.frames, 1)

    def test_untimed_frame_edits_keep_empty_duration_extension(self):
        group = FrameGroup(frames=2, sprites=[1, 2])
        duplicate_frame(group, 0)
        self.assertEqual(group.durations, [])
        insert_frame(group, 1, durations=True)
        self.assertEqual(group.durations, [(150, 150)] * 4)

    def test_invalid_and_overflow_edits_are_atomic(self):
        for operation in (
            lambda group: insert_frame(group, -1),
            lambda group: insert_frame(group, 1, duplicate=1000),
            lambda group: duplicate_frame(group, 3),
            lambda group: move_frame(group, 0, 9),
            lambda group: remove_frame(group, -1),
        ):
            group = self.group()
            original = copy.deepcopy(group)
            with self.assertRaises(FormatError):
                operation(group)
            self.assertEqual(group, original)
        group = FrameGroup(frames=255, sprites=[0] * 255)
        original = copy.deepcopy(group)
        with self.assertRaises(FormatError):
            duplicate_frame(group, 0)
        self.assertEqual(group, original)
        group = FrameGroup(width=255, height=255, frames=4, sprites=[0] * 260100)
        original = copy.deepcopy(group)
        with self.assertRaises(FormatError):
            insert_frame(group, 0)
        self.assertEqual(group, original)

    def test_signed_start_byte_limit_prevents_silent_remap(self):
        group = FrameGroup(frames=129, sprites=list(range(129)), start_frame=127)
        original = copy.deepcopy(group)
        with self.assertRaises(FormatError):
            insert_frame(group, 0)
        self.assertEqual(group, original)

    def test_enable_groups_keeps_legacy_outfits_exactly_and_binary_layout(self):
        options = FormatOptions()
        dat = read_dat(legacy_fixture(), options)
        original = copy.deepcopy(dat)
        self.assertTrue(enable_frame_groups(dat, options))
        self.assertEqual(dat, original)
        self.assertFalse(enable_frame_groups(dat, options))
        legacy = legacy_fixture()
        header = legacy[:12]
        bodies = [legacy[12 + index * 12:24 + index * 12] for index in range(4)]
        expected = header + bodies[0] + b"\xff\x01\x00" + bodies[1][1:] + bodies[2] + bodies[3]
        self.assertEqual(write_dat(dat, options), expected)
        self.assertEqual(read_dat(expected, options), original)

    def test_enabling_durations_seeds_every_category_before_any_save(self):
        dat = read_dat(legacy_fixture())
        options = FormatOptions()
        original_refs = [[list(thing.groups[0].sprites) for thing in category] for category in dat.categories]
        self.assertTrue(enable_frame_durations(dat, options))
        self.assertFalse(enable_frame_durations(dat, options))
        for category in dat.categories:
            self.assertEqual(category[0].groups[0].durations, [(150, 150)] * 2)
        self.assertEqual([[list(thing.groups[0].sprites) for thing in category] for category in dat.categories], original_refs)
        expected = struct.pack("<I4H", 0x4C2C7993, 100, 1, 1, 1)
        for index in (1, 2, 3, 4):
            expected += (b"\xff" + bytes((1, 1, 1, 1, 1, 1, 2))
                         + struct.pack("<Bib4I2H", 0, 0, 0, 150, 150, 150, 150, index, index + 1))
        self.assertEqual(write_dat(dat, options), expected)
        self.assertEqual(read_dat(expected, options), dat)

    def test_enabling_durations_failure_changes_no_groups_or_options(self):
        dat = read_dat(legacy_fixture())
        dat.categories[3][0].groups[0].animation_mode = 8
        original = copy.deepcopy(dat)
        options = FormatOptions()
        with self.assertRaises(FormatError):
            enable_frame_durations(dat, options)
        self.assertEqual(dat, original)
        self.assertFalse(options.frame_durations)

    def test_new_and_duplicate_groups_enforce_semantic_uniqueness(self):
        options = FormatOptions(frame_groups=True, frame_durations=True)
        thing = Thing(1, 1, groups=[self.group()])
        self.assertEqual(create_group(thing, options, duplicate=True), 1)
        self.assertEqual([group.group_type for group in thing.groups], [0, 1])
        thing.groups[1].sprites[0] = 0
        self.assertEqual(thing.groups[0].sprites[0], 1)
        with self.assertRaises(FormatError):
            create_group(thing, options)
        thing.groups[1].group_type = 0
        with self.assertRaises(FormatError):
            validate_group_types(thing)
        thing.groups[1].group_type = 1
        self.assertEqual(remove_group(thing, 0), 0)
        create_group(thing, options, duplicate=False)
        self.assertEqual(thing.groups[-1].group_type, 0)
        self.assertEqual(thing.groups[-1].frames, 1)
        self.assertTrue(all(value == 0 for value in thing.groups[-1].sprites))
        for category in (0, 2, 3):
            with self.assertRaises(FormatError):
                create_group(Thing(100 if category == 0 else 1, category), options)

    def test_metadata_validation_rejects_unserializable_ranges(self):
        group = self.group()
        for field, value in (("animation_mode", 2), ("loop_count", 0x80000000),
                             ("start_frame", 3), ("durations", [(1, 0)] * 3),
                             ("durations", [(0, 0x100000000)] * 3)):
            candidate = copy.deepcopy(group)
            setattr(candidate, field, value)
            with self.subTest(field=field, value=value), self.assertRaises(FormatError):
                validate_animation(candidate)

    def test_edited_animation_groups_save_reload_with_spr_and_otfi(self):
        project = Project(read_dat(legacy_fixture()), SpriteFile(sprites=[None] * 5))
        enable_frame_groups(project.dat, project.options)
        enable_frame_durations(project.dat, project.options)
        thing = project.dat.categories[1][0]
        create_group(thing, project.options, duplicate=True)
        walking = thing.groups[1]
        walking.durations = [(80, 120), (130, 180)]
        walking.animation_mode, walking.loop_count, walking.start_frame = 1, -1, 1
        duplicate_frame(walking, 0, durations=True)
        move_frame(walking, 2, 0, durations=True)
        with tempfile.TemporaryDirectory() as directory:
            project.save(directory)
            reopened = Project.load(directory)
        self.assertEqual(reopened.options, project.options)
        self.assertEqual(reopened.dat, project.dat)
        self.assertEqual(len(reopened.spr), 5)


class AnimationPlaybackTests(unittest.TestCase):
    def group(self, **meta):
        return FrameGroup(frames=3, sprites=[1, 2, 3], durations=[(30, 50), (60, 80), (90, 110)], **meta)

    def test_async_preview_honors_start_finite_cycles_and_range(self):
        player = AnimationPlayback(self.group(start_frame=1, loop_count=1), timed=True)
        self.assertEqual(player.frame, 1)
        with mock.patch("backlands_editor.animation.random.randint", return_value=73) as sample:
            self.assertEqual(player.delay(), 73)
            sample.assert_called_once_with(60, 80)
        self.assertTrue(player.advance())
        self.assertEqual(player.frame, 2)
        self.assertFalse(player.advance())
        self.assertEqual(player.frame, 2)

    def test_negative_cycles_preview_pingpongs_and_random_start_is_bounded(self):
        with mock.patch("backlands_editor.animation.random.randrange", return_value=0) as sample:
            player = AnimationPlayback(self.group(start_frame=-1, loop_count=-1), timed=True)
            sample.assert_called_once_with(3)
        frames = [player.frame]
        for _ in range(7):
            self.assertTrue(player.advance())
            frames.append(player.frame)
        self.assertEqual(frames, [0, 1, 2, 1, 0, 1, 2, 1])

    def test_sync_uses_shared_clock_phase_and_untimed_keeps_selected_frame(self):
        player = AnimationPlayback(self.group(animation_mode=1), timed=True, now_ms=155)
        self.assertEqual((player.frame, player.delay()), (2, 55))
        player = AnimationPlayback(self.group(start_frame=1), timed=False, selected_frame=2)
        self.assertEqual((player.frame, player.delay()), (2, 150))


try:
    import tkinter as tk
except ImportError:
    tk = None


@unittest.skipIf(tk is None, "Tkinter não está instalado")
class AnimationPanelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            cls.root = tk.Tk()
            cls.root.withdraw()
        except tk.TclError as error:
            raise unittest.SkipTest(f"Interface indisponível: {error}") from error

    @classmethod
    def tearDownClass(cls):
        cls.root.destroy()

    def setUp(self):
        from backlands_editor.gui import Editor
        self.errors = []
        self.editor = Editor(self.root)
        self.root.report_callback_exception = lambda kind, value, trace: self.errors.append(value)
        self.root.update()

    def tearDown(self):
        self.editor.stop_animation()
        self.root.update_idletasks()
        for child in self.root.winfo_children():
            child.destroy()
        self.root.configure(menu="")
        self.assertEqual(self.errors, [])

    def prepare_creature(self):
        editor = self.editor
        editor.thing = editor.project.add_thing(1)
        editor.thing.groups = [FrameGroup(frames=3, sprites=[0, 0, 0])]
        editor.group_index = 0
        editor.load_properties()
        self.root.update()
        return editor

    def test_panel_enables_existing_project_and_edits_group_frame_durations(self):
        editor = self.prepare_creature()
        editor.enable_animation_feature("frame_groups")
        editor.enable_animation_feature("frame_durations")
        panel = editor.animation_panel
        panel.frames.selection_set("1")
        self.root.update()
        panel.minimum.set("90")
        panel.maximum.set("140")
        editor.edit_animation_frame("duplicate")
        self.assertEqual(editor.thing.groups[0].durations, [(150, 150), (90, 140), (90, 140), (150, 150)])
        self.assertEqual(editor.selectors["frame"][0].get(), 2)
        self.assertEqual(panel.frames.selection(), ("2",))
        editor.add_group(True)
        self.root.update()
        self.assertEqual(editor.group_index, 1)
        self.assertEqual(panel.groups.selection(), ("1",))
        self.assertEqual([group.group_type for group in editor.thing.groups], [0, 1])

    def test_pending_invalid_durations_block_group_switch_and_duplicate(self):
        editor = self.prepare_creature()
        editor.enable_animation_feature("frame_groups")
        editor.enable_animation_feature("frame_durations")
        editor.add_group(True)
        original = copy.deepcopy(editor.thing)
        panel = editor.animation_panel
        panel.minimum.set("bad")
        with mock.patch("backlands_editor.gui.messagebox.showerror") as error:
            editor.edit_animation_frame("duplicate")
            editor.group_var.set(0)
            editor.change_group()
        self.assertEqual(error.call_count, 2)
        self.assertEqual(editor.thing, original)
        self.assertEqual(editor.group_index, 1)
        self.assertEqual(editor.group_var.get(), 1)

    def test_panel_playback_survives_queued_selection_and_honors_finite_loop(self):
        editor = self.prepare_creature()
        editor.enable_animation_feature("frame_durations")
        group = editor.thing.groups[0]
        group.loop_count, group.start_frame = 1, 1
        editor.load_properties()
        with mock.patch.object(self.root, "after", return_value="test-animation") as after:
            editor.toggle_animation()
            self.root.update()
            self.assertTrue(editor.playing)
            self.assertEqual(editor.selectors["frame"][0].get(), 1)
            callback = after.call_args.args[1]
            callback()
            self.root.update()
            self.assertTrue(editor.playing)
            self.assertEqual(editor.selectors["frame"][0].get(), 2)
            callback = after.call_args.args[1]
            callback()
            self.assertFalse(editor.playing)
            self.assertEqual(editor.animation_panel.frames.selection(), ("2",))


if __name__ == "__main__":
    unittest.main()
