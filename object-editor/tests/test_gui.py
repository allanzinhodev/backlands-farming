"""Functional Tk regression checks; skipped when a display is unavailable."""
from __future__ import annotations

from pathlib import Path
import sys
from types import SimpleNamespace
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

try:
    import tkinter as tk
except ImportError:
    tk = None

if tk is not None:
    from backlands_editor.formats import FrameGroup
    from backlands_editor.gui import Editor


@unittest.skipIf(tk is None, "Tkinter não está instalado")
class EditorInteractionTests(unittest.TestCase):
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
        self.errors = []
        self.editor = Editor(self.root)
        # Unexpected Tk callback errors should fail the test, never open a modal.
        self.root.report_callback_exception = lambda kind, value, trace: self.errors.append(value)
        self.root.update()
        self.assertIsNotNone(self.editor.thing)

    def tearDown(self):
        self.editor.stop_animation()
        self.root.update_idletasks()
        for child in self.root.winfo_children():
            child.destroy()
        self.root.configure(menu="")
        self.assertEqual(self.errors, [], "Tk callbacks raised unexpected errors")

    def add_sprite(self, rgba: bytes | None = None) -> int:
        return self.editor.project.spr.append(rgba if rgba is not None else bytes(1024))

    def select_slot(self, index: int) -> None:
        self.editor.slot_tree.selection_set(str(index))
        self.root.update()

    def pixel_event(self, x: int, y: int) -> SimpleNamespace:
        pixel = self.editor.pixel
        scale = pixel.scale.get()
        return SimpleNamespace(x=pixel.origin[0] + x * scale + scale // 2,
                               y=pixel.origin[1] + y * scale + scale // 2)

    def test_link_after_pending_resize_keeps_tile_coordinates(self):
        editor = self.editor
        sprite_id = self.add_sprite(bytes((255, 0, 0, 255)) * 256)
        editor.thing.groups = [FrameGroup(width=2, height=2, sprites=[0] * 4)]
        editor.load_properties()
        self.select_slot(2)  # x=0, y=1 in the original 2x2 group.
        editor.select_sprite(sprite_id)
        editor.dim_vars["width"].set(3)

        editor.link_sprite()

        group = editor.thing.groups[0]
        self.assertEqual(group.sprites, [0, 0, 0, sprite_id, 0, 0])
        self.assertEqual(editor.slot_coordinates(), (0, 1, 0, 0, 0, 0, 0))
        self.assertEqual(editor.slot_tree.selection(), ("3",))

    def test_set_slot_id_applies_pending_properties_and_assigns_id(self):
        editor = self.editor
        sprite_id = self.add_sprite()
        self.select_slot(0)
        editor.dim_vars["layers"].set(2)

        with mock.patch("backlands_editor.gui.simpledialog.askinteger", return_value=sprite_id):
            editor.set_slot_id()

        self.assertEqual(editor.thing.groups[0].layers, 2)
        self.assertEqual(editor.thing.groups[0].sprites, [sprite_id, 0])
        self.assertEqual(editor.slot_tree.selection(), ("0",))

    def test_redrawing_preview_preserves_selected_slot(self):
        editor = self.editor
        editor.thing.groups = [FrameGroup(width=2, height=1, sprites=[0, 0])]
        editor.load_properties()
        self.select_slot(1)

        editor.preview_zoom.set(3)
        editor.draw_preview()
        self.root.update()

        self.assertEqual(editor.slot_tree.selection(), ("1",))
        self.assertEqual(editor.slot_coordinates(), (1, 0, 0, 0, 0, 0, 0))

    def test_single_tile_exact_size_is_implicit_sixteen(self):
        editor = self.editor
        self.assertEqual(str(editor.dim_widgets["exact_size"].cget("state")), "disabled")
        editor.dim_vars["exact_size"].set(15)
        self.assertEqual(editor.dim_vars["exact_size"].get(), 16)
        self.assertTrue(editor.apply_properties())
        self.assertEqual(editor.thing.groups[0].exact_size, 16)

        editor.dim_vars["width"].set(2)
        self.assertEqual(str(editor.dim_widgets["exact_size"].cget("state")), "normal")
        editor.dim_vars["exact_size"].set(31)
        self.assertTrue(editor.apply_properties())
        self.assertEqual(editor.thing.groups[0].exact_size, 31)

        editor.dim_vars["width"].set(1)
        self.assertEqual(str(editor.dim_widgets["exact_size"].cget("state")), "disabled")
        self.assertTrue(editor.apply_properties())
        self.assertEqual(editor.thing.groups[0].exact_size, 16)

    def test_animation_selector_matches_rendered_frame_when_stopped(self):
        editor = self.editor
        red = self.add_sprite(bytes((255, 0, 0, 255)) * 256)
        green = self.add_sprite(bytes((0, 255, 0, 255)) * 256)
        editor.thing.groups = [FrameGroup(frames=2, sprites=[red, green])]
        editor.load_properties()
        rendered_frames = []
        render = editor.project.render_thing

        def observe(*args, **kwargs):
            rendered_frames.append(kwargs["frame"])
            return render(*args, **kwargs)

        # Capture the scheduled callback so the test does not depend on clocks.
        with mock.patch.object(editor.project, "render_thing", side_effect=observe):
            with mock.patch.object(self.root, "after", return_value="test-animation") as after:
                editor.toggle_animation()
                self.assertEqual(rendered_frames[-1], 0)
                self.assertEqual(editor.selectors["frame"][0].get(), 0)
                self.assertEqual(editor.slot_tree.item("0", "values")[1], str(red))

                callback = after.call_args.args[1]
                callback()
                self.assertEqual(rendered_frames[-1], 1)
                self.assertEqual(editor.selectors["frame"][0].get(), 1)
                self.assertEqual(editor.slot_tree.item("1", "values")[1], str(green))

                with mock.patch.object(self.root, "after_cancel"):
                    editor.stop_animation()

        self.assertFalse(editor.playing)
        self.assertIsNone(editor.animation_job)
        self.assertEqual(editor.selectors["frame"][0].get(), rendered_frames[-1])

    def test_animation_cannot_use_old_group_frame_count_after_group_switch(self):
        editor = self.editor
        editor.project.options.frame_groups = True
        editor.thing = editor.project.add_thing(1)
        editor.thing.groups = [
            FrameGroup(frames=5, sprites=[0] * 5),
            FrameGroup(frames=2, sprites=[0] * 2, group_type=1),
        ]
        editor.load_properties()
        editor.selectors["frame"][0].set(3)
        with mock.patch.object(self.root, "after", return_value="test-animation") as after:
            with mock.patch.object(self.root, "after_cancel"):
                editor.toggle_animation()
                scheduled = after.call_args.args[1]
                editor.group_var.set(1)
                editor.change_group()
                scheduled()
                frame = editor.selectors["frame"][0].get()
                self.assertIn(frame, (0, 1))
                editor.draw_preview()
                editor.stop_animation()

    def test_flood_fill_respects_boundary_and_supports_undo_redo(self):
        editor = self.editor
        red, wall, blue = (255, 0, 0, 255), (0, 0, 0, 255), (20, 100, 200, 255)
        original = bytes(red) * 8 + bytes(wall) + bytes(red) * 7
        original *= 16
        sprite_id = self.add_sprite(original)
        editor.select_sprite(sprite_id)
        editor.pixel.tool.set("Preencher")
        editor.pixel.color = blue
        editor.pixel.alpha.set(255)

        editor.pixel.start(self.pixel_event(0, 0))
        editor.pixel.finish()

        expected = (bytes(blue) * 8 + bytes(wall) + bytes(red) * 7) * 16
        self.assertEqual(editor.project.spr.get(sprite_id), expected)
        self.assertEqual(len(editor.undo_stack), 1)
        editor.undo()
        self.assertEqual(editor.project.spr.get(sprite_id), original)
        self.assertEqual(editor.pixel.pixels, original)
        editor.redo()
        self.assertEqual(editor.project.spr.get(sprite_id), expected)
        self.assertEqual(editor.pixel.pixels, expected)

    def test_pencil_drag_is_one_undoable_continuous_stroke(self):
        editor = self.editor
        sprite_id = self.add_sprite()
        editor.select_sprite(sprite_id)
        color = (7, 30, 91, 255)
        editor.pixel.color = color
        editor.pixel.alpha.set(255)

        editor.pixel.start(self.pixel_event(1, 1))
        editor.pixel.paint(self.pixel_event(5, 1))
        editor.pixel.finish()

        pixels = editor.project.spr.get(sprite_id)
        for x in range(1, 6):
            index = (16 + x) * 4
            self.assertEqual(pixels[index:index + 4], bytes(color))
        self.assertEqual(len(editor.undo_stack), 1)
        editor.undo()
        self.assertEqual(editor.project.spr.get(sprite_id), bytes(1024))


if __name__ == "__main__":
    unittest.main()
