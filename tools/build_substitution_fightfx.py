#!/usr/bin/env python3
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUB_SFF = ROOT / "data/substitution_fx.sff"
SUB_KEYS = {
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
}

TARGETS = [
    {
        "base": ROOT / "lifebars/NCoNR2/lfx-flashy.sff",
        "out": ROOT / "lifebars/NCoNR2/lfx-flashy_sub.sff",
    },
    {
        "base": ROOT / "lifebars/NxBBC/fightfx.sff",
        "out": ROOT / "lifebars/NxBBC/fightfx_sub.sff",
    },
]


def parse_v1_entries(path: Path):
    blob = path.read_bytes()
    header = bytearray(blob[:512])
    offset = struct.unpack_from("<I", blob, 24)[0]
    entries = []
    guard = 0
    while offset > 0 and offset + 32 <= len(blob) and guard < 50000:
        raw_header = bytearray(blob[offset : offset + 32])
        next_offset, data_length = struct.unpack_from("<II", raw_header, 0)
        group, item = struct.unpack_from("<HH", raw_header, 12)
        entries.append(
            {
                "group": group,
                "item": item,
                "header": raw_header,
                "data": bytes(blob[offset + 32 : offset + 32 + data_length]),
            }
        )
        if not next_offset or next_offset <= offset:
            break
        offset = next_offset
        guard += 1
    return header, entries


def build_v1_sff(base_path: Path, out_path: Path):
    base_header, base_entries = parse_v1_entries(base_path)
    _, sub_entries_all = parse_v1_entries(SUB_SFF)
    sub_entries = [entry for entry in sub_entries_all if (entry["group"], entry["item"]) in SUB_KEYS]

    existing = {(entry["group"], entry["item"]) for entry in base_entries}
    merged_entries = list(base_entries)
    merged_entries.extend(entry for entry in sub_entries if (entry["group"], entry["item"]) not in existing)

    groups = {entry["group"] for entry in merged_entries}
    struct.pack_into("<I", base_header, 16, len(groups))
    struct.pack_into("<I", base_header, 20, len(merged_entries))
    struct.pack_into("<I", base_header, 24, 512)
    struct.pack_into("<I", base_header, 28, 32)

    out = bytearray(base_header)
    offset = 512
    for i, entry in enumerate(merged_entries):
        raw_header = bytearray(entry["header"])
        data = entry["data"]
        next_offset = 0 if i == len(merged_entries) - 1 else offset + 32 + len(data)
        struct.pack_into("<I", raw_header, 0, next_offset)
        struct.pack_into("<I", raw_header, 4, len(data))
        out.extend(raw_header)
        out.extend(data)
        offset = next_offset

    out_path.write_bytes(out)


def verify_v1_sff(path: Path):
    blob = path.read_bytes()
    if blob[:12] != b"ElecbyteSpr\x00" or list(blob[12:16]) != [0, 1, 0, 1]:
        raise RuntimeError(f"{path} no quedo en formato SFF v1")
    offset = struct.unpack_from("<I", blob, 24)[0]
    guard = 0
    found = set()
    while offset > 0 and offset + 32 <= len(blob) and guard < 50000:
        next_offset = struct.unpack_from("<I", blob, offset)[0]
        group, item = struct.unpack_from("<HH", blob, offset + 12)
        found.add((group, item))
        if not next_offset or next_offset <= offset:
            break
        offset = next_offset
        guard += 1
    missing = sorted(key for key in SUB_KEYS if key not in found)
    if missing:
        raise RuntimeError(f"Sprites de sustitucion faltantes en {path}: {missing}")


def main():
    for target in TARGETS:
        build_v1_sff(target["base"], target["out"])
        verify_v1_sff(target["out"])
        print(f"wrote {target['out'].relative_to(ROOT)}")


if __name__ == "__main__":
    main()
