#!/usr/bin/env python3
"""Build the small Backlands farm in native ClientID OTBM format.

Only Python's standard library is required. The wire layout follows the readers
in server/src/iomap.cpp and map-editor/source/iomap_otbm.h. No item-ID conversion
is needed: the server, NexaMap and the 16px DAT all use ClientIDs in this repo.
"""

from __future__ import annotations

import argparse
from collections import deque
from dataclasses import dataclass, field
import json
from pathlib import Path
import struct
import xml.etree.ElementTree as ET

REPO = Path(__file__).resolve().parents[2]
SPAWN = (100, 100, 7)
BOUNDS = (80, 80, 126, 122)
NPCS = (("Seed Vendor", 102, 98), ("Harvest Buyer", 98, 98))
ANIMALS = ()

# Native ClientIDs verified against the current DAT and server items.otb.
GRASS, DIRT, WOOD, WATER = 106, 103, 408, 4597
WALL_H, WALL_V, WALL_CORNER = 1294, 1295, 1296
FENCE_H, FENCE_V, FENCE_CORNER = 2171, 2172, 2173
TREE, SMALL_TREE, BUSH, BLUEBERRY = 3614, 3682, 3681, 3699
WHEAT, WHEAT_GROWN, WHEAT_RIPE = 3651, 3652, 3653
SIGN, TABLE, CHAIR = 2012, 2322, 2358
BLOCKING = {WATER, WALL_H, WALL_V, WALL_CORNER, FENCE_H, FENCE_V,
            FENCE_CORNER, TREE, SMALL_TREE, BUSH, BLUEBERRY, SIGN, TABLE, WHEAT_RIPE}


@dataclass
class Tile:
    ground: int = GRASS
    items: list[tuple[int, str | None]] = field(default_factory=list)
    protection: bool = False


def make_tiles() -> dict[tuple[int, int], Tile]:
    xmin, ymin, xmax, ymax = BOUNDS
    tiles = {(x, y): Tile() for y in range(ymin, ymax + 1)
             for x in range(xmin, xmax + 1)}

    def place(x: int, y: int, item: int, text: str | None = None) -> None:
        tiles[x, y].items.append((item, text))

    # Walkable boundaries are deliberately closed with trees, not void tiles.
    for x in range(xmin, xmax + 1):
        place(x, ymin, SMALL_TREE)
        place(x, ymax, SMALL_TREE)
    for y in range(ymin + 1, ymax):
        place(xmin, y, SMALL_TREE)
        place(xmax, y, SMALL_TREE)

    # Main north/south and east/west paths join every playable area.
    for x, y in tiles:
        if 99 <= x <= 101 or 99 <= y <= 101:
            tiles[x, y].ground = DIRT
        if 96 <= x <= 104 and 96 <= y <= 104:
            tiles[x, y].ground = DIRT
            tiles[x, y].protection = True

    # A public farm cabin: no house ownership is needed to explore it.
    for y in range(88, 96):
        for x in range(89, 97):
            tiles[x, y].ground = WOOD
            tiles[x, y].protection = True
            if y in (88, 95) and x not in (92, 93):
                place(x, y, WALL_H)
            elif x in (89, 96):
                place(x, y, WALL_V)
    for x, y in ((89, 88), (96, 88), (89, 95), (96, 95)):
        tiles[x, y].items = [(WALL_CORNER, None)]
    # The north wall stays closed; the south entrance is two tiles wide.
    place(92, 88, WALL_H)
    place(93, 88, WALL_H)
    for y in range(96, 100):
        for x in (92, 93):
            tiles[x, y].ground = DIRT
    place(91, 90, TABLE)
    place(92, 90, CHAIR)

    # Eight short planting rows, split by a lane. Earth101 is solid rock in
    # this DAT; dirt103 is the walkable soil used by the farm instead.
    for y in (91, 93, 95, 97):
        for x in (*range(105, 109), *range(110, 114)):
            tiles[x, y].ground = DIRT
    for index, x in enumerate((105, 106, 107, 110, 111, 112)):
        place(x, 91, (WHEAT, WHEAT_GROWN, WHEAT_RIPE)[index % 3])
    place(114, 94, SIGN, "Canteiros: terra preparada para plantar. A arte 16px original vira aqui.")

    # Animal pasture with a west opening facing the path.
    for x in range(113, 124):
        place(x, 104, FENCE_H)
        place(x, 117, FENCE_H)
    for y in range(105, 117):
        if y not in (109, 110):
            place(113, y, FENCE_V)
        place(123, y, FENCE_V)
    for x, y in ((113, 104), (123, 104), (113, 117), (123, 117)):
        tiles[x, y].items = [(FENCE_CORNER, None)]
    for x in range(101, 114):
        for y in (109, 110):
            tiles[x, y].ground = DIRT

    # Pond and woodland provide fishing/wildlife space outside the plaza.
    for y in range(106, 115):
        for x in range(83, 89):
            if ((x - 85.5) / 3.5) ** 2 + ((y - 110) / 5) ** 2 <= 1:
                tiles[x, y].ground = WATER
    for x, y in ((84, 85), (87, 83), (83, 94), (86, 96), (107, 84),
                 (110, 86), (120, 83), (122, 91), (84, 119), (92, 118),
                 (107, 119), (124, 120)):
        place(x, y, TREE)
    for x, y in ((84, 91), (87, 116), (94, 113), (106, 115)):
        place(x, y, BLUEBERRY)
    for x, y in ((86, 86), (108, 86), (121, 92), (93, 118)):
        place(x, y, BUSH)

    place(100, 96, SIGN, "Bem-vindo a Backlands! Sementes a nordeste, colheitas a noroeste. Canteiros ao norte, animais a sudeste e lago a sudoeste.")
    return tiles


