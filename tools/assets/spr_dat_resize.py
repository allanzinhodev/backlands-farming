#!/usr/bin/env python3
"""Resize a protocol 8.6x Tibia.dat/Tibia.spr pair from 32px to 16px sprites.

Used to produce placeholder/test assets for the 16px NexaMap build
(map-editor, CMake option NEXAMAP_SPRITE_PIXELS=16). Real Backlands art should
be drawn at 16px; this only exists so the pipeline can be tested end to end.

What changes:
  .spr  every sprite is decoded, downscaled 32 -> 16 (box filter, alpha
        thresholded because 8.6 sprites have no partial alpha) and re-encoded.
  .dat  pixel values are scaled: Displacement (x, y), Elevation and the
        "exact size" byte of multi-tile objects. Everything else is copied.
  .otfi written next to the output with sprite-size set to the new size.

Usage:
  python -I spr_dat_resize.py <input_dir> <output_dir> [--size 16]

The input dir holds Tibia.dat, Tibia.spr and optionally Tibia.otfi (read for
extended / transparency / frame-durations / frame-groups). Requires Pillow.
"""
from __future__ import annotations

import argparse
import struct
import sys
import time
from pathlib import Path

from PIL import Image

SOURCE_SIZE = 32

# 8.6 dat flags -> number of payload bytes (None = special handling).
FLAG_PAYLOAD = {
    0: 2,  # Ground: speed
    8: 2, 9: 2,  # Writable, WritableOnce: max length
    21: 4,  # Light: intensity, color
    24: None,  # Displacement: x, y (pixels)
    25: None,  # Elevation (pixels)
    28: 2,  # MinimapColor
    29: 2,  # LensHelp
    32: 2,  # Cloth
    33: None,  # Market
    34: 2,  # Usable
}
NO_PAYLOAD = {1, 2, 3, 4, 5, 6, 7, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
              22, 23, 26, 27, 30, 31, 35, 36, 37}
FLAG_END = 0xFF


def read_otfi(path: Path) -> dict:
    opts = {"extended": False, "transparency": False, "frame-durations": False, "frame-groups": False}
    if not path.exists():
        return opts
    for line in path.read_text(encoding="utf-8").splitlines():
        key, sep, value = line.strip().partition(":")
        if sep and key in opts:
            opts[key] = value.strip().lower() == "true"
    return opts


class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0

    def take(self, n: int) -> bytes:
        if self.pos + n > len(self.data):
            raise ValueError(f"truncated at offset {self.pos}")
        chunk = self.data[self.pos:self.pos + n]
        self.pos += n
        return chunk

    def u8(self) -> int:
        return self.take(1)[0]

    def u16(self) -> int:
        return struct.unpack("<H", self.take(2))[0]


def scale(value: int, factor: float) -> int:
    return int(round(value * factor))


def convert_dat(data: bytes, opts: dict, factor: float) -> bytes:
    r = Reader(data)
    out = bytearray(r.take(4))  # signature
    counts = [r.u16() for _ in range(4)]  # items, outfits, effects, missiles
    out += struct.pack("<4H", *counts)
    totals = [counts[0] - 99, counts[1], counts[2], counts[3]]  # items start at id 100
    sprite_id_size = 4 if opts["extended"] else 2

    for category, total in enumerate(totals):
        for _ in range(total):
            while True:  # flags
                flag = r.u8()
                out.append(flag)
                if flag == FLAG_END:
                    break
                if flag == 24:
                    x, y = r.u16(), r.u16()
                    out += struct.pack("<HH", scale(x, factor), scale(y, factor))
                elif flag == 25:
                    out += struct.pack("<H", scale(r.u16(), factor))
                elif flag == 33:
                    out += r.take(6)
                    name_len = r.u16()
                    out += struct.pack("<H", name_len) + r.take(name_len) + r.take(4)
                elif flag in FLAG_PAYLOAD:
                    out += r.take(FLAG_PAYLOAD[flag])
                elif flag not in NO_PAYLOAD:
                    raise ValueError(f"unknown dat flag {flag} at offset {r.pos - 1}")

            groups = 1
            if opts["frame-groups"] and category == 1:
                groups = r.u8()
                out.append(groups)
            for _ in range(groups):
                if opts["frame-groups"] and category == 1:
                    out.append(r.u8())  # group type
                width, height = r.u8(), r.u8()
                out += bytes((width, height))
                if width > 1 or height > 1:
                    out.append(max(1, scale(r.u8(), factor)))  # exact size in pixels
                layers, px, py, pz, frames = (r.u8() for _ in range(5))
                out += bytes((layers, px, py, pz, frames))
                if frames > 1 and opts["frame-durations"]:
                    out += r.take(1 + 4 + 1 + frames * 8)
                count = width * height * layers * px * py * pz * frames
                out += r.take(count * sprite_id_size)

    if r.pos != len(data):
        raise ValueError(f"dat has {len(data) - r.pos} trailing bytes; format flags are probably wrong")
    return bytes(out)


