"""Validate the generated farm against the actual DAT/OTB and an independent parser."""

from collections import deque
from pathlib import Path
import re
import struct
import sys
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "object-editor"))
from backlands_editor.formats import read_dat, read_otfi
from backlands_editor.server_items import OtbFile, _read_node

import create_starter_world as world


class StarterWorldTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.files = world.build_files()
        cls.tiles = world.make_tiles()
        assets = world.REPO / "assets/860"
        cls.dat = read_dat((assets / "Tibia.dat").read_bytes(), read_otfi(assets / "Tibia.otfi"))
        cls.otb = OtbFile.load(world.REPO / "server/data/items/items.otb")
        cls.items = {record.client_id: record for record in cls.otb.records}

    def test_independent_binary_reader(self):
        data = self.files["world.otbm"]
        self.assertEqual(data[:4], b"OTBM")
        root, end = _read_node(data, 4)
        self.assertEqual(end, len(data))
        self.assertEqual(struct.unpack("<IHHII", root.payload[1:]), (2, 256, 256, 3, 20))
        self.assertEqual(len(root.children), 1)
        map_node = root.children[0]
        self.assertEqual(map_node.payload[0], 2)
        area, towns = map_node.children
        self.assertEqual(area.payload, b"\x04" + struct.pack("<HHB", 0, 0, 7))
        self.assertEqual(len(area.children), 2021)
        seen = set()
        for tile in area.children:
            self.assertEqual(tile.payload[0], 5)
            pos = tuple(tile.payload[1:3])
            self.assertNotIn(pos, seen)
            seen.add(pos)
            expected = self.tiles[pos]
            offset = 3
            if expected.protection:
                self.assertEqual(tile.payload[offset:offset + 5], b"\x03\x01\x00\x00\x00")
                offset += 5
            self.assertEqual(tile.payload[offset:], b"\x09" + struct.pack("<H", expected.ground))
            self.assertEqual([struct.unpack_from("<H", i.payload, 1)[0] for i in tile.children],
                             [item_id for item_id, _ in expected.items])
        self.assertEqual(seen, set(self.tiles))
        self.assertEqual(towns.payload, b"\x0c")
        self.assertEqual(len(towns.children), 1)
        temple = towns.children[0].payload
        self.assertEqual(temple, b"\x0d" + struct.pack("<I", 1)
                         + b"\x09\x00Backlands" + struct.pack("<HHB", *world.SPAWN))

    def test_native_item_ids_and_ground_flags(self):
        for tile in self.tiles.values():
            record = self.items[tile.ground]
            self.assertEqual(record.group, 1, f"Not a ground: {tile.ground}")
            self.assertIn(0, [a.code for a in self.dat.categories[0][tile.ground - 100].attributes])
            for item_id in (tile.ground, *(item for item, _ in tile.items)):
                self.assertIn(item_id, self.items)
                attributes = self.dat.categories[0][item_id - 100].attributes
                dat_blocks = any(a.code == 12 for a in attributes)
                self.assertEqual(bool(self.items[item_id].flags & 1), dat_blocks,
                                 f"Client/server disagree about solid item: {item_id}")

    def test_routes_with_actual_server_solid_flags(self):
        def can_walk(position):
            tile = self.tiles[position]
            return not any(self.items[item_id].flags & 1
                           for item_id in (tile.ground, *(i for i, _ in tile.items)))

        start = world.SPAWN[:2]
        self.assertTrue(can_walk(start))
        reached, queue = {start}, deque([start])
        while queue:
            x, y = queue.popleft()
            for target in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if target in self.tiles and target not in reached and can_walk(target):
                    reached.add(target)
                    queue.append(target)
        for name, x, y in (*world.NPCS, *world.ANIMALS):
            self.assertIn((x, y), reached, name)
        for target in ((92, 91), (105, 97), (113, 110), (89, 110)):
            self.assertIn(target, reached)

    def test_spawns_and_empty_houses(self):
        spawns = ET.fromstring(self.files["world-spawn.xml"])
        entries = [(entity.tag, entity.get("name"), int(spawn.get("centerx")),
                    int(spawn.get("centery")), int(spawn.get("centerz")))
                   for spawn in spawns for entity in spawn]
        self.assertEqual(entries, [("npc", n, x, y, 7) for n, x, y in world.NPCS]
                         + [("monster", n, x, y, 7) for n, x, y in world.ANIMALS])
        self.assertFalse(spawns.findall(".//monster"), "The starter farm has no registered animal types yet.")
        self.assertEqual(len(ET.fromstring(self.files["world-house.xml"])), 0)

    def test_spawn_names_have_real_creature_definitions(self):
        registered = {"npc": set(), "monster": set()}
        for kind, directory, constructor in (("npc", "npc", "createNpcType"),
                                              ("monster", "monsters", "createMonsterType")):
            pattern = re.compile(
                rf"^\s*(?:local\s+\w+\s*=\s*)?Game\s*\.\s*{constructor}"
                r"\s*\(\s*([\"'])(.*?)\1\s*\)", re.MULTILINE)
            for source in (world.REPO / "server/data" / directory).rglob("*.lua"):
                code = source.read_text(encoding="utf-8-sig")
                # Commented examples must not make a missing creature pass.
                code = re.sub(r"--\[(=*)\[.*?\]\1\]", "", code, flags=re.DOTALL)
                registered[kind].update(match.group(2).casefold() for match in pattern.finditer(code))

        spawns = ET.parse(world.REPO / "server/data/world/world-spawn.xml").getroot()
        for spawn in spawns:
            for creature in spawn:
                name = creature.get("name", "")
                with self.subTest(kind=creature.tag, name=name, x=spawn.get("centerx"),
                                  y=spawn.get("centery")):
                    self.assertIn(name.casefold(), registered[creature.tag],
                                  f"Spawned {creature.tag} {name!r} has no real Lua type definition.")

    def test_farmer_appearance_exists_in_dat(self):
        root = ET.parse(world.REPO / "server/data/XML/vocations.xml").getroot()
        self.assertEqual([(v.get("id"), v.get("name")) for v in root], [("0", "Farmer")])
        outfits = ET.parse(world.REPO / "server/data/XML/outfits.xml").getroot()
        self.assertEqual({int(o.get("looktype")) for o in outfits}, {128, 136})
        for outfit in outfits:
            looktype = int(outfit.get("looktype"))
            self.assertGreaterEqual(self.dat.categories[1][looktype - 1].groups[0].layers, 2)
        mounts = ET.parse(world.REPO / "server/data/XML/mounts.xml").getroot()
        self.assertEqual(len(mounts), 0)

    def test_committed_world_is_reproducible(self):
        for filename, generated in self.files.items():
            actual = (world.REPO / "server/data/world" / filename).read_bytes()
            if filename.endswith(".xml"):
                actual = actual.replace(b"\r\n", b"\n")
            self.assertEqual(actual, generated)


if __name__ == "__main__":
    unittest.main()