def walkable(tile: Tile) -> bool:
    return tile.ground not in BLOCKING and not any(i in BLOCKING for i, _ in tile.items)


def validate_layout(tiles: dict[tuple[int, int], Tile]) -> None:
    start = SPAWN[:2]
    assert walkable(tiles[start]), "The player spawn must be walkable."
    reached, pending = {start}, deque([start])
    while pending:
        x, y = pending.popleft()
        for target in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if target in tiles and target not in reached and walkable(tiles[target]):
                reached.add(target)
                pending.append(target)
    destinations = [(x, y) for _, x, y in (*NPCS, *ANIMALS)]
    destinations += [(92, 91), (105, 97), (113, 110), (89, 110)]
    for target in destinations:
        assert target in reached, f"Unreachable destination: {target}."
    for name, x, y in (*NPCS, *ANIMALS):
        assert walkable(tiles[x, y]), f"Blocked spawn: {name}."


def _escape(data: bytes) -> bytes:
    return b"".join((b"\xfd" + bytes((b,))) if b >= 253 else bytes((b,)) for b in data)


def node(kind: int, properties: bytes = b"", children: tuple[bytes, ...] | list[bytes] = ()) -> bytes:
    return b"\xfe" + _escape(bytes((kind,)) + properties) + b"".join(children) + b"\xff"


def string(value: str) -> bytes:
    data = value.encode("utf-8")
    return struct.pack("<H", len(data)) + data


def otbm_bytes(tiles: dict[tuple[int, int], Tile]) -> bytes:
    tile_nodes = []
    for (x, y), tile in sorted(tiles.items(), key=lambda entry: (entry[0][1], entry[0][0])):
        properties = bytes((x, y))
        if tile.protection:
            properties += b"\x03" + struct.pack("<I", 1)
        properties += b"\x09" + struct.pack("<H", tile.ground)
        children = []
        for item_id, text in tile.items:
            item_props = struct.pack("<H", item_id)
            if text:
                item_props += b"\x06" + string(text)
            children.append(node(6, item_props))
        tile_nodes.append(node(5, properties, children))
    area = node(4, struct.pack("<HHB", 0, 0, 7), tile_nodes)
    town = node(13, struct.pack("<I", 1) + string("Backlands") + struct.pack("<HHB", *SPAWN))
    towns = node(12, children=[town])
    metadata = (b"\x01" + string("Backlands starter farm; native 16px assets and ClientIDs")
                + b"\x0b" + string("world-spawn.xml") + b"\x0d" + string("world-house.xml"))
    data = node(2, metadata, [area, towns])
    # OTBM 2, item major 3 / minor 20 (CLIENT_VERSION_860), 256x256 bounds.
    return b"OTBM" + node(0, struct.pack("<IHHII", 2, 256, 256, 3, 20), [data])


def spawn_bytes() -> bytes:
    root = ET.Element("spawns")
    for kind, entries in (("npc", NPCS), ("monster", ANIMALS)):
        for name, x, y in entries:
            spawn = ET.SubElement(root, "spawn", centerx=str(x), centery=str(y), centerz="7", radius="2")
            attrs = dict(name=name, x="0", y="0", z="7", direction="2")
            if kind == "monster":
                attrs["spawntime"] = "60"
            ET.SubElement(spawn, kind, attrs)
    ET.indent(root, space="  ")
    return ET.tostring(root, encoding="utf-8", xml_declaration=True) + b"\n"


def build_files() -> dict[str, bytes]:
    tiles = make_tiles()
    validate_layout(tiles)
    return {"world.otbm": otbm_bytes(tiles), "world-spawn.xml": spawn_bytes(),
            "world-house.xml": b'<?xml version="1.0" encoding="UTF-8"?>\n<houses />\n'}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=REPO / "server/data/world")
    parser.add_argument("--check", action="store_true", help="Check committed files without changing them.")
    args = parser.parse_args()
    files = build_files()
    if args.check:
        for filename, expected in files.items():
            actual = (args.output / filename).read_bytes()
            if filename.endswith(".xml"):
                actual = actual.replace(b"\r\n", b"\n")
            if actual != expected:
                raise SystemExit(f"Different from generated starter world: {filename}")
    else:
        args.output.mkdir(parents=True, exist_ok=True)
        for filename, content in files.items():
            (args.output / filename).write_bytes(content)
    print(json.dumps({"tiles": len(make_tiles()), "spawn": SPAWN, "town_id": 1,
                      "npcs": len(NPCS), "animals": len(ANIMALS), "houses": 0,
                      "files": {name: len(data) for name, data in files.items()}}, indent=2))


if __name__ == "__main__":
    main()
