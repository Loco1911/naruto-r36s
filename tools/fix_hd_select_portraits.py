#!/usr/bin/env python3
import io
import os
import struct
from pathlib import Path

from PIL import Image

import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from storymode_editor import app  # noqa: E402


def fit_portrait(src_img: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    work = src_img.convert("RGBA")
    work.thumbnail(target_size, Image.Resampling.LANCZOS)
    x = (target_size[0] - work.width) // 2
    y = (target_size[1] - work.height) // 2
    canvas.alpha_composite(work, (x, y))
    return canvas


def save_png_bytes(img: Image.Image) -> bytes:
    buf = io.BytesIO()
    out = img
    if out.mode != "P":
        out = out.convert("RGBA").quantize(colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    out.save(buf, format="PNG")
    return buf.getvalue()


def patch_sprite_header(blob: bytearray, sprite_offset: int, idx: int, *, width: int, height: int,
                        axis_x: int, axis_y: int, data_offset: int, data_length: int,
                        fmt: int = 10, depth: int = 32, palette_index: int = 0, flags: int = 0) -> None:
    off = sprite_offset + idx * 28
    struct.pack_into("<H", blob, off + 4, width)
    struct.pack_into("<H", blob, off + 6, height)
    struct.pack_into("<h", blob, off + 8, axis_x)
    struct.pack_into("<h", blob, off + 10, axis_y)
    blob[off + 14] = fmt
    blob[off + 15] = depth
    struct.pack_into("<I", blob, off + 16, data_offset)
    struct.pack_into("<I", blob, off + 20, data_length)
    struct.pack_into("<H", blob, off + 24, palette_index)
    struct.pack_into("<H", blob, off + 26, flags)


def patch_section_lengths(blob: bytearray) -> bool:
    ldata_offset = struct.unpack_from("<I", blob, 0x34)[0]
    ldata_length = struct.unpack_from("<I", blob, 0x38)[0]
    tdata_offset = struct.unpack_from("<I", blob, 0x3C)[0]
    tdata_length = struct.unpack_from("<I", blob, 0x40)[0]
    expected_tdata_offset = ldata_offset + ldata_length
    file_length = len(blob)

    # Our portrait fix appends literal PNG bytes. If the file has no translated
    # data section, the global ldata/tdata header values must grow with the file.
    if tdata_length == 0 and tdata_offset == expected_tdata_offset and file_length > tdata_offset:
        struct.pack_into("<I", blob, 0x38, file_length - ldata_offset)
        struct.pack_into("<I", blob, 0x3C, file_length)
        return True
    return False


def get_sprite_header(blob: bytes | bytearray, sprite_offset: int, idx: int) -> dict:
    off = sprite_offset + idx * 28
    return {
        "group": struct.unpack_from("<H", blob, off)[0],
        "item": struct.unpack_from("<H", blob, off + 2)[0],
        "width": struct.unpack_from("<H", blob, off + 4)[0],
        "height": struct.unpack_from("<H", blob, off + 6)[0],
        "axis_x": struct.unpack_from("<h", blob, off + 8)[0],
        "axis_y": struct.unpack_from("<h", blob, off + 10)[0],
        "linked": struct.unpack_from("<H", blob, off + 12)[0],
        "format": blob[off + 14],
        "color_depth": blob[off + 15],
        "data_offset": struct.unpack_from("<I", blob, off + 16)[0],
        "data_length": struct.unpack_from("<I", blob, off + 20)[0],
        "palette_index": struct.unpack_from("<H", blob, off + 24)[0],
        "flags": struct.unpack_from("<H", blob, off + 26)[0],
    }


def has_valid_png_prefix(blob: bytes | bytearray, ldata_offset: int, header: dict) -> bool:
    start = ldata_offset + header["data_offset"]
    if start + 12 > len(blob):
        return False
    expected_prefix = header["width"] * header["height"]
    return (
        struct.unpack_from("<I", blob, start)[0] == expected_prefix
        and blob[start + 4:start + 12] == b"\x89PNG\r\n\x1a\n"
    )


def load_palette_bytes(sff_blob: bytes, index: int) -> bytes | None:
    palette_offset = struct.unpack_from("<I", sff_blob, 0x2C)[0]
    palette_count = struct.unpack_from("<I", sff_blob, 0x30)[0]
    ldata_offset = struct.unpack_from("<I", sff_blob, 0x34)[0]
    if not (0 <= index < palette_count):
        return None
    seen = set()
    while 0 <= index < palette_count and index not in seen:
        seen.add(index)
        off = palette_offset + index * 16
        if off + 16 > len(sff_blob):
            return None
        linked = struct.unpack_from("<H", sff_blob, off + 6)[0]
        data_offset = struct.unpack_from("<I", sff_blob, off + 8)[0]
        data_length = struct.unpack_from("<I", sff_blob, off + 12)[0]
        if data_length == 0:
            index = linked
            continue
        start = ldata_offset + data_offset
        return bytes(sff_blob[start:start + data_length])
    return None


def palette_bytes_to_rgb_triplets(palette_bytes: bytes) -> list[int]:
    if not palette_bytes:
        return [0] * (256 * 3)
    if len(palette_bytes) % 4 == 0 and len(palette_bytes) % 3 != 0:
        rgba = palette_bytes
        rgb = []
        for i in range(256):
            src = i * 4
            if src + 2 >= len(rgba):
                rgb.extend((0, 0, 0))
            else:
                rgb.extend((rgba[src], rgba[src + 1], rgba[src + 2]))
        return rgb[:256 * 3]
    rgb = list(palette_bytes[:256 * 3])
    if len(rgb) < 256 * 3:
        rgb.extend([0] * (256 * 3 - len(rgb)))
    return rgb


def quantize_to_palette(img: Image.Image, palette_bytes: bytes) -> Image.Image:
    rgba = img.convert("RGBA")
    pal = palette_bytes_to_rgb_triplets(palette_bytes)
    # Reserve index 0 for transparency and make it an unlikely visible color.
    pal[0:3] = [1, 0, 1]
    pal_img = Image.new("P", (16, 16))
    pal_img.putpalette(pal)
    quantized = Image.new("P", rgba.size, 0)
    quantized.putpalette(pal)
    qpix = quantized.load()
    src = rgba.load()
    width, height = rgba.size
    palette_rgb = [(pal[i * 3], pal[i * 3 + 1], pal[i * 3 + 2]) for i in range(256)]
    for y in range(height):
        for x in range(width):
            r, g, b, a = src[x, y]
            if a == 0:
                qpix[x, y] = 0
                continue
            # Avoid turning real black/shadow pixels transparent.
            best_idx = 1
            best_dist = None
            for idx in range(1, 256):
                pr, pg, pb = palette_rgb[idx]
                dist = (r - pr) * (r - pr) + (g - pg) * (g - pg) + (b - pb) * (b - pb)
                if best_dist is None or dist < best_dist:
                    best_dist = dist
                    best_idx = idx
            qpix[x, y] = best_idx
    quantized.info["transparency"] = bytes([0] + [255] * 255)
    return quantized


def fix_sff(sff_path: Path) -> bool:
    with sff_path.open("rb") as f:
        raw = f.read()
    if raw[:12] != b"ElecbyteSpr\x00" or raw[15] != 2:
        return False
    backup = sff_path.with_suffix(sff_path.suffix + ".orig")
    source_raw = backup.read_bytes() if backup.exists() else raw

    version, sprite_map, load_sprite = app.load_sff_v2_sprites(source_raw)
    idx0 = sprite_map.get((9000, 0))
    idx1 = sprite_map.get((9000, 1))
    idx3 = sprite_map.get((9000, 3))
    if idx0 is None or idx1 is None or idx3 is None:
        return False

    spr0 = load_sprite(idx0)
    spr1 = load_sprite(idx1)
    spr3 = load_sprite(idx3)
    sprite_offset = struct.unpack_from("<I", source_raw, 0x24)[0]
    ldata_offset = struct.unpack_from("<I", source_raw, 0x34)[0]
    hdr0 = get_sprite_header(source_raw, sprite_offset, idx0)
    hdr1 = get_sprite_header(source_raw, sprite_offset, idx1)
    valid_small_pngs = (
        spr0["image"].size == (25, 25)
        and spr1["image"].size == (120, 162)
        and hdr0["format"] == 10
        and hdr1["format"] == 10
        and hdr0["color_depth"] == 8
        and hdr1["color_depth"] == 8
        and has_valid_png_prefix(source_raw, ldata_offset, hdr0)
        and has_valid_png_prefix(source_raw, ldata_offset, hdr1)
    )

    if valid_small_pngs:
        blob = bytearray(raw)
        if patch_section_lengths(blob):
            sff_path.write_bytes(blob)
            print(f"repaired headers {sff_path.relative_to(ROOT)}")
            return True
        return False

    needs_rebuild = (
        (spr0["image"].size == (1280, 720) and spr1["image"].size == (1280, 720))
        or (
            spr0["image"].size == (25, 25)
            and spr1["image"].size == (120, 162)
            and spr3["image"].size == (1280, 720)
        )
    )

    # Only patch the HD portrait packs we actually identified.
    if not needs_rebuild:
        return False

    bbox = spr3["image"].getbbox()
    if bbox is None:
        return False

    crop = spr3["image"].crop(bbox)
    icon_img = fit_portrait(crop, (25, 25))
    face_img = fit_portrait(crop, (120, 162))
    icon_palette = load_palette_bytes(source_raw, hdr0["palette_index"])
    face_palette = load_palette_bytes(source_raw, hdr1["palette_index"])
    icon_indexed = quantize_to_palette(icon_img, icon_palette or b"")
    face_indexed = quantize_to_palette(face_img, face_palette or b"")
    icon_png = struct.pack("<I", icon_img.width * icon_img.height) + save_png_bytes(icon_indexed)
    face_png = struct.pack("<I", face_img.width * face_img.height) + save_png_bytes(face_indexed)

    blob = bytearray(source_raw)

    icon_data_offset = len(blob) - ldata_offset
    blob.extend(icon_png)
    face_data_offset = len(blob) - ldata_offset
    blob.extend(face_png)

    patch_sprite_header(
        blob,
        sprite_offset,
        idx0,
        width=25,
        height=25,
        axis_x=15,
        axis_y=0,
        data_offset=icon_data_offset,
        data_length=len(icon_png),
        depth=8,
        palette_index=hdr0["palette_index"],
        flags=hdr0["flags"],
    )
    patch_sprite_header(
        blob,
        sprite_offset,
        idx1,
        width=120,
        height=162,
        axis_x=0,
        axis_y=0,
        data_offset=face_data_offset,
        data_length=len(face_png),
        depth=8,
        palette_index=hdr1["palette_index"],
        flags=hdr1["flags"],
    )
    patch_section_lengths(blob)

    if not backup.exists():
        backup.write_bytes(raw)
    sff_path.write_bytes(blob)
    print(f"patched {sff_path.relative_to(ROOT)}")
    return True


def main() -> int:
    patched = 0
    for char_dir in sorted((ROOT / "chars").iterdir()):
        if not char_dir.is_dir():
            continue
        sff_files = sorted(p for p in char_dir.iterdir() if p.suffix.lower() == ".sff")
        for sff_path in sff_files:
            if fix_sff(sff_path):
                patched += 1
    print(f"patched_total={patched}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
