#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Build an ARM64 PortMaster release zip from the repository root.

The repository root is the canonical game tree used for local x64 testing.
This script creates the PortMaster shape in a temporary staging folder:

  Ikemen.sh
  IkemenDebug.sh
  IkemenGamepad.sh
  ikemen/

The ikemen/ folder contains game data plus ARM64 binaries only. Desktop x64
binaries, development tools, logs, editor files, old nested staging folders,
and Windows metadata are excluded.

Usage:
  tools/build-portmaster-release.sh [options]

Options:
  -o, --output PATH   Output zip path. Default: dist/ikemen.zip
  -n, --dry-run       Show the rsync plan without creating a zip.
  --keep-staging      Keep the temporary staging folder after building.
  -h, --help          Show this help.
EOF
}

die() {
  echo "build-portmaster-release: $*" >&2
  exit 1
}

info() {
  echo "build-portmaster-release: $*"
}

OUTPUT=""
DRY_RUN=0
KEEP_STAGING=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      [[ $# -ge 2 ]] || die "$1 requires a path"
      OUTPUT="$2"
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=1
      ;;
    --keep-staging)
      KEEP_STAGING=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

command -v rsync >/dev/null 2>&1 || die "rsync is required"
command -v python3 >/dev/null 2>&1 || die "python3 is required"

if [[ -z "$OUTPUT" ]]; then
  OUTPUT="$REPO_ROOT/dist/ikemen.zip"
elif [[ "$OUTPUT" != /* ]]; then
  OUTPUT="$REPO_ROOT/$OUTPUT"
fi

REQUIRED_ROOT_FILES=(
  "Ikemen.sh"
  "IkemenDebug.sh"
  "IkemenGamepad.sh"
  "ikemen_linux.aarch64"
  "sdlGamepadMapper"
  "port.json"
  "gameinfo.xml"
  "ikemen.md"
  "screenshot.png"
  "screenshot2.png"
  "screenshot3.png"
  "licenses/License.txt"
)

REQUIRED_CONTENT_DIRS=(
  "chars"
  "data"
  "external"
  "font"
  "lifebars"
  "moves"
  "save"
  "sound"
  "stages"
  "storymode"
)

for rel in "${REQUIRED_ROOT_FILES[@]}"; do
  [[ -f "$REPO_ROOT/$rel" ]] || die "missing required release file: $rel"
done

for rel in "${REQUIRED_CONTENT_DIRS[@]}"; do
  [[ -d "$REPO_ROOT/$rel" ]] || die "missing required content folder: $rel"
done

TMP_PARENT="$REPO_ROOT/.portmaster-build"
mkdir -p "$TMP_PARENT"
STAGE_ROOT="$(mktemp -d "$TMP_PARENT/release.XXXXXX")"

cleanup() {
  if [[ "$KEEP_STAGING" -eq 0 ]]; then
    rm -rf "$STAGE_ROOT"
    rmdir "$TMP_PARENT" 2>/dev/null || true
  else
    info "kept staging folder: ${STAGE_ROOT#$REPO_ROOT/}"
  fi
}
trap cleanup EXIT

ZIP_ROOT="$STAGE_ROOT/ziproot"
GAME_DIR="$ZIP_ROOT/ikemen"
mkdir -p "$GAME_DIR"

RSYNC_ARGS=(
  -a
  --human-readable
  --exclude='*:Zone.Identifier'
  --exclude='/.git/***'
  --exclude='/.github/***'
  --exclude='/.codex'
  --exclude='/.gitattributes'
  --exclude='/.gitignore'
  --exclude='/.portmaster-build/***'
  --exclude='/dist/***'
  --exclude='/ikemen/***'
  --exclude='/tools/***'
  --exclude='/storymode_editor/***'
  --exclude='/Malusardi N4rut0 MUG3N 2022 V5/***'
  --exclude='/vault_root/***'
  --exclude='/debug/***'
  --exclude='/Ikemen.sh'
  --exclude='/IkemenDebug.sh'
  --exclude='/IkemenGamepad.sh'
  --exclude='/Ikemen_GO'
  --exclude='/Ikemen_GO_Linux'
  --exclude='/Ikemen_GO.command'
  --exclude='/Ikemen_GO_Mac*'
  --exclude='/Ikemen_GO-v*.zip'
  --exclude='*.exe'
  --exclude='*.log'
  --exclude='*.crash'
  --exclude='*.orig'
  --exclude='Thumbs.db'
  --exclude='.DS_Store'
  --exclude='*.docx'
  --exclude='*.aseprite'
  --exclude='*.onetoc2'
  --exclude='/data/NxBBC/export/***'
  --exclude='/data/work/***'
  --exclude='/data/NxBBC/system_bak.def'
  --exclude='/storymode/debug.log'
  --exclude='/storymode/legacy_tests/***'
  --exclude='/storymode/storyboards/General/01_old.sff'
  --exclude='/save/replays/***'
  --exclude='/get-pip.py'
  --exclude='/generated.lua'
  --exclude='/parse_test.lua'
  --exclude='/test_bg.def'
  --exclude='/test_script.lua'
  --exclude='/_tmp_*'
)

if [[ "$DRY_RUN" -eq 1 ]]; then
  RSYNC_ARGS+=(--dry-run --itemize-changes)
fi

info "copying PortMaster launchers"
LAUNCHER_RSYNC_ARGS=(-a)
if [[ "$DRY_RUN" -eq 1 ]]; then
  LAUNCHER_RSYNC_ARGS+=(--dry-run)
fi
rsync "${LAUNCHER_RSYNC_ARGS[@]}" \
  "$REPO_ROOT/Ikemen.sh" \
  "$REPO_ROOT/IkemenDebug.sh" \
  "$REPO_ROOT/IkemenGamepad.sh" \
  "$ZIP_ROOT/"

info "copying game tree into ikemen/"
rsync "${RSYNC_ARGS[@]}" "$REPO_ROOT/" "$GAME_DIR/"

if [[ "$DRY_RUN" -eq 1 ]]; then
  info "dry run complete; no zip was created"
  exit 0
fi

chmod +x \
  "$ZIP_ROOT/Ikemen.sh" \
  "$ZIP_ROOT/IkemenDebug.sh" \
  "$ZIP_ROOT/IkemenGamepad.sh" \
  "$GAME_DIR/ikemen_linux.aarch64" \
  "$GAME_DIR/sdlGamepadMapper"

info "applying ARM64 package overlays"
python3 - "$GAME_DIR" <<'PY'
from pathlib import Path
import json
import sys

root = Path(sys.argv[1])

def rewrite(rel, replacements):
    path = root / rel
    if not path.exists():
        return
    text = path.read_text(errors="ignore")
    original = text
    for old, new in replacements:
        text = text.replace(old, new)
    if text != original:
        path.write_text(text)

for rel in ("data/select.def", "data/remix/select.def"):
    rewrite(rel, [("data/storymode/", "storymode/")])

rewrite(
    "storymode/storyboards/General/chunin_intro.def",
    [("bgm = data/storymode/prologo/01.ogg", "bgm = 01.ogg")],
)

system = root / "data/NxBBC/system.def"
if system.exists():
    text = system.read_text(errors="ignore")
    text = text.replace("font3 = .def", "font3 = NES-Name.def")
    if "font9 =" not in text:
        text = text.replace(
            "font8 = BigBlueTermPlusNerdFont-Regular.def ;Move list / story UI font\n",
            "font8 = BigBlueTermPlusNerdFont-Regular.def ;Move list / story UI font\n"
            "font9 = FORCED SQUARE.def ;Continue / victory name font\n",
        )
    text = text.replace("winstext.font = 255,175,0", "winstext.font = 9,0,0,255,175,0")
    system.write_text(text)

config = root / "save/config.json"
if config.exists():
    data = json.loads(config.read_text())
    data["Fullscreen"] = True
    config.write_text(json.dumps(data, indent=2) + "\n")
PY

info "creating compatibility stage aliases"
mkdir -p \
  "$GAME_DIR/stages/Cloud_Village" \
  "$GAME_DIR/stages/Konoha_Night" \
  "$GAME_DIR/stages/Konoha_Night_(Rain_Ver)"

copy_if_present() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    cp -a "$src" "$dst"
  else
    die "expected stage asset missing: ${src#$GAME_DIR/}"
  fi
}

copy_if_present "$GAME_DIR/stages/Cloud_Village.def" "$GAME_DIR/stages/Cloud_Village/"
copy_if_present "$GAME_DIR/stages/Cloud_Village.sff" "$GAME_DIR/stages/Cloud_Village/"
copy_if_present "$GAME_DIR/stages/Konoha_Night.def" "$GAME_DIR/stages/Konoha_Night/"
copy_if_present "$GAME_DIR/stages/Konoha_Night.sff" "$GAME_DIR/stages/Konoha_Night/"
copy_if_present "$GAME_DIR/stages/Konoha_Night_(Rain_Ver).def" "$GAME_DIR/stages/Konoha_Night_(Rain_Ver)/"
copy_if_present "$GAME_DIR/stages/Konoha_Night_(Rain_Ver).sff" "$GAME_DIR/stages/Konoha_Night_(Rain_Ver)/"
copy_if_present "$GAME_DIR/stages/01-Training_Field_NSUNS4/01-Training_Field_NSUNS4.def" "$GAME_DIR/stages/"
copy_if_present "$GAME_DIR/stages/01-Training_Field_NSUNS4/01-Training_Field_NSUNS4.sff" "$GAME_DIR/stages/"
copy_if_present "$GAME_DIR/Stages/NS_Valley1.1.def" "$GAME_DIR/stages/"
copy_if_present "$GAME_DIR/Stages/NS_Valley.sff" "$GAME_DIR/stages/"

info "validating package staging"
python3 - "$GAME_DIR" <<'PY'
from pathlib import Path
import json
import re
import sys

root = Path(sys.argv[1])

for rel in ("save/config.json", "storymode/catalog.json", "port.json"):
    with (root / rel).open() as f:
        json.load(f)

missing = []
for rel in ("data/NxBBC/select.def", "data/select.def", "data/remix/select.def"):
    path = root / rel
    if not path.exists():
        continue
    for lineno, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
        line = line.split(";", 1)[0]
        for match in re.finditer(r"(stages/[^,\s]+(?: [^,\s]+)*?\.def)", line):
            stage = match.group(1).strip()
            if not (root / stage).exists():
                missing.append(f"{rel}:{lineno}:{stage}")
if missing:
    raise SystemExit("Missing stage references:\n" + "\n".join(missing))
PY

if find "$GAME_DIR" -type f \( \
  -name 'Ikemen_GO' -o \
  -name 'Ikemen_GO_Linux' -o \
  -name 'Ikemen_GO.command' -o \
  -name 'Ikemen_GO_Mac*' -o \
  -name 'Ikemen_GO-v*.zip' -o \
  -name '*:Zone.Identifier' -o \
  -name '01_old.sff' \
\) | grep -q .; then
  die "unexpected desktop/archive/temp file found in package staging"
fi

if command -v file >/dev/null 2>&1; then
  if find "$GAME_DIR" -type f -perm /111 -exec file {} + | grep -E 'x86-64|80386' >/dev/null; then
    find "$GAME_DIR" -type f -perm /111 -exec file {} +
    die "x86 executable detected in ARM64 package staging"
  fi
fi

mkdir -p "$(dirname "$OUTPUT")"
rm -f "$OUTPUT"

info "writing zip: ${OUTPUT#$REPO_ROOT/}"
python3 - "$ZIP_ROOT" "$OUTPUT" <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_STORED
import os
import stat
import sys

root = Path(sys.argv[1])
out = Path(sys.argv[2])

with ZipFile(out, "w", compression=ZIP_STORED, allowZip64=True) as zf:
    for path in sorted(root.rglob("*")):
        rel = path.relative_to(root).as_posix()
        st = path.stat()
        if path.is_dir():
            zi = ZipInfo(rel + "/")
            zi.external_attr = ((st.st_mode & 0o777) << 16) | 0x10
            zf.writestr(zi, b"")
            continue
        zi = ZipInfo(rel)
        zi.compress_type = ZIP_STORED
        zi.external_attr = (st.st_mode & 0o777) << 16
        with path.open("rb") as f:
            zf.writestr(zi, f.read())

print(out)
PY

info "release zip ready: ${OUTPUT#$REPO_ROOT/}"