def decode_sprite(dump: bytes, alpha: bool) -> bytes:
    pixels = SOURCE_SIZE * SOURCE_SIZE
    bpp = 4 if alpha else 3
    rgba = bytearray(pixels * 4)
    write = read = 0
    while read + 2 <= len(dump) and write < pixels:
        transparent = dump[read] | dump[read + 1] << 8
        read += 2
        write += transparent
        if write >= pixels or read + 2 > len(dump):
            break
        colored = dump[read] | dump[read + 1] << 8
        read += 2
        for _ in range(colored):
            if write >= pixels or read + bpp > len(dump):
                break
            o = write * 4
            rgba[o:o + 3] = dump[read:read + 3]
            rgba[o + 3] = dump[read + 3] if alpha else 0xFF
            write += 1
            read += bpp
    return bytes(rgba)


def encode_sprite(rgba: bytes, size: int, alpha: bool) -> bytes:
    pixels = size * size
    out = bytearray()
    i = 0
    while i < pixels:
        start = i
        while i < pixels and rgba[i * 4 + 3] == 0:
            i += 1
        transparent = i - start
        if i >= pixels:
            break  # trailing transparency is implicit
        start = i
        colored = bytearray()
        while i < pixels and rgba[i * 4 + 3] != 0:
            o = i * 4
            colored += rgba[o:o + 4] if alpha else rgba[o:o + 3]
            i += 1
        out += struct.pack("<HH", transparent, i - start) + colored
    return bytes(out)


def resize_sprite(rgba: bytes, size: int, alpha: bool) -> bytes:
    img = Image.frombytes("RGBA", (SOURCE_SIZE, SOURCE_SIZE), rgba)
    img = img.resize((size, size), Image.Resampling.BOX)
    data = bytearray(img.tobytes())
    if not alpha:  # 8.6 sprites are either opaque or fully transparent
        for o in range(3, len(data), 4):
            data[o] = 0xFF if data[o] >= 128 else 0
    return bytes(data)


def convert_spr(data: bytes, opts: dict, size: int) -> bytes:
    r = Reader(data)
    signature = r.take(4)
    count = struct.unpack("<I", r.take(4))[0] if opts["extended"] else r.u16()
    offsets = struct.unpack(f"<{count}I", r.take(count * 4))
    alpha = opts["transparency"]

    header = signature + (struct.pack("<I", count) if opts["extended"] else struct.pack("<H", count))
    body = bytearray()
    new_offsets = []
    base = len(header) + count * 4
    started = time.time()
    for index, offset in enumerate(offsets, 1):
        if offset == 0:
            new_offsets.append(0)
            continue
        dump_size = struct.unpack_from("<H", data, offset + 3)[0]
        dump = data[offset + 5:offset + 5 + dump_size]
        encoded = encode_sprite(resize_sprite(decode_sprite(dump, alpha), size, alpha), size, alpha)
        if not encoded:
            new_offsets.append(0)
            continue
        new_offsets.append(base + len(body))
        body += b"\xff\x00\xff" + struct.pack("<H", len(encoded)) + encoded
        if index % 50000 == 0:
            print(f"  {index}/{count} sprites ({time.time() - started:.0f}s)", flush=True)
    return header + struct.pack(f"<{count}I", *new_offsets) + bytes(body)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--size", type=int, default=16, choices=(16,))
    args = parser.parse_args()

    opts = read_otfi(args.input_dir / "Tibia.otfi")
    factor = args.size / SOURCE_SIZE
    args.output_dir.mkdir(parents=True, exist_ok=True)
    print(f"format: {opts}")

    print("dat...", flush=True)
    dat = convert_dat((args.input_dir / "Tibia.dat").read_bytes(), opts, factor)
    (args.output_dir / "Tibia.dat").write_bytes(dat)

    print("spr...", flush=True)
    spr = convert_spr((args.input_dir / "Tibia.spr").read_bytes(), opts, args.size)
    (args.output_dir / "Tibia.spr").write_bytes(spr)

    lines = ["DatSpr"] + [f"  {k}: {str(v).lower()}" for k, v in opts.items()] + [
        "  metadata-file: Tibia.dat",
        "  sprites-file: Tibia.spr",
        f"  sprite-size: {args.size}",
        f"  sprite-data-size: {args.size * args.size * 4}",
    ]
    (args.output_dir / "Tibia.otfi").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"done: {args.output_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
