#!/usr/bin/env python3
import io
import struct
from pathlib import Path

from PIL import Image

import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from storymode_editor import app  # noqa: E402


GOFX_SFF = ROOT / "data/gofx.sff"
SUB_SFF = ROOT / "data/substitution_fx.sff"
OUT_SFF = ROOT / "data/gofx_merged.sff"

SUB_KEYS = [
    (25000, 0),
    (25000, 1),
    (7500, 2),
    (7500, 3),
    (7500, 4),
    (7500, 5),
    (7500, 6),
    (7500, 7),
    (7500, 8),
    (7500, 9),
    (9007, 1),
    (9007, 2),
    (9007, 3),
    (9007, 4),
    (9007, 5),
]


def iter_sff_v1_headers(blob: bytes):
    offset = struct.unpack_from("<I", blob, 24)[0]
    guard = 0
    while offset > 0 and offset + 32 <= len(blob) and guard < 20000:
        next_offset, data_length = struct.unpack_from("<II", blob, offset)
        axis_x, axis_y = struct.unpack_from("<hh", blob, offset + 8)
        group, item = struct.unpack_from("<HH", blob, offset + 12)
        yield {
            "group": group,
            "item": item,
            "axis_x": axis_x,
            "axis_y": axis_y,
            "data_length": data_length,
        }
        if not next_offset or next_offset <= offset:
            break
        offset = next_offset
        guard += 1


def collect_unique_v1_sprites(path: Path, wanted_keys=None):
    blob = path.read_bytes()
    _, sprite_map, load_sprite = app.load_sff_v1_sprites(blob)
    seen = set()
    entries = []
    for header in iter_sff_v1_headers(blob):
        key = (header["group"], header["item"])
        if key in seen:
            continue
        if wanted_keys is not None and key not in wanted_keys:
            continue
        idx = sprite_map.get(key)
        if idx is None:
            continue
        sprite = load_sprite(idx)
        entries.append(
            {
                "group": header["group"],
                "item": header["item"],
                "axis_x": int(sprite["axis_x"]),
                "axis_y": int(sprite["axis_y"]),
                "image": sprite["image"].convert("RGBA"),
            }
        )
        seen.add(key)
    return entries


def save_png_bytes(image: Image.Image) -> bytes:
    buf = io.BytesIO()
    image.save(buf, format="PNG")
    return buf.getvalue()


def remove_green_colorkey(image: Image.Image) -> Image.Image:
    img = image.convert("RGBA")
    out = []
    for r, g, b, a in img.getdata():
        if (r, g, b) == (0, 128, 0):
            out.append((r, g, b, 0))
        else:
            out.append((r, g, b, a))
    img.putdata(out)
    return img


