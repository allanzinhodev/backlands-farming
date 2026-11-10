#!/usr/bin/env python3
"""Create a small, original 16px farming DAT/SPR project to try the editor."""
from pathlib import Path
import argparse
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from PIL import Image, ImageDraw
from backlands_editor.formats import Attribute
from backlands_editor.project import Project


def create_demo(directory: Path) -> Project:
    project = Project.new()
    sprites = []
    # Each image is drawn directly at native16px. No source asset is resized.
    ground = Image.new("RGBA", (16, 16), "#68a34b")
    draw = ImageDraw.Draw(ground)
    for x, y in ((1, 3), (9, 2), (5, 10), (12, 12), (3, 14)):
        draw.line((x, y, x + 1, y - 1), fill="#87b85b")
        draw.point((x + 2, y), fill="#497c3d")
    sprites.append(("Grama", ground, [Attribute(0, (150,)), Attribute(30)]))
    soil = Image.new("RGBA", (16, 16), "#95623f")
    draw = ImageDraw.Draw(soil)
    for y in (2, 6, 10, 14):
        draw.line((0, y, 15, y), fill="#6f4936")
        draw.line((0, y + 1, 15, y + 1), fill="#b17b4e")
    sprites.append(("Terra arada", soil, [Attribute(0, (150,)), Attribute(30)]))
    for phase in (0, 1, 2):
        crop = Image.new("RGBA", (16, 16))
        draw = ImageDraw.Draw(crop)
        draw.rectangle((7, 8 - phase * 2, 8, 14), fill="#3d713d")
        draw.line((5, 12, 7, 13), fill="#78ad4e", width=2)
        draw.line((9, 10, 11, 8), fill="#78ad4e", width=2)
        if phase >= 1:
            draw.rectangle((4, 6, 6, 8), fill="#80b84d")
            draw.rectangle((9, 4, 11, 6), fill="#91c15b")
        if phase == 2:
            draw.rectangle((6, 3, 9, 6), fill="#d78438")
            draw.rectangle((7, 2, 8, 6), fill="#efb14b")
        sprites.append((f"Planta {phase + 1}", crop, [Attribute(13)]))
    crate = Image.new("RGBA", (16, 16))
    draw = ImageDraw.Draw(crate)
    draw.rectangle((2, 4, 13, 14), fill="#684635")
    draw.rectangle((3, 5, 12, 13), fill="#b9824b")
    for y in (6, 9, 12):
        draw.line((4, y, 11, y), fill="#8c5f3c")
    draw.line((3, 5, 12, 13), fill="#dcad70", width=2)
    sprites.append(("Caixa", crate, [Attribute(4), Attribute(12), Attribute(16)]))
    sheet = Image.new("RGBA", (len(sprites) * 16, 16))
    directory.mkdir(parents=True, exist_ok=True)
    for index, (name, image, flags) in enumerate(sprites):
        sprite_id = project.spr.append(image.tobytes())
        thing = project.dat.categories[0][0] if index == 0 else project.add_thing(0)
        thing.attributes = flags + [Attribute(33, (0, thing.id, thing.id, name, 0, 0))]
        thing.groups[0].sprites = [sprite_id]
        sheet.paste(image, (index * 16, 0))
    sheet.save(directory / "farming-16.png")
    project.save(directory)
    return project


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    create_demo(args.directory)
    print(f"Exemplo criado: {args.directory.resolve()}")