def rgba_to_indexed_png(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    base = rgba.quantize(colors=255, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    src_palette = base.getpalette()[:255 * 3]
    if len(src_palette) < 255 * 3:
        src_palette.extend([0] * (255 * 3 - len(src_palette)))
    pal = [1, 0, 1] + src_palette
    if len(pal) < 256 * 3:
        pal.extend([0] * (256 * 3 - len(pal)))

    indexed = Image.new("P", rgba.size, 0)
    indexed.putpalette(pal[:256 * 3])
    src = rgba.load()
    base_px = base.load()
    dst = indexed.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            if src[x, y][3] == 0:
                dst[x, y] = 0
            else:
                dst[x, y] = min(int(base_px[x, y]) + 1, 255)
    indexed.info["transparency"] = bytes([0] + [255] * 255)
    return indexed


def build_v2_sff(entries, out_path: Path):
    version_bytes = bytes([0, 1, 0, 2])
    sprite_count = len(entries)
    sprite_offset = 0x200
    palette_offset = sprite_offset + sprite_count * 28
    palette_count = 0
    ldata_offset = palette_offset

    blob = bytearray(b"\x00" * ldata_offset)
    blob[:12] = b"ElecbyteSpr\x00"
    blob[12:16] = version_bytes

    struct.pack_into("<I", blob, 0x10, 0)
    struct.pack_into("<I", blob, 0x14, 0)
    struct.pack_into("<I", blob, 0x18, 0)
    struct.pack_into("<I", blob, 0x1C, 0)
    struct.pack_into("<I", blob, 0x20, 0)
    struct.pack_into("<I", blob, 0x24, sprite_offset)
    struct.pack_into("<I", blob, 0x28, sprite_count)
    struct.pack_into("<I", blob, 0x2C, palette_offset)
    struct.pack_into("<I", blob, 0x30, palette_count)
    struct.pack_into("<I", blob, 0x34, ldata_offset)

    comment = b"Made by Codex\nMerged GOFX + substitution assets\0"
    blob[0x44 : 0x44 + len(comment)] = comment

    ldata = bytearray()
    for idx, entry in enumerate(entries):
        width, height = entry["image"].size
        payload = struct.pack("<I", width * height) + save_png_bytes(entry["image"])
        fmt = int(entry.get("format", 11))
        depth = int(entry.get("depth", 32))
        palette_index = int(entry.get("palette_index", 0))
        data_offset = len(ldata)
        ldata.extend(payload)
        off = sprite_offset + idx * 28
        struct.pack_into("<H", blob, off + 0, entry["group"])
        struct.pack_into("<H", blob, off + 2, entry["item"])
        struct.pack_into("<H", blob, off + 4, width)
        struct.pack_into("<H", blob, off + 6, height)
        struct.pack_into("<h", blob, off + 8, entry["axis_x"])
        struct.pack_into("<h", blob, off + 10, entry["axis_y"])
        struct.pack_into("<H", blob, off + 12, 0)
        blob[off + 14] = fmt
        blob[off + 15] = depth
        struct.pack_into("<I", blob, off + 16, data_offset)
        struct.pack_into("<I", blob, off + 20, len(payload))
        struct.pack_into("<H", blob, off + 24, palette_index)
        struct.pack_into("<H", blob, off + 26, 0)

    blob.extend(ldata)
    struct.pack_into("<I", blob, 0x38, len(ldata))
    struct.pack_into("<I", blob, 0x3C, ldata_offset + len(ldata))
    struct.pack_into("<I", blob, 0x40, 0)

    out_path.write_bytes(blob)


def verify_output(path: Path, expected_keys):
    blob = path.read_bytes()
    version, sprite_map, load_sprite = app.load_sff_v2_sprites(blob)
    assert version == "SFF v2"
    missing = [key for key in expected_keys if key not in sprite_map]
    if missing:
        raise RuntimeError(f"Sprites faltantes en merged GOFX: {missing}")
    for key in expected_keys[:3]:
        spr = load_sprite(sprite_map[key])
        if spr["image"].width <= 0 or spr["image"].height <= 0:
            raise RuntimeError(f"Sprite inválido en merged GOFX: {key}")


def main():
    go_entries = collect_unique_v1_sprites(GOFX_SFF)
    sub_entries = collect_unique_v1_sprites(SUB_SFF, wanted_keys=set(SUB_KEYS))
    for entry in sub_entries:
        entry["image"] = rgba_to_indexed_png(remove_green_colorkey(entry["image"]))
        entry["format"] = 10
        entry["depth"] = 8
        entry["palette_index"] = 0
    merged = go_entries + [entry for entry in sub_entries if (entry["group"], entry["item"]) not in {(e["group"], e["item"]) for e in go_entries}]
    build_v2_sff(merged, OUT_SFF)
    verify_output(OUT_SFF, [(e["group"], e["item"]) for e in go_entries] + SUB_KEYS)
    print(f"wrote {OUT_SFF.relative_to(ROOT)} with {len(merged)} sprites")


if __name__ == "__main__":
    main()
