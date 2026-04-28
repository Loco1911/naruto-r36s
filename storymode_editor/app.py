import filecmp, io, os, json, re, shutil, struct, subprocess, tempfile, zipfile, traceback
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs, quote, unquote

try:
    from PIL import Image
except Exception:
    Image = None

PROJECT_ROOT = None
EDITOR_DIR = os.path.dirname(os.path.abspath(__file__))
EDITOR_CHARS_META = os.path.join("save", "editor_chars_meta.json")
PROJECT_BUNDLE_DIRS = {
    "chars", "stages", "lifebars", "sound", "data", "font", "music",
    "external", "script", "plugins", "save", "storymode"
}
PROJECT_BUNDLE_FILES = {"select.def"}
DEF_ASSET_EXTS = {'.def', '.sff', '.snd', '.air', '.act', '.mp3', '.ogg', '.wav', '.mid', '.midi'}
LIFEBAR_ASSET_EXTS = DEF_ASSET_EXTS | {'.fnt'}
LIFEBAR_META_FILE = '.ikemen_lifebar.json'
CHAR_IDLE_PREVIEW_CACHE = {}
CHAR_MUGSHOT_PREVIEW_CACHE = {}
CHAR_ALIAS_TEXT_SCAN_EXTS = {'.def', '.air', '.cmd', '.cns', '.st', '.txt', '.md'}
CHAR_ALIAS_TERM_CACHE = {}

def resolve_project_relative_path(root_path, rel_path, base_path=None):
    rel = (rel_path or "").replace('\\', '/').strip()
    if not rel:
        return None
    if os.path.isabs(rel):
        return os.path.normpath(rel)
    candidates = []
    if base_path:
        candidates.append(os.path.normpath(os.path.join(os.path.dirname(base_path), rel)))
    candidates.append(os.path.normpath(os.path.join(root_path, rel)))
    data_candidate = os.path.normpath(os.path.join(root_path, "data", rel))
    if data_candidate not in candidates:
        candidates.append(data_candidate)
    for candidate in candidates:
        resolved = resolve_case_insensitive_path(candidate)
        if resolved:
            return resolved
    return candidates[0]


def resolve_case_insensitive_path(path):
    target = os.path.normpath(path)
    if os.path.exists(target):
        return target

    drive, tail = os.path.splitdrive(os.path.abspath(target))
    if os.path.isabs(target):
        current = drive + os.sep if drive else os.sep
        parts = [part for part in tail.split(os.sep) if part]
    else:
        current = drive or os.curdir
        parts = [part for part in target.split(os.sep) if part]

    for part in parts:
        if not os.path.isdir(current):
            return None
        exact = os.path.join(current, part)
        if os.path.exists(exact):
            current = exact
            continue
        try:
            entries = os.listdir(current)
        except OSError:
            return None
        match = next((name for name in entries if name.casefold() == part.casefold()), None)
        if match is None:
            return None
        current = os.path.join(current, match)

    return current if os.path.exists(current) else None


def get_active_motif_ref(root_path):
    motif_path = "data/system.def"
    config_path = os.path.join(root_path, "save", "config.json")
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                cfg = json.load(f)
                if "Motif" in cfg and cfg["Motif"]:
                    motif_path = cfg["Motif"].replace('\\', '/')
        except:
            pass
    return motif_path


def get_active_motif_path(root_path):
    return resolve_project_relative_path(root_path, get_active_motif_ref(root_path))


def get_select_def_path(root_path):
    motif_path = get_active_motif_ref(root_path)
    motif_full = get_active_motif_path(root_path)
    select_rel = "select.def"
    if os.path.exists(motif_full):
        try:
            with open(motif_full, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line.lower().startswith('select') and '=' in line:
                        select_rel = line.split('=', 1)[1].split(';')[0].strip().replace('\\', '/')
                        break
        except:
            pass
    return resolve_project_relative_path(root_path, select_rel, motif_full)

# ─── Select.def parsing ─────────────────────────────────────────────

def make_char_entry(name):
    return {
        "kind": "char",
        "name": name,
        "char_ref": "",
        "stage": "",
        "hidden": 0,
        "order": 1,
        "music": "",
        "ai": 0,
        "includestage": 1,
        "unlock": "",
        "extra_params": [],
        "slot_locked": False,
    }

def make_label_entry(label):
    return {
        "kind": "label",
        "label": label,
        "slot_locked": False,
    }

def _to_int(value, default):
    try: return int(value)
    except: return default


def normalize_editor_hidden_value(value):
    hidden = _to_int(value, 0)
    if hidden < 0:
        return 0
    if hidden > 3:
        return 3
    return hidden

def get_editor_chars_meta_path(root):
    return os.path.join(root, EDITOR_CHARS_META)

def load_editor_chars_meta(root):
    mp = get_editor_chars_meta_path(root)
    if not os.path.isfile(mp):
        return {"slot_locks": [], "char_refs": []}
    try:
        with open(mp, 'r', encoding='utf-8') as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return {"slot_locks": [], "char_refs": []}
        if not isinstance(data.get("slot_locks"), list):
            data["slot_locks"] = []
        if not isinstance(data.get("char_refs"), list):
            data["char_refs"] = []
        return data
    except:
        return {"slot_locks": [], "char_refs": []}


def get_installed_char_items(available_chars):
    return [
        item for item in (available_chars or [])
        if item.get("type") == "folder" and item.get("has_def")
    ]


def find_char_item_exact(char_name, available_chars):
    query = strip_wrapping_quotes(char_name)
    query_key = char_name_key(query)
    if not query_key:
        return None
    best_score = -1
    best_items = []
    for item in get_installed_char_items(available_chars):
        score = -1
        for candidate, candidate_score in (
            (item.get("name", ""), 130),
            (item.get("def_name", ""), 120),
            (item.get("info_name", ""), 110),
            (item.get("display_name", ""), 100),
        ):
            if candidate and char_name_key(candidate) == query_key:
                score = max(score, candidate_score)
        if score > best_score:
            best_score = score
            best_items = [item]
        elif score == best_score and score >= 0:
            best_items.append(item)
    return best_items[0] if best_score >= 0 and len(best_items) == 1 else None


def extract_parenthetical_terms(value):
    text = strip_wrapping_quotes(value)
    return [normalize_text(term) for term in re.findall(r'\(([^)]+)\)', text) if normalize_text(term)]


def char_folder_mentions_term(root, folder_name, term):
    term_key = char_name_key(term)
    cache_key = (os.path.abspath(root), char_name_key(folder_name), term_key)
    if cache_key in CHAR_ALIAS_TERM_CACHE:
        return CHAR_ALIAS_TERM_CACHE[cache_key]
    char_dir = os.path.join(root, "chars", normalize_text(folder_name))
    found = False
    if os.path.isdir(char_dir) and term_key:
        for dirpath, _, filenames in os.walk(char_dir):
            for filename in filenames:
                if os.path.splitext(filename)[1].lower() not in CHAR_ALIAS_TEXT_SCAN_EXTS:
                    continue
                file_path = os.path.join(dirpath, filename)
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        for line in f:
                            if term_key in line.casefold():
                                found = True
                                break
                except OSError:
                    continue
                if found:
                    break
            if found:
                break
    CHAR_ALIAS_TERM_CACHE[cache_key] = found
    return found


def find_char_item_by_parenthetical_alias(root, char_name, available_chars):
    terms = [char_name_key(term) for term in extract_parenthetical_terms(char_name) if len(char_name_key(term)) >= 3]
    if not terms:
        return None
    best_score = -1
    best_items = []
    for item in get_installed_char_items(available_chars):
        score = 0
        exact_keys = [
            char_name_key(candidate)
            for candidate in (
                normalize_text(item.get("name")),
                normalize_text(item.get("def_name")),
                normalize_text(item.get("info_name")),
                normalize_text(item.get("display_name")),
            )
            if normalize_text(candidate)
        ]
        for term in terms:
            if any(term == candidate_key or term in candidate_key for candidate_key in exact_keys):
                score += 200
            elif char_folder_mentions_term(root, item.get("name", ""), term):
                score += 120
        if score > best_score:
            best_score = score
            best_items = [item]
        elif score == best_score and score > 0:
            best_items.append(item)
    return best_items[0] if best_score > 0 and len(best_items) == 1 else None


def infer_roster_char_ref(root, char_name, available_chars=None):
    query = normalize_text(char_name)
    if not query:
        return ""
    available = available_chars if available_chars is not None else list_available_chars(root)
    exact_item = find_char_item_exact(query, available)
    if exact_item:
        return normalize_text(exact_item.get("name"))
    alias_item = find_char_item_by_parenthetical_alias(root, query, available)
    if alias_item:
        return normalize_text(alias_item.get("name"))
    return ""

def apply_editor_chars_meta(root, roster):
    meta = load_editor_chars_meta(root)
    locks = meta.get("slot_locks", [])
    char_refs = meta.get("char_refs", [])
    available = list_available_chars(root)
    out = []
    for i, entry in enumerate(roster or []):
        item = dict(entry)
        item["slot_locked"] = bool(locks[i]) if i < len(locks) else bool(entry.get("slot_locked", False))
        if item.get("kind") == "char":
            meta_ref = normalize_text(char_refs[i]) if i < len(char_refs) else normalize_text(entry.get("char_ref", ""))
            item["char_ref"] = meta_ref or infer_roster_char_ref(root, item.get("name", ""), available)
        out.append(item)
    return out

def save_editor_chars_meta(root, roster):
    mp = get_editor_chars_meta_path(root)
    os.makedirs(os.path.dirname(mp), exist_ok=True)
    data = {
        "slot_locks": [bool(entry.get("slot_locked", False)) for entry in roster or []],
        "char_refs": [
            normalize_text(entry.get("char_ref", "")) if entry.get("kind") == "char" else ""
            for entry in roster or []
        ],
    }
    with open(mp, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

def normalize_char_roster(roster):
    normalized = []
    for raw in roster or []:
        if not isinstance(raw, dict):
            continue
        if raw.get("kind") == "label":
            label = str(raw.get("label", "")).strip()
            if not label:
                continue
            entry = make_label_entry(label)
        else:
            name = str(raw.get("name", "")).strip()
            if not name:
                continue
            entry = make_char_entry(name)
            entry["char_ref"] = normalize_text(raw.get("char_ref", ""))
            entry["stage"] = str(raw.get("stage", "")).strip()
            entry["hidden"] = normalize_editor_hidden_value(raw.get("hidden"))
            entry["order"] = max(1, _to_int(raw.get("order"), 1))
            entry["music"] = str(raw.get("music", "")).strip()
            entry["ai"] = _to_int(raw.get("ai"), 0)
            entry["includestage"] = _to_int(raw.get("includestage"), 1)
            entry["unlock"] = str(raw.get("unlock", "")).strip()
            extra_params = raw.get("extra_params", [])
            if isinstance(extra_params, list):
                entry["extra_params"] = [str(p).strip() for p in extra_params if str(p).strip()]
        entry["slot_locked"] = bool(raw.get("slot_locked", False))
        normalized.append(entry)
    return normalized

def parse_select_def_full(root):
    sp = get_select_def_path(root)
    chars, stages_section, options_section = [], [], []
    try:
        with open(sp, 'r', encoding='utf-8') as f:
            raw = f.read()
    except:
        return {"chars": [], "stages": [], "options": []}
    mode = "header"
    for line in raw.split('\n'):
        stripped = line.strip()
        if stripped.startswith('[Characters]'): mode = "chars"; continue
        elif stripped.startswith('[ExtraStages]'): mode = "stages"; continue
        elif stripped.startswith('[Options]'): mode = "options"; continue
        elif stripped.startswith('[') and ']' in stripped: mode = "other"; options_section.append(line); continue
        if mode == "chars":
            if not stripped: continue
            if stripped.startswith(';'):
                comment = stripped[1:].strip()
                if comment and not re.fullmatch(r'-+', comment):
                    chars.append(make_label_entry(comment))
                continue
            entry = parse_char_line(stripped)
            if entry: chars.append(entry)
        elif mode == "stages":
            if stripped and not stripped.startswith(';'): stages_section.append(stripped)
        elif mode in ("options", "other"):
            options_section.append(line)
    return {"chars": chars, "stages": stages_section, "options": options_section}

def parse_char_line(line):
    ci = line.find(';')
    if ci >= 0: line = line[:ci]
    line = line.strip()
    if not line: return None
    parts = [p.strip() for p in line.split(',')]
    name = parts[0]
    if not name: return None
    entry = make_char_entry(name)
    params_start = 2 if len(parts) > 1 and parts[1] and '=' not in parts[1] else 1
    if params_start == 2: entry["stage"] = parts[1]
    for i in range(params_start, len(parts)):
        p = parts[i].strip()
        if '=' in p:
            key, val = p.split('=', 1)
            key, val = key.strip().lower(), val.strip()
            if key == "hidden": entry["hidden"] = normalize_editor_hidden_value(val)
            elif key == "order": entry["order"] = int(val) if val.isdigit() else 1
            elif key == "music": entry["music"] = val
            elif key == "ai": entry["ai"] = int(val) if val.isdigit() else 0
            elif key == "includestage": entry["includestage"] = int(val) if val.isdigit() else 1
            elif key == "unlock": entry["unlock"] = val
            else: entry["extra_params"].append(p)
        else: entry["extra_params"].append(p)
    return entry

def char_entry_to_line(entry):
    if entry.get("kind") == "label":
        return "; " + str(entry.get("label", "")).strip()
    parts = [entry["name"]]
    if entry.get("stage"): parts.append(entry["stage"])
    if entry.get("order", 1) != 1: parts.append(f"order={entry['order']}")
    if entry.get("hidden", 0) != 0: parts.append(f"hidden={entry['hidden']}")
    if entry.get("music"): parts.append(f"music={entry['music']}")
    if entry.get("ai", 0) != 0: parts.append(f"ai={entry['ai']}")
    if entry.get("includestage", 1) != 1: parts.append(f"includestage={entry['includestage']}")
    if entry.get("unlock"): parts.append(f"unlock={entry['unlock']}")
    for ep in entry.get("extra_params", []): parts.append(ep)
    return ", ".join(parts)

def write_select_def(root, chars, stages, options):
    chars = normalize_char_roster(chars)
    sp = get_select_def_path(root)
    lines = [";---------------------------------------------------------------------", "[Characters]", ""]
    for entry in chars: lines.append(char_entry_to_line(entry))
    lines += ["", ";-----------------------", "[ExtraStages]", ""]
    for s in stages: lines.append(s)
    lines += ["", ";---------------------------------------------------------------------", "[Options]"]
    for o in options: lines.append(o)
    content = "\n".join(lines)
    if "arcade.maxmatches" not in content: lines.append("arcade.maxmatches = 10,1,1,0,0,0,0,0,0,0")
    if "team.maxmatches" not in content: lines.append("team.maxmatches = 10,1,1,0,0,0,0,0,0,0")
    lines.append("")
    with open(sp, 'w', encoding='utf-8') as f: f.write("\n".join(lines))


def normalize_text(value):
    return str(value or "").strip()


def strip_wrapping_quotes(value):
    text = normalize_text(value)
    if len(text) >= 2 and text[0] == text[-1] and text[0] in {'"', "'"}:
        return text[1:-1].strip()
    return text


def strip_parenthetical_suffix(value):
    text = strip_wrapping_quotes(value)
    return re.sub(r'\s*\([^)]*\)\s*$', '', text).strip()


def char_name_key(value):
    return normalize_text(value).casefold()


def normalize_rel_path(value):
    return normalize_text(value).replace('\\', '/')


def stage_ref_key(value):
    ref = normalize_rel_path(value)
    if ref.lower().startswith('stages/'):
        ref = ref[7:]
    return ref.casefold()


def path_is_within(base_path, target_path):
    try:
        return os.path.commonpath([os.path.abspath(base_path), os.path.abspath(target_path)]) == os.path.abspath(base_path)
    except ValueError:
        return False


def get_lifebars_root(root):
    return os.path.join(root, "lifebars")


def ensure_lifebars_root(root):
    path = get_lifebars_root(root)
    os.makedirs(path, exist_ok=True)
    return path


def relative_to_root(root, abs_path):
    return os.path.relpath(os.path.abspath(abs_path), root).replace('\\', '/')


def slugify_lifebar_name(name, fallback="lifebar"):
    return sanitize_package_name(name or "", fallback)


def same_file_contents(path_a, path_b):
    try:
        return filecmp.cmp(path_a, path_b, shallow=False)
    except:
        return False


def read_motif_files_value(motif_path, key):
    section = None
    try:
        with open(motif_path, 'r', encoding='utf-8', errors='replace') as f:
            for raw_line in f:
                stripped = raw_line.strip()
                if stripped.startswith('[') and stripped.endswith(']'):
                    section = stripped[1:-1].strip().lower()
                    continue
                if section != 'files':
                    continue
                line = raw_line.split(';', 1)[0].strip()
                if not line or '=' not in line:
                    continue
                raw_key, raw_value = line.split('=', 1)
                if raw_key.strip().lower() == key.lower():
                    return raw_value.strip()
    except:
        pass
    return ""


def write_motif_files_value(motif_path, key, value):
    key_l = key.lower()
    with open(motif_path, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    section = None
    files_start = -1
    insert_at = -1
    updated = False
    for idx, raw_line in enumerate(lines):
        stripped = raw_line.strip()
        if stripped.startswith('[') and stripped.endswith(']'):
            if section == 'files' and insert_at == -1:
                insert_at = idx
            section = stripped[1:-1].strip().lower()
            if section == 'files':
                files_start = idx
            continue
        if section != 'files':
            continue
        line = raw_line.split(';', 1)[0].strip()
        if not line or '=' not in line:
            continue
        raw_key, _ = line.split('=', 1)
        if raw_key.strip().lower() == key_l:
            suffix = ''
            if ';' in raw_line:
                suffix = ';' + raw_line.split(';', 1)[1].rstrip('\n')
            lines[idx] = f"{raw_key.split('=')[0].strip()} = {value}{(' ' + suffix) if suffix else ''}\n"
            updated = True
            break

    if not updated:
        if files_start == -1:
            lines.extend(["\n", "[Files]\n", f"{key} = {value}\n"])
        else:
            if insert_at == -1:
                insert_at = len(lines)
            lines.insert(insert_at, f"{key} = {value}\n")

    with open(motif_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)


def get_story_catalog_path(root):
    return os.path.join(root, "storymode", "catalog.json")


def load_story_catalog(root):
    catalog_path = get_story_catalog_path(root)
    if not os.path.isfile(catalog_path):
        return []
    try:
        with open(catalog_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data if isinstance(data, list) else []
    except:
        return []


def save_story_catalog(root, catalog):
    catalog_path = get_story_catalog_path(root)
    os.makedirs(os.path.dirname(catalog_path), exist_ok=True)
    with open(catalog_path, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)


def collect_valid_char_names(values):
    seen = set()
    names = []
    for raw in values or []:
        name = normalize_text(raw)
        key = char_name_key(name)
        if not name or key in seen or key in {"null", "randomselect"}:
            continue
        seen.add(key)
        names.append(name)
    return names


def collect_valid_stage_names(values):
    seen = set()
    names = []
    for raw in values or []:
        name = normalize_rel_path(raw)
        key = stage_ref_key(name)
        if not name or key in seen:
            continue
        seen.add(key)
        names.append(name)
    return names


def resolve_char_delete_plan(root, char_names):
    available = list_available_chars(root)
    match_keys = set()
    disk_names = []
    seen_disk = set()

    for raw_name in char_names or []:
        query = normalize_text(raw_name)
        if not query:
            continue

        candidates = [query]
        disk_name = ""

        item = find_char_item_exact(query, available)
        if item is None:
            inferred = infer_roster_char_ref(root, query, available)
            if inferred:
                item = find_char_item_exact(inferred, available)
        if item is None:
            item = find_char_item_by_parenthetical_alias(root, query, available)

        if item:
            disk_name = normalize_text(item.get("name"))
            candidates.extend([
                disk_name,
                normalize_text(item.get("def_name")),
                normalize_text(item.get("info_name")),
                normalize_text(item.get("display_name")),
            ])

        for candidate in candidates:
            candidate_key = char_name_key(candidate)
            if candidate_key:
                match_keys.add(candidate_key)

        safe_disk_name = sanitize_char_folder_name(disk_name or query)
        if safe_disk_name:
            disk_key = char_name_key(safe_disk_name)
            if disk_key not in seen_disk:
                seen_disk.add(disk_key)
                disk_names.append(safe_disk_name)

    return {"match_keys": match_keys, "disk_names": disk_names}


def resolve_char_rename_target(root, char_name):
    query = normalize_text(char_name)
    available = list_available_chars(root)
    item = find_char_item_exact(query, available)
    if item is None:
        inferred = infer_roster_char_ref(root, query, available)
        if inferred:
            item = find_char_item_exact(inferred, available)
    if item is None:
        item = find_char_item_by_parenthetical_alias(root, query, available)

    folder_name = normalize_text(item.get("name")) if item else sanitize_char_folder_name(query) or query
    match_keys = set()
    for candidate in (
        query,
        folder_name,
        normalize_text(item.get("def_name")) if item else "",
        normalize_text(item.get("info_name")) if item else "",
        normalize_text(item.get("display_name")) if item else "",
    ):
        candidate_key = char_name_key(candidate)
        if candidate_key:
            match_keys.add(candidate_key)

    return {
        "folder_name": folder_name,
        "match_keys": match_keys,
        "item": item,
    }


def remove_chars_from_select(root, char_names):
    plan = resolve_char_delete_plan(root, char_names)
    char_keys = plan["match_keys"]
    parsed = parse_select_def_full(root)
    roster = apply_editor_chars_meta(root, parsed["chars"])
    
    filtered = []
    removed = 0
    for entry in roster:
        if entry.get("kind") == "char" and (
            char_name_key(entry.get("name")) in char_keys
            or char_name_key(entry.get("char_ref")) in char_keys
        ):
            filtered.append({
                "name": "randomselect",
                "char_ref": "randomselect",
                "kind": "char",
                "slot_locked": False,
                "hidden": 0
            })
            removed += 1
        else:
            filtered.append(entry)

    write_select_def(root, filtered, parsed["stages"], parsed["options"])
    save_editor_chars_meta(root, filtered)
    return {"roster_removed": removed}


def remove_chars_from_story_catalog(root, char_names):
    plan = resolve_char_delete_plan(root, char_names)
    char_keys = plan["match_keys"]
    catalog = load_story_catalog(root)
    stats = {"chapters_changed": 0, "p1_removed": 0, "p2_removed": 0, "p2ai_trimmed": 0}
    changed = False

    for saga in catalog:
        chapters = saga.get("chapters", [])
        if not isinstance(chapters, list):
            continue
        for chapter in chapters:
            if not isinstance(chapter, dict):
                continue
            chapter_changed = False

            p1 = chapter.get("p1")
            if isinstance(p1, list):
                new_p1 = [name for name in p1 if char_name_key(name) not in char_keys]
                removed = len(p1) - len(new_p1)
                if removed:
                    chapter["p1"] = new_p1
                    stats["p1_removed"] += removed
                    chapter_changed = True

            p2 = chapter.get("p2")
            p2ai = chapter.get("p2ai")
            if isinstance(p2, list):
                kept_p2 = []
                kept_ai = [] if isinstance(p2ai, list) else None
                removed = 0
                for idx, fighter in enumerate(p2):
                    if char_name_key(fighter) in char_keys:
                        removed += 1
                        continue
                    kept_p2.append(fighter)
                    if kept_ai is not None and idx < len(p2ai):
                        kept_ai.append(p2ai[idx])
                if removed:
                    chapter["p2"] = kept_p2
                    stats["p2_removed"] += removed
                    if kept_ai is not None:
                        stats["p2ai_trimmed"] += max(0, len(p2ai) - len(kept_ai))
                        chapter["p2ai"] = kept_ai
                    chapter_changed = True

            if chapter_changed:
                stats["chapters_changed"] += 1
                changed = True

    if changed:
        save_story_catalog(root, catalog)
    return stats


def sanitize_char_folder_name(char_name):
    name = normalize_rel_path(char_name).strip('/')
    if not name or '/' in name or name in ('.', '..'):
        return None
    return name


def delete_char_files(root, char_names):
    stats = {"char_dirs_removed": 0, "move_dirs_removed": 0}
    plan = resolve_char_delete_plan(root, char_names)
    for safe_name in plan["disk_names"]:
        char_dir = os.path.join(root, "chars", safe_name)
        if os.path.isdir(char_dir):
            shutil.rmtree(char_dir)
            stats["char_dirs_removed"] += 1
        moves_dir = os.path.join(root, "moves", safe_name)
        if os.path.isdir(moves_dir):
            shutil.rmtree(moves_dir)
            stats["move_dirs_removed"] += 1
    return stats


def rename_char_in_story_catalog(root, old_keys, new_name):
    catalog = load_story_catalog(root)
    stats = {"chapters_changed": 0, "p1_renamed": 0, "p2_renamed": 0}
    changed = False
    new_value = normalize_text(new_name)
    if not new_value:
        return stats

    for saga in catalog:
        chapters = saga.get("chapters", [])
        if not isinstance(chapters, list):
            continue
        for chapter in chapters:
            if not isinstance(chapter, dict):
                continue
            chapter_changed = False

            p1 = chapter.get("p1")
            if isinstance(p1, list):
                new_p1 = []
                renamed = 0
                for fighter in p1:
                    if char_name_key(fighter) in old_keys:
                        new_p1.append(new_value)
                        renamed += 1
                    else:
                        new_p1.append(fighter)
                if renamed:
                    chapter["p1"] = new_p1
                    stats["p1_renamed"] += renamed
                    chapter_changed = True

            p2 = chapter.get("p2")
            if isinstance(p2, list):
                new_p2 = []
                renamed = 0
                for fighter in p2:
                    if char_name_key(fighter) in old_keys:
                        new_p2.append(new_value)
                        renamed += 1
                    else:
                        new_p2.append(fighter)
                if renamed:
                    chapter["p2"] = new_p2
                    stats["p2_renamed"] += renamed
                    chapter_changed = True

            if chapter_changed:
                stats["chapters_changed"] += 1
                changed = True

    if changed:
        save_story_catalog(root, catalog)
    return stats


def repair_roster_char_names_from_refs(root):
    parsed = parse_select_def_full(root)
    roster = apply_editor_chars_meta(root, parsed["chars"])
    repaired = []
    changed = 0

    for entry in roster:
        item = dict(entry)
        if item.get("kind") != "char":
            repaired.append(item)
            continue
        name = normalize_text(item.get("name"))
        ref = normalize_text(item.get("char_ref"))
        if (
            name
            and ref
            and name not in {"null", "randomselect"}
            and name != ref
            and not find_primary_char_def(root, name)
            and find_primary_char_def(root, ref)
        ):
            item["name"] = ref
            changed += 1
        repaired.append(item)

    if changed:
        write_select_def(root, repaired, parsed["stages"], parsed["options"])
        save_editor_chars_meta(root, repaired)
    return changed


def resolve_stage_ref_path(root, stage_ref):
    ref = normalize_rel_path(stage_ref)
    if not ref:
        return None
    stages_root = os.path.abspath(os.path.join(root, "stages"))
    candidates = [os.path.abspath(os.path.join(root, ref))]
    if not ref.lower().startswith('stages/'):
        candidates.append(os.path.abspath(os.path.join(stages_root, ref)))
    seen = set()
    for candidate in candidates:
        norm = os.path.normcase(candidate)
        if norm in seen:
            continue
        seen.add(norm)
        if path_is_within(stages_root, candidate):
            return candidate
    return None


def iter_stage_def_paths(root):
    stages_root = os.path.join(root, "stages")
    if not os.path.isdir(stages_root):
        return
    for dirpath, _, filenames in os.walk(stages_root):
        for filename in filenames:
            if filename.lower().endswith('.def'):
                yield os.path.join(dirpath, filename)


def iter_project_def_paths(root):
    for top_dir in ("chars", "stages", "storymode", "data"):
        abs_dir = os.path.join(root, top_dir)
        if not os.path.isdir(abs_dir):
            continue
        for dirpath, _, filenames in os.walk(abs_dir):
            for filename in filenames:
                if filename.lower().endswith('.def'):
                    yield os.path.join(dirpath, filename)


def build_stage_reference_maps(root):
    def_to_assets = {}
    asset_to_defs = {}
    asset_paths = {}
    for def_path in iter_project_def_paths(root) or []:
        package_root = os.path.dirname(def_path)
        def_key = os.path.normcase(os.path.abspath(def_path))
        assets = set()
        for ref in iter_def_asset_refs(def_path):
            resolved = resolve_package_asset_destination(root, package_root, "stages", ref)
            if not resolved:
                continue
            resolved_abs = os.path.abspath(resolved)
            if not path_is_within(root, resolved_abs):
                continue
            asset_key = os.path.normcase(resolved_abs)
            assets.add(asset_key)
            asset_paths.setdefault(asset_key, resolved_abs)
            asset_to_defs.setdefault(asset_key, set()).add(def_key)
        def_to_assets[def_key] = assets
    return def_to_assets, asset_to_defs, asset_paths


def remove_stages_from_select(root, stage_names):
    stage_keys = {stage_ref_key(name) for name in stage_names}
    parsed = parse_select_def_full(root)
    roster = apply_editor_chars_meta(root, parsed["chars"])
    filtered_stages = [stage for stage in parsed["stages"] if stage_ref_key(stage) not in stage_keys]
    removed_stages = len(parsed["stages"]) - len(filtered_stages)
    cleared_char_stage = 0
    for entry in roster:
        if entry.get("kind") != "char":
            continue
        stage_ref = entry.get("stage", "")
        if stage_ref and stage_ref_key(stage_ref) in stage_keys:
            entry["stage"] = ""
            cleared_char_stage += 1
    write_select_def(root, roster, filtered_stages, parsed["options"])
    save_editor_chars_meta(root, roster)
    return {"stages_removed": removed_stages, "char_stage_refs_cleared": cleared_char_stage}


def remove_stages_from_story_catalog(root, stage_names):
    stage_keys = {stage_ref_key(name) for name in stage_names}
    catalog = load_story_catalog(root)
    stats = {"chapters_changed": 0}
    changed = False
    for saga in catalog:
        chapters = saga.get("chapters", [])
        if not isinstance(chapters, list):
            continue
        for chapter in chapters:
            if not isinstance(chapter, dict):
                continue
            if stage_ref_key(chapter.get("stage", "")) in stage_keys:
                chapter["stage"] = "random"
                stats["chapters_changed"] += 1
                changed = True
    if changed:
        save_story_catalog(root, catalog)
    return stats


def delete_stage_files(root, stage_names):
    stages_root = os.path.abspath(os.path.join(root, "stages"))
    targets = []
    for stage_name in stage_names:
        abs_path = resolve_stage_ref_path(root, stage_name)
        if not abs_path or not abs_path.lower().endswith('.def'):
            continue
        targets.append(os.path.abspath(abs_path))
    if not targets:
        return {"defs_removed": 0, "asset_files_removed": 0, "dirs_removed": 0}

    target_keys = {os.path.normcase(path) for path in targets}
    all_def_paths = [os.path.abspath(path) for path in (iter_stage_def_paths(root) or [])]
    def_to_assets, asset_to_defs, asset_paths = build_stage_reference_maps(root)

    files_to_delete = {}
    dirs_to_delete = set()
    for def_path in targets:
        def_key = os.path.normcase(def_path)
        files_to_delete[def_key] = def_path
        def_dir = os.path.dirname(def_path)
        sibling_defs = [path for path in all_def_paths if os.path.dirname(path) == def_dir]
        remaining_defs = [path for path in sibling_defs if os.path.normcase(path) not in target_keys]
        if def_dir != stages_root and not remaining_defs:
            dirs_to_delete.add(def_dir)

        for asset_key in def_to_assets.get(def_key, set()):
            if asset_key == def_key:
                continue
            owners = asset_to_defs.get(asset_key, set())
            if owners - target_keys:
                continue
            real_path = asset_paths.get(asset_key)
            if real_path and os.path.isfile(real_path):
                files_to_delete[asset_key] = real_path

    stats = {"defs_removed": 0, "asset_files_removed": 0, "dirs_removed": 0}
    for dir_path in sorted(dirs_to_delete, key=lambda value: len(value), reverse=True):
        if os.path.isdir(dir_path):
            shutil.rmtree(dir_path)
            stats["dirs_removed"] += 1

    for key, file_path in files_to_delete.items():
        if any(path_is_within(dir_path, file_path) for dir_path in dirs_to_delete):
            continue
        if os.path.isfile(file_path):
            os.remove(file_path)
            if file_path.lower().endswith('.def'):
                stats["defs_removed"] += 1
            else:
                stats["asset_files_removed"] += 1

    return stats


def clean_missing_stage_references(root):
    parsed = parse_select_def_full(root)
    roster = apply_editor_chars_meta(root, parsed["chars"])
    valid_stages = []
    removed_stage_refs = []
    for stage_ref in parsed["stages"]:
        if resolve_stage_ref_path(root, stage_ref):
            valid_stages.append(stage_ref)
        else:
            removed_stage_refs.append(stage_ref)

    cleared_char_stage = 0
    for entry in roster:
        if entry.get("kind") != "char":
            continue
        stage_ref = normalize_rel_path(entry.get("stage", ""))
        if stage_ref and not resolve_stage_ref_path(root, stage_ref):
            entry["stage"] = ""
            cleared_char_stage += 1

    if removed_stage_refs or cleared_char_stage:
        write_select_def(root, roster, valid_stages, parsed["options"])
        save_editor_chars_meta(root, roster)

    catalog = load_story_catalog(root)
    chapters_changed = 0
    catalog_changed = False
    for saga in catalog:
        chapters = saga.get("chapters", [])
        if not isinstance(chapters, list):
            continue
        for chapter in chapters:
            if not isinstance(chapter, dict):
                continue
            stage_ref = normalize_rel_path(chapter.get("stage", ""))
            if not stage_ref or stage_ref == "random":
                continue
            if resolve_stage_ref_path(root, stage_ref):
                continue
            chapter["stage"] = "random"
            chapters_changed += 1
            catalog_changed = True
    if catalog_changed:
        save_story_catalog(root, catalog)

    return {
        "removed_stage_refs": len(removed_stage_refs),
        "removed_stages": removed_stage_refs,
        "cleared_char_stage_refs": cleared_char_stage,
        "chapters_changed": chapters_changed,
    }


def list_available_chars(root):
    chars_dir = os.path.join(root, "chars")
    available = []
    if not os.path.isdir(chars_dir): return available
    for entry in os.scandir(chars_dir):
        if entry.is_dir():
            def_path = find_primary_char_def(root, entry.name)
            item = {"name": entry.name, "type": "folder", "has_def": bool(def_path)}
            if def_path:
                sections = parse_def_sections(def_path)
                info = sections.get('info', {})
                item["def_name"] = os.path.splitext(os.path.basename(def_path))[0]
                item["info_name"] = strip_wrapping_quotes(info.get('name', ''))
                item["display_name"] = strip_wrapping_quotes(info.get('displayname', '')) or item["info_name"]
            available.append(item)
        elif entry.name.endswith('.zip'):
            available.append({"name": entry.name, "type": "zip", "has_def": True})
    available.sort(key=lambda x: x["name"].lower())
    return available


def list_installed_char_names(root):
    installed = []
    seen = set()
    for item in list_available_chars(root):
        if item.get("type") != "folder" or not item.get("has_def"):
            continue
        name = normalize_text(item.get("name", ""))
        key = char_name_key(name)
        if not name or key in seen:
            continue
        seen.add(key)
        installed.append(name)
    return installed


def find_primary_char_def(root, char_name):
    char_dir = os.path.join(root, "chars", normalize_text(char_name))
    if not os.path.isdir(char_dir):
        return None
    def_paths = []
    
    ignore_names = {'intro', 'ending', 'story', 'ed', 'op', 'credits', 'logo'}
    
    for entry in os.scandir(char_dir):
        if entry.is_file() and entry.name.lower().endswith('.def'):
            base = os.path.splitext(entry.name)[0].lower()
            if base not in ignore_names:
                def_paths.append(entry.path)
                
    if not def_paths:
        for entry in os.scandir(char_dir):
            if entry.is_file() and entry.name.lower().endswith('.def'):
                def_paths.append(entry.path)
                
    if not def_paths:
        return None
        
    def_paths.sort(key=lambda path: os.path.basename(path).lower())
    
    char_key = char_name_key(char_name)
    preferred = os.path.join(char_dir, f"{normalize_text(char_name)}.def")
    if os.path.isfile(preferred) and preferred in def_paths:
        return preferred
        
    for path in def_paths:
        if char_name_key(os.path.splitext(os.path.basename(path))[0]) == char_key:
            return path
            
    for path in def_paths:
        def_key = char_name_key(os.path.splitext(os.path.basename(path))[0])
        if def_key and (def_key in char_key or char_key in def_key):
            return path
            
    return def_paths[0]


def find_char_def_by_alias(root, char_name):
    query = strip_wrapping_quotes(char_name)
    query_key = char_name_key(query)
    query_base_key = char_name_key(strip_parenthetical_suffix(query))
    query_has_parenthetical = bool(extract_parenthetical_terms(query))
    best_score = -1
    best_path = None
    for item in list_available_chars(root):
        if item.get("type") != "folder" or not item.get("has_def"):
            continue
        folder_name = normalize_text(item.get("name"))
        def_path = find_primary_char_def(root, folder_name)
        if not def_path:
            continue
        sections = parse_def_sections(def_path)
        info = sections.get('info', {})
        candidates = {
            folder_name,
            os.path.splitext(os.path.basename(def_path))[0],
            strip_wrapping_quotes(info.get('name', '')),
            strip_wrapping_quotes(info.get('displayname', '')),
        }
        score = -1
        for candidate in candidates:
            candidate = normalize_text(candidate)
            if not candidate:
                continue
            candidate_key = char_name_key(candidate)
            candidate_base_key = char_name_key(strip_parenthetical_suffix(candidate))
            if candidate_key == query_key:
                score = max(score, 100)
            elif not query_has_parenthetical and candidate_base_key and candidate_base_key == query_base_key:
                score = max(score, 90)
            elif not query_has_parenthetical and query_base_key and (candidate_base_key.startswith(query_base_key) or query_base_key.startswith(candidate_base_key)):
                score = max(score, 70)
        if score > best_score:
            best_score = score
            best_path = def_path
    return best_path if best_score >= 70 else None


def parse_def_sections(def_path):
    sections = {}
    current = ""
    try:
        with open(def_path, 'r', encoding='utf-8', errors='replace') as f:
            for raw_line in f:
                line = raw_line.split(';', 1)[0].strip()
                if not line:
                    continue
                if line.startswith('[') and line.endswith(']'):
                    current = line[1:-1].strip().casefold()
                    sections.setdefault(current, {})
                    continue
                if '=' not in line:
                    continue
                key, value = line.split('=', 1)
                sections.setdefault(current, {})[key.strip().casefold()] = value.strip()
    except OSError:
        return {}
    return sections


def project_path_to_url(root, abs_path):
    if not abs_path:
        return ""
    target = os.path.abspath(abs_path)
    if not path_is_within(root, target):
        return ""
    rel = os.path.relpath(target, root).replace('\\', '/')
    return '/' + rel


def resolve_char_preview_paths(root, char_name, preferred_ref=""):
    char_name = normalize_text(char_name)
    preferred_ref = normalize_text(preferred_ref)
    if not char_name:
        raise ValueError("Falta el nombre del personaje")
    resolved_ref = preferred_ref or infer_roster_char_ref(root, char_name)
    def_path = find_primary_char_def(root, resolved_ref) if resolved_ref else None
    if not def_path:
        def_path = find_primary_char_def(root, char_name)
    if not def_path:
        def_path = find_char_def_by_alias(root, char_name)
    if not def_path:
        raise ValueError(f"No se encontró un .def para chars/{char_name}")

    sections = parse_def_sections(def_path)
    info_section = sections.get('info', {})
    files_section = sections.get('files', {})

    display_name = strip_wrapping_quotes(info_section.get('displayname') or info_section.get('name') or char_name)
    air_ref = normalize_rel_path(files_section.get('anim') or files_section.get('air') or '')
    sff_ref = normalize_rel_path(files_section.get('sprite') or files_section.get('spr') or '')
    pal1_ref = normalize_rel_path(files_section.get('pal1') or '')

    if not air_ref:
        fallback = os.path.splitext(os.path.basename(def_path))[0] + '.air'
        air_ref = fallback
    if not sff_ref:
        fallback = os.path.splitext(os.path.basename(def_path))[0] + '.sff'
        sff_ref = fallback

    air_path = resolve_project_relative_path(root, air_ref, def_path)
    sff_path = resolve_project_relative_path(root, sff_ref, def_path)
    pal1_path = resolve_project_relative_path(root, pal1_ref, def_path) if pal1_ref else None

    if not air_path or not os.path.isfile(air_path):
        raise ValueError(f"No se encontró el AIR del personaje: {air_ref or '(vacío)'}")
    if not sff_path or not os.path.isfile(sff_path):
        raise ValueError(f"No se encontró el SFF del personaje: {sff_ref or '(vacío)'}")

    return {
        "name": char_name,
        "char_ref": resolved_ref or os.path.basename(os.path.dirname(def_path)),
        "display_name": display_name,
        "def_abs_path": os.path.abspath(def_path),
        "air_abs_path": os.path.abspath(air_path),
        "sff_abs_path": os.path.abspath(sff_path),
        "pal1_abs_path": os.path.abspath(pal1_path) if pal1_path and os.path.isfile(pal1_path) else None,
    }


def resolve_char_preview_source(root, char_name, preferred_ref=""):
    preview = resolve_char_preview_paths(root, char_name, preferred_ref)
    return {
        "name": preview["name"],
        "char_ref": preview.get("char_ref", ""),
        "display_name": preview["display_name"],
        "def_path": project_path_to_url(root, preview["def_abs_path"]),
        "air_path": project_path_to_url(root, preview["air_abs_path"]),
        "sff_path": project_path_to_url(root, preview["sff_abs_path"]),
    }


def read_act_palette_bytes(act_path):
    if not act_path or not os.path.isfile(act_path):
        return None
    try:
        with open(act_path, 'rb') as f:
            data = f.read()
    except OSError:
        return None
    count = min(256, len(data) // 3)
    if count <= 0:
        return None
    palette = bytearray(256 * 3)
    for i in range(count):
        src = i * 3
        dst = (255 - i) * 3
        palette[dst:dst + 3] = data[src:src + 3]
    return bytes(palette)


def analyze_single_preview_image(image):
    colors = image.getcolors(maxcolors=1000000) or []
    opaque = 0
    non_black = 0
    for count, (r, g, b, a) in colors:
        if a == 0:
            continue
        opaque += count
        if (r, g, b) != (0, 0, 0):
            non_black += count
    return {
        'opaque': opaque,
        'non_black_ratio': non_black / max(1, opaque),
        'top_left': image.getpixel((0, 0)) if image.width > 0 and image.height > 0 else (0, 0, 0, 0),
    }


def resolve_char_state_paths(preview):
    sections = parse_def_sections(preview['def_abs_path'])
    files_section = sections.get('files', {})
    paths = []
    seen = set()
    for key, value in files_section.items():
        key_l = normalize_text(key).casefold()
        if key_l != 'cns' and not key_l.startswith('st'):
            continue
        rel = normalize_rel_path(value)
        if not rel:
            continue
        abs_path = resolve_project_relative_path(os.path.dirname(os.path.dirname(os.path.dirname(preview['def_abs_path']))), rel, preview['def_abs_path'])
        if not abs_path or not os.path.isfile(abs_path):
            continue
        norm = os.path.abspath(abs_path)
        if norm in seen:
            continue
        seen.add(norm)
        paths.append(norm)
    return paths


def extract_state0_action_candidates(preview):
    candidates = []
    seen = set()
    for state_path in resolve_char_state_paths(preview):
        in_state0 = False
        controller_type = ''
        try:
            with open(state_path, 'r', encoding='utf-8', errors='replace') as f:
                for raw_line in f:
                    line = raw_line.split(';', 1)[0].strip()
                    if not line:
                        continue
                    match = re.match(r'^\[Statedef\s+(-?\d+)\]$', line, re.I)
                    if match:
                        state_no = int(match.group(1))
                        if in_state0 and state_no != 0:
                            break
                        in_state0 = state_no == 0
                        controller_type = ''
                        continue
                    if line.startswith('[') and line.endswith(']'):
                        controller_type = ''
                        continue
                    if not in_state0:
                        continue
                    if '=' not in line:
                        continue
                    key, value = [part.strip() for part in line.split('=', 1)]
                    key_l = key.casefold()
                    if key_l == 'type':
                        controller_type = normalize_text(value).casefold()
                        continue
                    expr = None
                    if key_l == 'anim':
                        expr = value
                    elif key_l == 'value' and controller_type == 'changeanim':
                        expr = value
                    if not expr:
                        continue
                    numbers = re.findall(r'(?<![\w.])-?\d+', expr)
                    if not numbers:
                        continue
                    try:
                        base_action = int(numbers[0])
                    except Exception:
                        continue
                    if base_action < 0:
                        continue
                    mode_expanded = 'var(' in expr.casefold()
                    candidate_key = (base_action, mode_expanded)
                    if candidate_key in seen:
                        continue
                    seen.add(candidate_key)
                    candidates.append({
                        'base_action': base_action,
                        'mode_expanded': mode_expanded,
                    })
        except OSError:
            continue
    return candidates


def parse_air_action(air_path, action_no=0):
    frames = []
    loop_start = 0
    active = False
    with open(air_path, 'r', encoding='utf-8', errors='replace') as f:
        for raw_line in f:
            line = raw_line.split(';', 1)[0].strip()
            if not line:
                continue
            match = re.match(r'^\[Begin Action\s+(-?\d+)\]$', line, re.I)
            if match:
                active = int(match.group(1)) == int(action_no)
                continue
            if not active:
                continue
            if line.startswith('['):
                break
            if re.match(r'^loopstart$', line, re.I):
                loop_start = len(frames)
                continue
            if re.match(r'^clsn', line, re.I):
                continue
            parts = [part.strip() for part in line.split(',')]
            if len(parts) < 5:
                continue
            try:
                group = int(parts[0])
                item = int(parts[1])
                offset_x = int(parts[2])
                offset_y = int(parts[3])
                ticks = int(parts[4])
            except Exception:
                continue
            flip = parts[5].upper() if len(parts) > 5 else ''
            frames.append({
                'group': group,
                'item': item,
                'offset_x': offset_x,
                'offset_y': offset_y,
                'ticks': ticks if ticks > 0 else 1,
                'flip_h': 'H' in flip,
                'flip_v': 'V' in flip,
            })
    if not frames:
        raise ValueError("No se encontró el Begin Action 0 en el AIR")
    return {"frames": frames, "loop_start": min(loop_start, max(0, len(frames) - 1))}


def extract_png_bytes(blob, offset):
    signature = b'\x89PNG\r\n\x1a\n'

    def try_extract(start):
        if start < 0 or start + len(signature) > len(blob):
            return None
        if blob[start:start + len(signature)] != signature:
            return None
        pos = start + len(signature)
        while pos + 8 <= len(blob):
            chunk_length = struct.unpack_from('>I', blob, pos)[0]
            chunk_type = blob[pos + 4:pos + 8]
            pos += 8 + chunk_length + 4
            if pos > len(blob):
                return None
            if chunk_type == b'IEND':
                return blob[start:pos]
        return None

    return try_extract(offset) or try_extract(offset + 4)


def rgba_bytes_to_image(width, height, rgba_bytes):
    return Image.frombytes('RGBA', (width, height), bytes(rgba_bytes[:width * height * 4]))


def indexed_bytes_to_image(width, height, pixels, palette_bytes):
    rgba = bytearray(width * height * 4)
    use_rgba_palette = len(palette_bytes) % 4 == 0 and len(palette_bytes) % 3 != 0
    for idx, color_index in enumerate(pixels[:width * height]):
        out = idx * 4
        if color_index == 0:
            rgba[out + 3] = 0
            continue
        if use_rgba_palette:
            src = color_index * 4
            rgba[out:out + 4] = palette_bytes[src:src + 4]
        else:
            src = color_index * 3
            rgba[out] = palette_bytes[src] if src < len(palette_bytes) else 0
            rgba[out + 1] = palette_bytes[src + 1] if src + 1 < len(palette_bytes) else 0
            rgba[out + 2] = palette_bytes[src + 2] if src + 2 < len(palette_bytes) else 0
            rgba[out + 3] = 255
    return Image.frombytes('RGBA', (width, height), bytes(rgba))


def decode_pcx_image_manual(raw_bytes, fallback_palette=None):
    payload = bytes(raw_bytes)
    if len(payload) < 128:
        raise ValueError("PCX inválido o incompleto")

    xmin, ymin, xmax, ymax = struct.unpack_from('<HHHH', payload, 4)
    width = (xmax - xmin) + 1
    height = (ymax - ymin) + 1
    planes = payload[65] or 1
    bytes_per_line = struct.unpack_from('<H', payload, 66)[0]
    expected = bytes_per_line * planes * height
    palette = None
    palette_marker_pos = len(payload) - 769 if len(payload) >= 769 else -1
    if palette_marker_pos >= 0 and payload[palette_marker_pos] == 0x0C:
        palette = payload[palette_marker_pos + 1:palette_marker_pos + 769]
        data_end = palette_marker_pos
    else:
        palette = bytes(fallback_palette) if fallback_palette else None
        data_end = len(payload)

    decoded = bytearray(expected)
    src = 128
    dst = 0
    while src < data_end and dst < expected:
        value = payload[src]
        src += 1
        if (value & 0xC0) == 0xC0 and src < data_end:
            count = value & 0x3F
            run_value = payload[src]
            src += 1
            end = min(expected, dst + count)
            decoded[dst:end] = bytes([run_value]) * (end - dst)
            dst = end
        else:
            decoded[dst] = value
            dst += 1

    pixels = bytearray(width * height)
    for y in range(height):
        row_start = y * bytes_per_line * planes
        pixels[y * width:(y + 1) * width] = decoded[row_start:row_start + width]

    if not palette or len(palette) < 768:
        raise ValueError("El sprite PCX no tiene palette utilizable")
    return indexed_bytes_to_image(width, height, pixels, palette), palette


def decode_pcx_image(raw_bytes, fallback_palette=None):
    payload = bytes(raw_bytes)
    palette = None
    if len(payload) >= 769 and payload[-769] == 0x0C:
        palette = payload[-768:]
    elif fallback_palette:
        palette = bytes(fallback_palette)
        payload += b'\x0C' + palette

    try:
        image = Image.open(io.BytesIO(payload))
        if image.mode == 'P':
            image_palette = image.getpalette() or []
            if len(image_palette) >= 768:
                palette = bytes(image_palette[:768])
        return image.convert('RGBA'), palette
    except Exception:
        return decode_pcx_image_manual(raw_bytes, fallback_palette=fallback_palette)


def extract_pcx_palette(raw_bytes):
    payload = bytes(raw_bytes)
    if len(payload) >= 769 and payload[-769] == 0x0C:
        return payload[-768:]
    return None


def decode_rle8_pixels(raw_bytes, expected_pixels):
    payload = bytes(raw_bytes)
    if len(payload) < 4:
        raise ValueError("Sprite RLE8 incompleto")
    encoded_size = struct.unpack_from('<I', payload, 0)[0]
    src = 4
    pixels = bytearray()
    target = int(expected_pixels or encoded_size)
    while src < len(payload) and len(pixels) < target:
        value = payload[src]
        src += 1
        if 0x40 <= value <= 0x7F and src < len(payload):
            pixels.extend(bytes([payload[src]]) * (value & 0x3F))
            src += 1
        else:
            pixels.append(value)
    if len(pixels) < target:
        raise ValueError("Sprite RLE8 incompleto o corrupto")
    return bytes(pixels[:target])


def decode_rle5_pixels(raw_bytes, expected_pixels):
    payload = bytes(raw_bytes)
    if len(payload) < 4:
        raise ValueError("Sprite RLE5 incompleto")
    encoded = payload[4:]
    target = int(expected_pixels or struct.unpack_from('<I', payload, 0)[0])
    pixels = bytearray()
    src = 0
    while len(pixels) < target and src < len(encoded):
        run_length = encoded[src]
        src += 1
        if src >= len(encoded):
            break
        data_length = encoded[src] & 0x7F
        color = 0
        if encoded[src] >> 7:
            src += 1
            if src >= len(encoded):
                break
            color = encoded[src]
        src += 1
        while True:
            if len(pixels) < target:
                pixels.append(color)
            run_length -= 1
            if run_length < 0:
                data_length -= 1
                if data_length < 0:
                    break
                if src >= len(encoded):
                    break
                color = encoded[src] & 0x1F
                run_length = encoded[src] >> 5
                src += 1
    if len(pixels) < target:
        raise ValueError("Sprite RLE5 incompleto o corrupto")
    return bytes(pixels[:target])


def decode_lz5_pixels(raw_bytes, expected_pixels):
    payload = bytes(raw_bytes)
    if len(payload) < 5:
        raise ValueError("Sprite LZ5 incompleto")
    encoded = payload[4:]
    target = int(expected_pixels or struct.unpack_from('<I', payload, 0)[0])
    pixels = bytearray(target)
    src = 0
    dst = 0
    control = encoded[src]
    control_shift = 0
    src += 1
    repeat_bits = 0
    repeat_bits_count = 0
    while dst < target and src < len(encoded):
        distance = encoded[src]
        src += 1
        if control & (1 << control_shift):
            if distance & 0x3F == 0:
                if src + 1 >= len(encoded):
                    break
                distance = ((distance << 2) | encoded[src]) + 1
                src += 1
                run_length = encoded[src] + 2
                src += 1
            else:
                repeat_bits |= ((distance & 0xC0) >> repeat_bits_count)
                repeat_bits_count += 2
                run_length = distance & 0x3F
                if repeat_bits_count < 8:
                    if src >= len(encoded):
                        break
                    distance = encoded[src] + 1
                    src += 1
                else:
                    distance = repeat_bits + 1
                    repeat_bits = 0
                    repeat_bits_count = 0
            while True:
                if dst >= target:
                    break
                ref_index = dst - distance
                if ref_index < 0:
                    raise ValueError("Sprite LZ5 corrupto: referencia fuera de rango")
                pixels[dst] = pixels[ref_index]
                dst += 1
                run_length -= 1
                if run_length < 0:
                    break
        else:
            if distance & 0xE0 == 0:
                if src >= len(encoded):
                    break
                run_length = encoded[src] + 8
                src += 1
            else:
                run_length = distance >> 5
                distance &= 0x1F
            for _ in range(run_length):
                if dst >= target:
                    break
                pixels[dst] = distance
                dst += 1
        control_shift += 1
        if control_shift >= 8:
            if src >= len(encoded):
                break
            control = encoded[src]
            control_shift = 0
            src += 1
    if dst < target:
        raise ValueError("Sprite LZ5 incompleto o corrupto")
    return bytes(pixels[:target])


def load_sff_v1_sprites(sff_blob, palette_override=None):
    view = memoryview(sff_blob)
    subheader_offset = struct.unpack_from('<I', sff_blob, 24)[0]
    headers = []
    offset = subheader_offset
    guard = 0
    while offset > 0 and offset + 32 <= len(sff_blob) and guard < 20000:
        next_offset, data_length = struct.unpack_from('<II', sff_blob, offset)
        axis_x, axis_y = struct.unpack_from('<hh', sff_blob, offset + 8)
        group, item = struct.unpack_from('<HH', sff_blob, offset + 12)
        linked = struct.unpack_from('<H', sff_blob, offset + 16)[0]
        same_palette = sff_blob[offset + 18] != 0
        headers.append({
            'group': group,
            'item': item,
            'axis_x': axis_x,
            'axis_y': axis_y,
            'linked': linked,
            'same_palette': same_palette,
            'data_start': offset + 32,
            'data_length': data_length,
        })
        if not next_offset or next_offset <= offset:
            break
        offset = next_offset
        guard += 1

    sprite_map = {}
    cache = {}
    for idx, header in enumerate(headers):
        sprite_map.setdefault((header['group'], header['item']), idx)

    default_shared_palette = bytes(palette_override) if palette_override else None
    for header in headers:
        if header['data_length'] <= 0:
            continue
        raw = view[header['data_start']:header['data_start'] + header['data_length']]
        palette = extract_pcx_palette(raw)
        if palette:
            default_shared_palette = bytes(palette)
            break

    def load_sprite(index):
        if index in cache:
            return cache[index]
        header = headers[index]
        if header['data_length'] == 0 and 0 <= header['linked'] < len(headers):
            base = load_sprite(header['linked'])
            sprite = {
                'image': base['image'],
                'axis_x': header['axis_x'],
                'axis_y': header['axis_y'],
                'palette': base.get('palette'),
            }
            cache[index] = sprite
            return sprite

        raw = view[header['data_start']:header['data_start'] + header['data_length']]
        fallback_palette = None
        if header['same_palette'] and index > 0:
            fallback_palette = load_sprite(index - 1).get('palette')
        if not fallback_palette and header['same_palette']:
            fallback_palette = default_shared_palette
        if not fallback_palette and len(raw) >= 128 + 768 and extract_pcx_palette(raw) is None:
            fallback_palette = bytes(raw[-768:])
        image, palette = decode_pcx_image(raw, fallback_palette=fallback_palette)
        if palette_override:
            palette = bytes(palette_override)
            pixel_image = image.convert('P')
            image = indexed_bytes_to_image(pixel_image.width, pixel_image.height, pixel_image.tobytes(), palette_override)
        sprite = {
            'image': image,
            'axis_x': header['axis_x'],
            'axis_y': header['axis_y'],
            'palette': palette,
        }
        cache[index] = sprite
        return sprite

    return 'SFF v1', sprite_map, load_sprite


def load_sff_v2_sprites(sff_blob, palette_override=None):
    sprite_offset = struct.unpack_from('<I', sff_blob, 0x24)[0]
    sprite_count = struct.unpack_from('<I', sff_blob, 0x28)[0]
    palette_offset = struct.unpack_from('<I', sff_blob, 0x2C)[0]
    palette_count = struct.unpack_from('<I', sff_blob, 0x30)[0]
    ldata_offset = struct.unpack_from('<I', sff_blob, 0x34)[0]

    palette_headers = []
    for idx in range(palette_count):
        off = palette_offset + idx * 16
        if off + 16 > len(sff_blob):
            break
        palette_headers.append({
            'group': struct.unpack_from('<H', sff_blob, off)[0],
            'item': struct.unpack_from('<H', sff_blob, off + 2)[0],
            'color_count': struct.unpack_from('<H', sff_blob, off + 4)[0],
            'linked': struct.unpack_from('<H', sff_blob, off + 6)[0],
            'data_offset': struct.unpack_from('<I', sff_blob, off + 8)[0],
            'data_length': struct.unpack_from('<I', sff_blob, off + 12)[0],
        })

    sprite_headers = []
    sprite_map = {}
    for idx in range(sprite_count):
        off = sprite_offset + idx * 28
        if off + 28 > len(sff_blob):
            break
        header = {
            'group': struct.unpack_from('<H', sff_blob, off)[0],
            'item': struct.unpack_from('<H', sff_blob, off + 2)[0],
            'width': struct.unpack_from('<H', sff_blob, off + 4)[0],
            'height': struct.unpack_from('<H', sff_blob, off + 6)[0],
            'axis_x': struct.unpack_from('<h', sff_blob, off + 8)[0],
            'axis_y': struct.unpack_from('<h', sff_blob, off + 10)[0],
            'linked': struct.unpack_from('<H', sff_blob, off + 12)[0],
            'format': sff_blob[off + 14],
            'color_depth': sff_blob[off + 15],
            'data_offset': struct.unpack_from('<I', sff_blob, off + 16)[0],
            'data_length': struct.unpack_from('<I', sff_blob, off + 20)[0],
            'palette_index': struct.unpack_from('<H', sff_blob, off + 24)[0],
            'flags': struct.unpack_from('<H', sff_blob, off + 26)[0],
        }
        sprite_headers.append(header)
        sprite_map.setdefault((header['group'], header['item']), idx)

    palette_cache = {}
    sprite_cache = {}

    def load_palette(index):
        if index in palette_cache:
            return palette_cache[index]
        if not (0 <= index < len(palette_headers)):
            return None
        header = palette_headers[index]
        if header['data_length'] == 0 and 0 <= header['linked'] < len(palette_headers) and header['linked'] != index:
            palette = load_palette(header['linked'])
            palette_cache[index] = palette
            return palette
        start = ldata_offset + header['data_offset']
        palette = bytes(sff_blob[start:start + header['data_length']])
        palette_cache[index] = palette
        return palette

    def load_sprite(index):
        if index in sprite_cache:
            return sprite_cache[index]
        header = sprite_headers[index]
        if header['data_length'] == 0 and 0 <= header['linked'] < len(sprite_headers):
            base = load_sprite(header['linked'])
            sprite = {
                'image': base['image'],
                'axis_x': header['axis_x'],
                'axis_y': header['axis_y'],
            }
            sprite_cache[index] = sprite
            return sprite

        start = ldata_offset + header['data_offset']
        png_payload = extract_png_bytes(sff_blob, start)
        if png_payload:
            image = Image.open(io.BytesIO(png_payload))
            if image.mode == 'P' and header['color_depth'] == 8:
                palette = bytes(palette_override) if palette_override else load_palette(header['palette_index'])
                if palette:
                    image = indexed_bytes_to_image(image.width, image.height, image.tobytes(), palette)
                else:
                    image = image.convert('RGBA')
            else:
                image = image.convert('RGBA')
        elif header['color_depth'] == 8:
            pixel_count = header['width'] * header['height']
            if header['format'] == 2:
                pixels = decode_rle8_pixels(sff_blob[start:start + header['data_length']], pixel_count)
            else:
                pixels = sff_blob[start:start + pixel_count]
            if len(pixels) < pixel_count:
                raise ValueError(f"Sprite {header['group']},{header['item']} usa compresión SFF v2 no soportada todavía")
            palette = bytes(palette_override) if palette_override else load_palette(header['palette_index'])
            if not palette:
                raise ValueError(f"Palette {header['palette_index']} no disponible para {header['group']},{header['item']}")
            image = indexed_bytes_to_image(header['width'], header['height'], pixels, palette)
        elif header['color_depth'] == 5:
            pixel_count = header['width'] * header['height']
            if header['format'] == 3:
                pixels = decode_rle5_pixels(sff_blob[start:start + header['data_length']], pixel_count)
            elif header['format'] == 4:
                pixels = decode_lz5_pixels(sff_blob[start:start + header['data_length']], pixel_count)
            else:
                raise ValueError(f"Sprite {header['group']},{header['item']} usa compresión 5-bit no soportada ({header['format']})")
            palette = bytes(palette_override) if palette_override else load_palette(header['palette_index'])
            if not palette:
                raise ValueError(f"Palette {header['palette_index']} no disponible para {header['group']},{header['item']}")
            image = indexed_bytes_to_image(header['width'], header['height'], pixels, palette)
        elif header['color_depth'] == 32:
            byte_length = header['width'] * header['height'] * 4
            rgba_bytes = sff_blob[start:start + byte_length]
            if len(rgba_bytes) < byte_length:
                raise ValueError(f"Sprite {header['group']},{header['item']} usa compresión SFF v2 no soportada todavía")
            image = rgba_bytes_to_image(header['width'], header['height'], rgba_bytes)
        else:
            raise ValueError(f"Formato SFF v2 no soportado ({header['format']}/{header['color_depth']})")

        sprite = {
            'image': image,
            'axis_x': header['axis_x'],
            'axis_y': header['axis_y'],
        }
        sprite_cache[index] = sprite
        return sprite

    return 'SFF v2', sprite_map, load_sprite


def resolve_preview_frames(sprite_map, load_sprite, frame_defs):
    resolved_frames = []
    for frame in frame_defs:
        sprite_idx = sprite_map.get((frame['group'], frame['item']))
        if sprite_idx is None:
            continue
        sprite = load_sprite(sprite_idx)
        image = sprite['image']
        if frame.get('flip_h'):
            image = image.transpose(Image.FLIP_LEFT_RIGHT)
        if frame.get('flip_v'):
            image = image.transpose(Image.FLIP_TOP_BOTTOM)
        left = frame.get('offset_x', 0) - sprite['axis_x']
        top = frame.get('offset_y', 0) - sprite['axis_y']
        resolved_frames.append({
            'image': image,
            'left': left,
            'top': top,
            'duration': max(16, int(round(frame.get('ticks', 1) * 1000 / 60))),
        })
    return resolved_frames


def list_air_action_ids(air_path):
    action_ids = []
    seen = set()
    with open(air_path, 'r', encoding='utf-8', errors='replace') as f:
        for raw_line in f:
            line = raw_line.split(';', 1)[0].strip()
            if not line:
                continue
            match = re.match(r'^\[Begin Action\s+(-?\d+)\]$', line, re.I)
            if not match:
                continue
            try:
                action_no = int(match.group(1))
            except Exception:
                continue
            if action_no in seen:
                continue
            seen.add(action_no)
            action_ids.append(action_no)
    return action_ids


def analyze_preview_frames(frames):
    if not frames:
        return {
            'frame_count': 0,
            'unique_images': 0,
            'avg_area': 0,
        }
    unique_images = set()
    areas = []
    for frame in frames:
        image = frame['image']
        unique_images.add(image.tobytes())
        bbox = image.getbbox()
        if bbox is None:
            areas.append(0)
        else:
            areas.append(max(0, (bbox[2] - bbox[0]) * (bbox[3] - bbox[1])))
    return {
        'frame_count': len(frames),
        'unique_images': len(unique_images),
        'avg_area': int(sum(areas) / max(1, len(areas))),
    }


def analyze_action_candidate(frame_defs, frames):
    metrics = analyze_preview_frames(frames)
    base_refs = {
        (frame.get('group'), frame.get('item'))
        for frame in (frame_defs or [])
        if 'group' in frame and 'item' in frame
    }
    oriented_refs = {
        (
            frame.get('group'),
            frame.get('item'),
            bool(frame.get('flip_h')),
            bool(frame.get('flip_v')),
        )
        for frame in (frame_defs or [])
        if 'group' in frame and 'item' in frame
    }
    metrics['unique_base_refs'] = len(base_refs)
    metrics['unique_oriented_refs'] = len(oriented_refs)
    metrics['mirror_only'] = (
        len(frame_defs or []) >= 2
        and metrics['unique_images'] > 1
        and len(base_refs) == 1
        and len(oriented_refs) > 1
    )
    return metrics


def choose_idle_action_preview(preview, sprite_map, load_sprite):
    preferred_actions = [0, 5, 6, 1, 3, 2, 10, 11, 12, 20, 21, 40, 41, 42, 43, 44, 45, 46, 47, 50, 100, 105]
    available_actions = set(list_air_action_ids(preview['air_abs_path']))
    metrics_by_action = {}

    def load_action_metrics(action_no):
        if action_no in metrics_by_action:
            return metrics_by_action[action_no]
        if action_no not in available_actions:
            metrics_by_action[action_no] = None
            return None
        try:
            action = parse_air_action(preview['air_abs_path'], action_no)
            frames = resolve_preview_frames(sprite_map, load_sprite, action['frames'])
        except Exception:
            metrics_by_action[action_no] = None
            return None
        if not frames:
            metrics_by_action[action_no] = None
            return None
        metrics_by_action[action_no] = {
            'action_no': action_no,
            'frames': frames,
            'metrics': analyze_action_candidate(action['frames'], frames),
        }
        return metrics_by_action[action_no]

    action_zero = load_action_metrics(0)
    if action_zero and action_zero['metrics']['unique_images'] > 1:
        return action_zero, False

    state_specs = extract_state0_action_candidates(preview)
    state_actions = []
    seen_state_actions = set()
    paired_stand_variants = sorted({
        spec['base_action'] - 5
        for spec in state_specs
        if not spec['mode_expanded']
        and spec['base_action'] >= 1000
        and spec['base_action'] % 10 == 5
        and (spec['base_action'] - 5) in available_actions
    })
    for idx, spec in enumerate(state_specs):
        base_action = spec['base_action']
        if base_action not in seen_state_actions:
            seen_state_actions.add(base_action)
            state_actions.append((base_action, idx))
        if spec['mode_expanded'] and 0 <= base_action < 1000:
            variants = [action_no for action_no in paired_stand_variants if action_no % 1000 == base_action]
            for variant in variants:
                if variant in seen_state_actions:
                    continue
                seen_state_actions.add(variant)
                state_actions.append((variant, idx + 100))

    state_candidates = []
    for action_no, priority in state_actions:
        item = load_action_metrics(action_no)
        if not item:
            continue
        state_candidates.append({**item, 'priority': priority})

    if state_candidates:
        animated_state_candidates = [
            item for item in state_candidates
            if item['metrics']['unique_images'] > 1 and not item['metrics'].get('mirror_only')
        ]
        if animated_state_candidates:
            animated_state_candidates.sort(
                key=lambda item: (
                    1 if item['action_no'] % 10 == 0 else 0,
                    item['metrics']['unique_images'],
                    item['metrics']['avg_area'],
                    item['metrics']['frame_count'],
                    -item['priority'],
                ),
                reverse=True,
            )
            return animated_state_candidates[0], True

    if action_zero is not None:
        return action_zero, False

    candidates = []
    for priority, action_no in enumerate(preferred_actions):
        item = load_action_metrics(action_no)
        if not item:
            continue
        candidates.append({**item, 'priority': priority})
    if not candidates:
        raise ValueError("No se encontró una animación utilizable en el AIR")

    animated_candidates = [
        item for item in candidates
        if item['metrics']['unique_images'] > 1 and not item['metrics'].get('mirror_only')
    ]
    if animated_candidates:
        animated_candidates.sort(key=lambda item: item['priority'])
        return animated_candidates[0], True

    candidates.sort(
        key=lambda item: (
            item['metrics']['avg_area'],
            item['metrics']['frame_count'],
            -item['priority'],
        ),
        reverse=True,
    )
    return candidates[0], True


def render_preview_result(preview, sff_version, resolved_frames, status):
    if not resolved_frames:
        raise ValueError("No hay sprites válidos para renderizar la preview")

    min_x = min(frame['left'] for frame in resolved_frames)
    min_y = min(frame['top'] for frame in resolved_frames)
    max_x = max(frame['left'] + frame['image'].width for frame in resolved_frames)
    max_y = max(frame['top'] + frame['image'].height for frame in resolved_frames)
    content_width = max(1, max_x - min_x)
    content_height = max(1, max_y - min_y)
    pad_x = max(8, min(18, int(round(content_width * 0.12))))
    pad_y = max(8, min(20, int(round(content_height * 0.10))))
    width = content_width + pad_x * 2
    height = content_height + pad_y * 2

    rendered_frames = []
    durations = []
    for frame in resolved_frames:
        canvas = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        canvas.alpha_composite(frame['image'], (frame['left'] - min_x + pad_x, frame['top'] - min_y + pad_y))
        rendered_frames.append(canvas)
        durations.append(frame['duration'])

    payload = io.BytesIO()
    rendered_frames[0].save(
        payload,
        format='PNG',
        save_all=True,
        append_images=rendered_frames[1:],
        duration=durations,
        loop=0,
        disposal=[0] * len(rendered_frames),
        blend=[0] * len(rendered_frames),
        optimize=False,
    )
    return {
        'display_name': preview['display_name'],
        'frame_count': len(rendered_frames),
        'sff_version': sff_version,
        'mime': 'image/png',
        'image_bytes': payload.getvalue(),
        'status': status,
    }


def build_char_static_fallback(preview, sff_version, sprite_map, load_sprite):
    candidates = [(9000, item) for item in range(1, 11)] + [(9000, 0)] + [(0, 0)] + [(0, item) for item in range(1, 6)]
    for group, item in candidates:
        if (group, item) not in sprite_map:
            continue
        try:
            frames = resolve_preview_frames(sprite_map, load_sprite, [{
                'group': group,
                'item': item,
                'offset_x': 0,
                'offset_y': 0,
                'ticks': 1,
                'flip_h': False,
                'flip_v': False,
            }])
            if frames:
                label = 'Portrait fallback' if group == 9000 else 'Sprite fallback'
                return render_preview_result(preview, sff_version, frames, label)
        except Exception:
            continue
    return None


def build_char_mugshot_result(preview, sff_version, sprite_map, load_sprite):
    candidates = [(9000, item) for item in range(1, 11)] + [(9000, 0)]
    for group, item in candidates:
        if (group, item) not in sprite_map:
            continue
        try:
            frames = resolve_preview_frames(sprite_map, load_sprite, [{
                'group': group,
                'item': item,
                'offset_x': 0,
                'offset_y': 0,
                'ticks': 1,
                'flip_h': False,
                'flip_v': False,
            }])
            if frames:
                return render_preview_result(preview, sff_version, frames, 'Mugshot')
        except Exception:
            continue
    return None


def _iter_preview_override_dirs(preview):
    char_dir = os.path.dirname(preview['def_abs_path'])
    if not os.path.isdir(char_dir):
        return
    try:
        entries = sorted(os.scandir(char_dir), key=lambda entry: entry.name.lower())
    except OSError:
        return
    for entry in entries:
        if not entry.is_dir():
            continue
        name_key = entry.name.casefold()
        if 'fix' not in name_key or 'sprite' not in name_key:
            continue
        yield entry.path


def _find_override_frame_path(dir_path, group, item):
    candidates = [
        f"{item}.png",
        f"{group}-{item}.png",
        f"{group}_{item}.png",
        f"{group}.{item}.png",
    ]
    try:
        entries = {entry.name.casefold(): entry.path for entry in os.scandir(dir_path) if entry.is_file()}
    except OSError:
        return None
    for name in candidates:
        match = entries.get(name.casefold())
        if match:
            return match
    return None


def build_char_override_preview(preview, action):
    frame_defs = action.get('frames', []) if isinstance(action, dict) else []
    if not frame_defs:
        return None
    for dir_path in _iter_preview_override_dirs(preview) or []:
        try:
            cache = {}
            resolved_frames = []
            for frame in frame_defs:
                key = (frame['group'], frame['item'])
                if key not in cache:
                    frame_path = _find_override_frame_path(dir_path, frame['group'], frame['item'])
                    if not frame_path:
                        if resolved_frames:
                            break
                        cache = None
                        break
                    image = Image.open(frame_path).convert('RGBA')
                    cache[key] = image
                if cache is None:
                    break
                image = cache[key]
                if frame.get('flip_h'):
                    image = image.transpose(Image.FLIP_LEFT_RIGHT)
                if frame.get('flip_v'):
                    image = image.transpose(Image.FLIP_TOP_BOTTOM)
                resolved_frames.append({
                    'image': image,
                    'left': frame.get('offset_x', 0) - image.width // 2,
                    'top': frame.get('offset_y', 0) - image.height,
                    'duration': max(16, int(round(frame.get('ticks', 1) * 1000 / 60))),
                })
            if resolved_frames:
                return render_preview_result(preview, 'PNG override', resolved_frames, 'Action 0 · Idle (fix sprites)')
        except Exception:
            continue
    return None


def build_char_idle_preview(root, char_name, preferred_ref=""):
    if Image is None:
        raise ValueError("Pillow no está disponible en el servidor")

    preview = resolve_char_preview_paths(root, char_name, preferred_ref)
    cache_key = (
        os.path.abspath(root),
        char_name_key(preview.get('char_ref') or preview['name']),
        os.path.getmtime(preview['air_abs_path']),
        os.path.getmtime(preview['sff_abs_path']),
    )
    cached = CHAR_IDLE_PREVIEW_CACHE.get(cache_key)
    if cached:
        return cached

    with open(preview['sff_abs_path'], 'rb') as f:
        sff_blob = f.read()

    version_tag = sff_blob[15]
    if version_tag == 1:
        sff_version, sprite_map, load_sprite = load_sff_v1_sprites(sff_blob)
    elif version_tag == 2:
        sff_version, sprite_map, load_sprite = load_sff_v2_sprites(sff_blob)
    else:
        raise ValueError(f"Versión de SFF no soportada ({version_tag})")

    result = None
    action_error = None
    selected_action_no = None
    selected_action_frames = None
    try:
        action_choice, used_fallback_action = choose_idle_action_preview(preview, sprite_map, load_sprite)
        action_no = action_choice['action_no']
        action_frames = action_choice['frames']
        selected_action_no = action_no
        selected_action_frames = action_frames
        action = parse_air_action(preview['air_abs_path'], action_no)
        override_result = build_char_override_preview(preview, action)
        if override_result is not None:
            result = override_result
        else:
            if action_frames:
                status = f'Action {action_no} · Idle'
                if action_no != 0 or used_fallback_action:
                    status += ' fallback'
                result = render_preview_result(preview, sff_version, action_frames, status)
            else:
                action_error = ValueError(f"El Action {action_no} no encontró sprites válidos en el SFF")
    except Exception as exc:
        action_error = exc

    if result is None:
        result = build_char_static_fallback(preview, sff_version, sprite_map, load_sprite)
    if result is None and action_error is not None:
        raise action_error
    if result is None:
        raise ValueError("No se pudo construir una preview utilizable para el personaje")

    if version_tag == 1 and preview.get('pal1_abs_path') and selected_action_no is not None and selected_action_frames:
        palette_override = read_act_palette_bytes(preview['pal1_abs_path'])
        if palette_override:
            try:
                _, alt_sprite_map, alt_load_sprite = load_sff_v1_sprites(sff_blob, palette_override=palette_override)
                alt_frames = resolve_preview_frames(alt_sprite_map, alt_load_sprite, parse_air_action(preview['air_abs_path'], selected_action_no)['frames'])
                if alt_frames:
                    base_info = analyze_single_preview_image(selected_action_frames[0]['image'])
                    alt_info = analyze_single_preview_image(alt_frames[0]['image'])
                    if (
                        base_info['top_left'][3] > 0
                        and alt_info['top_left'][3] == 0
                        and alt_info['non_black_ratio'] >= 0.25
                    ):
                        alt_status = result.get('status', f'Action {selected_action_no} · Idle')
                        result = render_preview_result(preview, sff_version, alt_frames, alt_status)
            except Exception:
                pass

    CHAR_IDLE_PREVIEW_CACHE.clear()
    CHAR_IDLE_PREVIEW_CACHE[cache_key] = result
    return result


def build_char_mugshot_preview(root, char_name, preferred_ref=""):
    if Image is None:
        raise ValueError("Pillow no está disponible en el servidor")

    preview = resolve_char_preview_paths(root, char_name, preferred_ref)
    cache_key = (
        os.path.abspath(root),
        char_name_key(preview.get('char_ref') or preview['name']),
        os.path.getmtime(preview['sff_abs_path']),
        'mugshot',
    )
    cached = CHAR_MUGSHOT_PREVIEW_CACHE.get(cache_key)
    if cached:
        return cached

    with open(preview['sff_abs_path'], 'rb') as f:
        sff_blob = f.read()

    version_tag = sff_blob[15]
    if version_tag == 1:
        sff_version, sprite_map, load_sprite = load_sff_v1_sprites(sff_blob)
    elif version_tag == 2:
        sff_version, sprite_map, load_sprite = load_sff_v2_sprites(sff_blob)
    else:
        raise ValueError(f"Versión de SFF no soportada ({version_tag})")

    result = build_char_mugshot_result(preview, sff_version, sprite_map, load_sprite)
    if result is None:
        raise ValueError("No se encontró un mugshot utilizable en el SFF")

    if version_tag == 1 and preview.get('pal1_abs_path'):
        palette_override = read_act_palette_bytes(preview['pal1_abs_path'])
        if palette_override:
            try:
                _, alt_sprite_map, alt_load_sprite = load_sff_v1_sprites(sff_blob, palette_override=palette_override)
                alt_result = build_char_mugshot_result(preview, sff_version, alt_sprite_map, alt_load_sprite)
                if alt_result:
                    base_img = Image.open(io.BytesIO(result['image_bytes'])).convert('RGBA')
                    alt_img = Image.open(io.BytesIO(alt_result['image_bytes'])).convert('RGBA')
                    base_info = analyze_single_preview_image(base_img)
                    alt_info = analyze_single_preview_image(alt_img)
                    if (
                        base_info['top_left'][3] > 0
                        and alt_info['top_left'][3] == 0
                        and alt_info['non_black_ratio'] >= 0.25
                    ):
                        result = alt_result
            except Exception:
                pass

    CHAR_MUGSHOT_PREVIEW_CACHE.clear()
    CHAR_MUGSHOT_PREVIEW_CACHE[cache_key] = result
    return result


def replace_missing_roster_chars_with_random(root):
    parsed = parse_select_def_full(root)
    roster = apply_editor_chars_meta(root, parsed["chars"])
    installed_keys = {char_name_key(name) for name in list_installed_char_names(root)}
    replaced = []
    changes = 0

    for entry in roster:
        if entry.get("kind") != "char":
            continue
        name = normalize_text(entry.get("name", ""))
        ref = normalize_text(entry.get("char_ref", "")) or name
        key = char_name_key(ref)
        if not name or key in {"null", "randomselect"}:
            continue
        if key in installed_keys:
            continue
        slot_locked = bool(entry.get("slot_locked", False))
        entry.clear()
        entry.update(make_char_entry("randomselect"))
        entry["slot_locked"] = slot_locked
        replaced.append(name)
        changes += 1

    if changes:
        write_select_def(root, roster, parsed["stages"], parsed["options"])
        save_editor_chars_meta(root, roster)

    return {
        "changed": changes,
        "replaced": replaced,
        "installed_chars": len(installed_keys),
    }


def read_stage_name(def_path):
    """Read the name= field from a stage .def file."""
    try:
        with open(def_path, 'r', encoding='utf-8', errors='replace') as f:
            for line in f:
                line = line.strip()
                if line.lower().startswith('name') and '=' in line:
                    val = line.split('=', 1)[1].split(';')[0].strip().strip('"').strip("'")
                    if val: return val
                    break
                if line.startswith('[') and 'Info' not in line:
                    break
    except: pass
    return None

def list_available_stages(root):
    stages_dir = os.path.join(root, "stages")
    available = []
    if not os.path.isdir(stages_dir): return available
    for entry in os.scandir(stages_dir):
        if entry.is_dir():
            defs = [f for f in os.listdir(entry.path) if f.endswith('.def') and os.path.isfile(os.path.join(entry.path, f))]
            for d in defs:
                rel = f"stages/{entry.name}/{d}"
                abs_path = os.path.join(entry.path, d)
                real_name = read_stage_name(abs_path) or entry.name.replace('_', ' ')
                available.append({"name": rel, "display": real_name, "type": "folder"})
        elif entry.name.endswith('.def'):
            rel = f"stages/{entry.name}"
            abs_path = os.path.join(stages_dir, entry.name)
            real_name = read_stage_name(abs_path) or entry.name.replace('.def', '').replace('_', ' ')
            available.append({"name": rel, "display": real_name, "type": "file"})
    available.sort(key=lambda x: x["display"].lower())
    return available

def resolve_stage_names(root, stage_paths):
    """Given a list of stage paths from select.def, resolve their real names."""
    result = {}
    for sp in stage_paths:
        if sp in result: continue
        abs_path = os.path.join(root, sp)
        name = read_stage_name(abs_path) if os.path.isfile(abs_path) else None
        if not name:
            parts = sp.replace('\\', '/').split('/')
            fname = parts[-1].replace('.def', '') if parts else sp
            folder = parts[-2] if len(parts) > 2 else ''
            name = (folder or fname).replace('_', ' ')
        result[sp] = name
    return result

def extract_zip_to(zip_path, dest_dir):
    """Extract a zip and return the folder name created."""
    with zipfile.ZipFile(zip_path, 'r') as zf:
        names = zf.namelist()
        top_dirs = set()
        for n in names:
            parts = n.split('/')
            if len(parts) > 1 and parts[0]: top_dirs.add(parts[0])
        if len(top_dirs) == 1:
            zf.extractall(dest_dir)
            return list(top_dirs)[0]
        else:
            folder_name = os.path.splitext(os.path.basename(zip_path))[0]
            dest = os.path.join(dest_dir, folder_name)
            os.makedirs(dest, exist_ok=True)
            zf.extractall(dest)
            return folder_name


def sanitize_package_name(name, fallback):
    base = os.path.splitext(os.path.basename(name or ""))[0]
    base = re.sub(r'[^A-Za-z0-9._-]+', '_', base).strip('._-')
    return base or fallback


def safe_join(base_dir, rel_path):
    rel_parts = [part for part in rel_path.replace('\\', '/').split('/') if part and part not in ('.', '..')]
    abs_path = os.path.normpath(os.path.join(base_dir, *rel_parts))
    base_norm = os.path.normpath(base_dir)
    if abs_path != base_norm and not abs_path.startswith(base_norm + os.sep):
        raise ValueError(f"Ruta insegura en ZIP: {rel_path}")
    return abs_path


def normalize_zip_member_path(name):
    path = (name or "").replace('\\', '/').strip('/')
    if not path or path.startswith('__MACOSX/'):
        return None
    parts = []
    for part in path.split('/'):
        if part in ('', '.'):
            continue
        if part == '..':
            raise ValueError(f"Ruta inválida en ZIP: {name}")
        parts.append(part)
    if not parts:
        return None
    return '/'.join(parts)


def list_zip_file_paths(zf):
    paths = []
    for info in zf.infolist():
        if info.is_dir():
            continue
        normalized = normalize_zip_member_path(info.filename)
        if normalized:
            paths.append(normalized)
    return paths


def strip_single_wrapper(paths):
    if not paths:
        return paths, None
    first_parts = {path.split('/')[0] for path in paths}
    if len(first_parts) != 1:
        return paths, None
    wrapper = next(iter(first_parts))
    stripped = []
    for path in paths:
        parts = path.split('/')
        if len(parts) < 2:
            return paths, None
        stripped.append('/'.join(parts[1:]))
    return stripped, wrapper


def is_project_bundle(paths, upload_type):
    top_dirs = {path.split('/')[0].lower() for path in paths if '/' in path}
    known_dirs = top_dirs & PROJECT_BUNDLE_DIRS
    target_dir = "chars" if upload_type == "chars" else "stages"
    if target_dir in known_dirs:
        return True
    if len(known_dirs) >= 2:
        return True
    return any('/' not in path and path.lower() in PROJECT_BUNDLE_FILES for path in paths)


def summarize_installed_entries(upload_type, rel_paths):
    prefix = ("chars/" if upload_type == "chars" else "stages/")
    entries = []
    for rel_path in rel_paths:
        path = rel_path.replace('\\', '/')
        if not path.startswith(prefix):
            continue
        rest = path[len(prefix):]
        if not rest:
            continue
        if upload_type == "stages" and '/' not in rest and rest.lower().endswith('.def'):
            entries.append(os.path.splitext(rest)[0])
        else:
            entries.append(rest.split('/')[0])
    return sorted({entry for entry in entries if entry})


def copy_zip_entries(zf, dest_root, rel_paths, strip_prefix=None):
    written = []
    prefix = (strip_prefix.rstrip('/') + '/') if strip_prefix else None
    for info in zf.infolist():
        if info.is_dir():
            continue
        normalized = normalize_zip_member_path(info.filename)
        if not normalized:
            continue
        rel_path = normalized
        if prefix:
            if not rel_path.startswith(prefix):
                continue
            rel_path = rel_path[len(prefix):]
            if not rel_path:
                continue
        if rel_path not in rel_paths:
            continue
        dest_path = safe_join(dest_root, rel_path)
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        with zf.open(info) as src, open(dest_path, 'wb') as dst:
            shutil.copyfileobj(src, dst)
        written.append(rel_path)
    return written


def iter_def_asset_refs(def_path, asset_exts=DEF_ASSET_EXTS):
    refs = []
    try:
        with open(def_path, 'r', encoding='utf-8', errors='replace') as f:
            for raw_line in f:
                line = raw_line.split(';', 1)[0].strip()
                if not line or '=' not in line:
                    continue
                _, value = line.split('=', 1)
                value = value.strip().strip('"').strip("'")
                if not value or value.endswith('/'):
                    continue
                normalized = value.replace('\\', '/').strip()
                _, ext = os.path.splitext(normalized)
                if ext.lower() in asset_exts:
                    refs.append(normalized)
    except:
        pass
    return refs


def resolve_package_asset_destination(project_root, package_root, target_dirname, ref_path):
    parts = [part for part in ref_path.replace('\\', '/').split('/') if part]
    if not parts:
        return None
    top = parts[0].lower()
    if top == target_dirname:
        if len(parts) >= 3:
            return safe_join(package_root, '/'.join(parts[2:]))
        if len(parts) == 2:
            return safe_join(package_root, parts[1])
        return package_root
    if top in PROJECT_BUNDLE_DIRS or (len(parts) == 1 and parts[0].lower() in PROJECT_BUNDLE_FILES):
        return safe_join(project_root, '/'.join(parts))
    return safe_join(package_root, '/'.join(parts))


def find_package_source_by_basename(package_root, filename):
    wanted = os.path.basename(filename).lower()
    matches = []
    for root, _, files in os.walk(package_root):
        for file_name in files:
            if file_name.lower() != wanted:
                continue
            matches.append(os.path.join(root, file_name))
    if len(matches) == 1:
        return matches[0]
    return None


def reorganize_flat_package_from_defs(project_root, package_root, upload_type):
    moved = []
    target_dirname = "chars" if upload_type == "chars" else "stages"
    def_paths = []
    for root, _, files in os.walk(package_root):
        for file_name in files:
            if file_name.lower().endswith('.def'):
                def_paths.append(os.path.join(root, file_name))

    seen_refs = set()
    for def_path in def_paths:
        for ref in iter_def_asset_refs(def_path):
            ref_key = ref.lower()
            if ref_key in seen_refs:
                continue
            seen_refs.add(ref_key)

            dest_path = resolve_package_asset_destination(project_root, package_root, target_dirname, ref)
            if not dest_path:
                continue
            if os.path.isfile(dest_path):
                continue

            src_path = find_package_source_by_basename(package_root, ref)
            if not src_path:
                continue
            if os.path.normpath(src_path) == os.path.normpath(dest_path):
                continue

            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            shutil.move(src_path, dest_path)
            moved.append({
                "source": os.path.relpath(src_path, package_root).replace('\\', '/'),
                "destination": os.path.relpath(dest_path, project_root).replace('\\', '/')
            })
    return moved


def convert_archive_to_zip_bytes(file_name, file_data):
    """Extract .rar or .7z using system tools, repack as ZIP bytes in memory."""
    ext = os.path.splitext(file_name)[1].lower()
    tmp_dir = tempfile.mkdtemp(prefix="ikemen_archive_")
    archive_path = os.path.join(tmp_dir, file_name)
    extract_dir = os.path.join(tmp_dir, "extracted")
    os.makedirs(extract_dir, exist_ok=True)
    try:
        with open(archive_path, 'wb') as f:
            f.write(file_data)
        if ext == '.7z':
            result = subprocess.run(
                ['7z', 'x', archive_path, f'-o{extract_dir}', '-y'],
                capture_output=True, timeout=120
            )
            if result.returncode != 0:
                raise ValueError(f"Error extrayendo .7z: {result.stderr.decode(errors='replace')[:300]}")
        elif ext == '.rar':
            result = subprocess.run(
                ['unrar', 'x', '-o+', archive_path, extract_dir + '/'],
                capture_output=True, timeout=120
            )
            if result.returncode != 0:
                raise ValueError(f"Error extrayendo .rar: {result.stderr.decode(errors='replace')[:300]}")
        else:
            raise ValueError(f"Formato no soportado: {ext}")
        # Repack as ZIP in memory
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(extract_dir):
                for fname in files:
                    abs_path = os.path.join(root, fname)
                    arc_name = os.path.relpath(abs_path, extract_dir)
                    zf.write(abs_path, arc_name)
        zip_bytes = zip_buffer.getvalue()
        zip_name = os.path.splitext(file_name)[0] + ".zip"
        return zip_name, zip_bytes
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def install_upload_zip(project_root, zip_name, zip_bytes, upload_type):
    target_dirname = "chars" if upload_type == "chars" else "stages"
    target_root = os.path.join(project_root, target_dirname)
    os.makedirs(target_root, exist_ok=True)

    with zipfile.ZipFile(io.BytesIO(zip_bytes), 'r') as zf:
        raw_paths = list_zip_file_paths(zf)
        if not raw_paths:
            raise ValueError("El ZIP no contiene archivos válidos")

        stripped_paths, wrapper = strip_single_wrapper(raw_paths)
        use_wrapper_bundle = wrapper is not None and is_project_bundle(stripped_paths, upload_type)
        root_bundle = is_project_bundle(raw_paths, upload_type) or use_wrapper_bundle

        if root_bundle:
            rel_paths = stripped_paths if use_wrapper_bundle else raw_paths
            written = copy_zip_entries(zf, project_root, set(rel_paths), strip_prefix=wrapper if use_wrapper_bundle else None)
            has_def = any(path.lower().startswith(target_dirname + "/") and path.lower().endswith('.def') for path in written)
            installed = summarize_installed_entries(upload_type, written)
            fallback = sanitize_package_name(zip_name, target_dirname)
            return {
                "mode": "project_root",
                "name": installed[0] if len(installed) == 1 else fallback,
                "installed": installed,
                "has_def": has_def,
                "type": upload_type,
            }

        if wrapper is not None:
            folder_name = sanitize_package_name(wrapper, sanitize_package_name(zip_name, target_dirname))
            rel_paths = set(stripped_paths)
            dest_root = os.path.join(target_root, folder_name)
            written = copy_zip_entries(zf, dest_root, rel_paths, strip_prefix=wrapper)
            flat_layout = all('/' not in path for path in stripped_paths)
        else:
            top_dirs = {path.split('/')[0] for path in raw_paths if '/' in path}
            root_files = any('/' not in path for path in raw_paths)
            if len(top_dirs) == 1 and not root_files:
                folder_name = sanitize_package_name(next(iter(top_dirs)), sanitize_package_name(zip_name, target_dirname))
                dest_root = target_root
                rel_paths = set(raw_paths)
            else:
                folder_name = sanitize_package_name(zip_name, target_dirname)
                dest_root = os.path.join(target_root, folder_name)
                rel_paths = set(raw_paths)
            written = copy_zip_entries(zf, dest_root, rel_paths)
            flat_layout = all('/' not in path for path in raw_paths)

        has_def = any(path.lower().endswith('.def') for path in written)
        relocated = []
        if flat_layout:
            package_root = os.path.join(target_root, folder_name)
            relocated = reorganize_flat_package_from_defs(project_root, package_root, upload_type)
        return {
            "mode": "folder",
            "name": folder_name,
            "installed": [folder_name],
            "has_def": has_def,
            "type": upload_type,
            "relocated": relocated,
        }


def normalize_package_rel_path(ref_path):
    parts = []
    for part in (ref_path or "").replace('\\', '/').split('/'):
        part = part.strip()
        if not part or part == '.':
            continue
        if part == '..':
            if parts:
                parts.pop()
            continue
        parts.append(part)
    return '/'.join(parts)


def lifebar_ref_to_rel_path(ref_path):
    rel = normalize_package_rel_path(ref_path)
    parts = [part for part in rel.split('/') if part]
    if not parts:
        return ''
    if parts[0].lower() == 'lifebars' and len(parts) >= 3:
        return '/'.join(parts[2:])
    if parts[0].lower() == 'data' and len(parts) >= 3:
        return '/'.join(parts[2:])
    if parts[0].lower() == 'data' and len(parts) == 2:
        return parts[1]
    return '/'.join(parts)


def resolve_lifebar_package_destination(package_root, ref_path):
    rel = lifebar_ref_to_rel_path(ref_path)
    if not rel:
        return None
    return safe_join(package_root, rel)


def read_lifebar_meta(package_root):
    meta_path = os.path.join(package_root, LIFEBAR_META_FILE)
    if not os.path.isfile(meta_path):
        return {}
    try:
        with open(meta_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except:
        return {}


def write_lifebar_meta(package_root, data):
    meta_path = os.path.join(package_root, LIFEBAR_META_FILE)
    with open(meta_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def read_def_info(def_path):
    info = {}
    section = None
    try:
        with open(def_path, 'r', encoding='utf-8', errors='replace') as f:
            for raw_line in f:
                stripped = raw_line.strip()
                if stripped.startswith('[') and stripped.endswith(']'):
                    section = stripped[1:-1].strip().lower()
                    continue
                if section not in ('info', 'files'):
                    continue
                line = raw_line.split(';', 1)[0].strip()
                if not line or '=' not in line:
                    continue
                key, value = line.split('=', 1)
                info[key.strip().lower()] = value.strip().strip('"').strip("'")
    except:
        pass
    return info


def file_looks_like_lifebar_def(def_path):
    base = os.path.basename(def_path).lower()
    if base.startswith('fight') and base.endswith('.def'):
        return True
    try:
        with open(def_path, 'r', encoding='utf-8', errors='replace') as f:
            data = f.read(8192).lower()
        return '[lifebar]' in data or '[simul lifebar]' in data or '[turns lifebar]' in data
    except:
        return False


def score_lifebar_def(def_path):
    base = os.path.basename(def_path).lower()
    score = 0
    if base == 'fight.def':
        score += 300
    elif base.startswith('fight') and base.endswith('.def'):
        score += 200
    if file_looks_like_lifebar_def(def_path):
        score += 150
    return score


def find_lifebar_def_candidates(search_root):
    defs = []
    for root, _, files in os.walk(search_root):
        for file_name in files:
            if file_name.lower().endswith('.def'):
                defs.append(os.path.join(root, file_name))
    scored = sorted(defs, key=lambda path: (-score_lifebar_def(path), path.lower()))
    filtered = [path for path in scored if score_lifebar_def(path) > 0]
    return filtered or scored


def pick_lifebar_main_def(package_root):
    meta = read_lifebar_meta(package_root)
    main_def = normalize_rel_path(meta.get('main_def', ''))
    if main_def and os.path.isfile(os.path.join(package_root, main_def)):
        return main_def
    candidates = find_lifebar_def_candidates(package_root)
    if not candidates:
        return None
    return os.path.relpath(candidates[0], package_root).replace('\\', '/')


def build_lifebar_metadata(package_root, main_def_rel=None):
    existing = read_lifebar_meta(package_root)
    main_def_rel = normalize_rel_path(main_def_rel or existing.get('main_def') or pick_lifebar_main_def(package_root) or '')
    title = os.path.basename(package_root)
    author = ''
    if main_def_rel:
        info = read_def_info(os.path.join(package_root, main_def_rel))
        title = normalize_text(info.get('name')) or title
        author = normalize_text(info.get('author'))
    meta = {
        **{k: v for k, v in existing.items() if k not in {'id', 'title', 'author', 'main_def', 'root'}},
        "id": os.path.basename(package_root),
        "title": title,
        "author": author,
        "main_def": main_def_rel,
        "root": relative_to_root(PROJECT_ROOT or package_root, package_root) if PROJECT_ROOT else package_root,
    }
    write_lifebar_meta(package_root, meta)
    return meta


def resolve_engine_asset_path(root, base_dir, ref_path):
    rel = normalize_rel_path(ref_path)
    if not rel:
        return None
    basename = os.path.basename(rel)
    candidates = [
        os.path.normpath(os.path.join(base_dir, rel)),
        os.path.normpath(os.path.join(root, rel)),
        os.path.normpath(os.path.join(root, 'data', rel)),
    ]
    if '/' not in rel:
        candidates.extend([
            os.path.normpath(os.path.join(root, basename)),
            os.path.normpath(os.path.join(root, 'data', basename)),
            os.path.normpath(os.path.join(root, 'font', basename)),
        ])
    else:
        candidates.append(os.path.normpath(os.path.join(root, 'font', rel)))
    seen = set()
    for candidate in candidates:
        norm = os.path.normcase(candidate)
        if norm in seen:
            continue
        seen.add(norm)
        if os.path.isfile(candidate):
            return candidate
    return None


def collect_lifebar_dependency_map(root, start_def_path):
    start_abs = os.path.abspath(start_def_path)
    queue = [(start_abs, os.path.basename(start_abs))]
    seen_defs = set()
    mapping = {}
    missing = []
    while queue:
        current_path, current_rel = queue.pop(0)
        current_key = os.path.normcase(current_path)
        if current_key in seen_defs:
            continue
        seen_defs.add(current_key)
        mapping.setdefault(current_rel, current_path)
        for ref in iter_def_asset_refs(current_path, LIFEBAR_ASSET_EXTS):
            src = resolve_engine_asset_path(root, os.path.dirname(current_path), ref)
            rel = lifebar_ref_to_rel_path(ref)
            if not rel:
                continue
            if not src:
                missing.append(ref)
                continue
            mapping.setdefault(rel, src)
            if src.lower().endswith('.def'):
                queue.append((src, rel))
    return mapping, sorted(set(missing))


def rewrite_def_refs(def_path, replacements):
    if not replacements:
        return False
    changed = False
    out_lines = []
    try:
        with open(def_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except:
        return False

    for raw_line in lines:
        newline = ''
        body = raw_line
        if raw_line.endswith('\r\n'):
            newline = '\r\n'
            body = raw_line[:-2]
        elif raw_line.endswith('\n'):
            newline = '\n'
            body = raw_line[:-1]
        comment = ''
        if ';' in body:
            body, comment = body.split(';', 1)
            comment = ';' + comment
        stripped = body.strip()
        if not stripped or '=' not in stripped:
            out_lines.append(raw_line)
            continue
        key, value = body.split('=', 1)
        current_value = value.strip().strip('"').strip("'")
        normalized = normalize_package_rel_path(current_value)
        replacement = replacements.get(normalized.casefold())
        if replacement and replacement != current_value:
            changed = True
            out_lines.append(f"{key.rstrip()} = {replacement}{comment}{newline}")
        else:
            out_lines.append(raw_line)

    if changed:
        with open(def_path, 'w', encoding='utf-8') as f:
            f.writelines(out_lines)
    return changed


def choose_font_destination(root, package_id, rel_from_font, src_path=None):
    font_root = os.path.join(root, 'font')
    rel_from_font = normalize_package_rel_path(rel_from_font)
    target = safe_join(font_root, rel_from_font)
    public_ref = f"font/{rel_from_font}"
    if not os.path.exists(target) or (src_path and os.path.isfile(src_path) and same_file_contents(src_path, target)):
        return target, public_ref
    if not src_path or not os.path.isfile(src_path):
        return target, public_ref

    base_dir = os.path.dirname(rel_from_font)
    base_name = os.path.basename(rel_from_font)
    name, ext = os.path.splitext(base_name)
    suffix_root = normalize_package_rel_path(os.path.join(package_id, base_dir, base_name))
    alt_rel = suffix_root
    counter = 2
    alt_target = safe_join(font_root, alt_rel)
    while os.path.exists(alt_target) and not same_file_contents(src_path, alt_target):
        alt_rel = normalize_package_rel_path(os.path.join(package_id, base_dir, f"{name}_{counter}{ext}"))
        alt_target = safe_join(font_root, alt_rel)
        counter += 1
    return alt_target, f"font/{alt_rel}"


def find_unique_path_by_basename(search_root, basename):
    matches = []
    wanted = os.path.basename(basename).lower()
    for root, _, files in os.walk(search_root):
        for file_name in files:
            if file_name.lower() == wanted:
                matches.append(os.path.join(root, file_name))
    if len(matches) == 1:
        return matches[0]
    return None


def resolve_lifebar_expected_ref(root, package_root, current_def_abs, ref_path, package_id, src_hint=None):
    normalized = normalize_package_rel_path(ref_path)
    if not normalized:
        return None, None
    font_root = os.path.join(root, 'font')
    current_dir = os.path.dirname(current_def_abs)
    current_in_font = path_is_within(font_root, current_def_abs)
    current_in_package = path_is_within(package_root, current_def_abs)

    if normalized.lower().startswith('font/'):
        rel_from_font = normalized.split('/', 1)[1] if '/' in normalized else os.path.basename(normalized)
        expected_abs, public_ref = choose_font_destination(root, package_id, rel_from_font, src_hint)
        return expected_abs, public_ref

    if current_in_font:
        expected_abs = os.path.normpath(os.path.join(current_dir, normalized))
        if not path_is_within(font_root, expected_abs):
            expected_abs = safe_join(font_root, normalized)
        public_ref = os.path.relpath(expected_abs, current_dir).replace('\\', '/')
        return expected_abs, public_ref

    if current_in_package:
        lower = normalized.lower()
        if lower.startswith('data/') or lower.startswith('lifebars/'):
            expected_abs = resolve_lifebar_package_destination(package_root, ref_path)
        else:
            expected_abs = os.path.normpath(os.path.join(current_dir, normalized))
        if not path_is_within(package_root, expected_abs):
            expected_abs = resolve_lifebar_package_destination(package_root, ref_path)
        if not expected_abs:
            return None, None
        public_ref = os.path.relpath(expected_abs, current_dir).replace('\\', '/')
        return expected_abs, public_ref

    return None, None


def find_lifebar_repair_source(root, package_root, current_def_abs, expected_abs, ref_path):
    normalized = normalize_package_rel_path(ref_path)
    basename = os.path.basename(normalized)
    if not basename:
        return None

    candidates = []
    resolved = resolve_engine_asset_path(root, os.path.dirname(current_def_abs), ref_path)
    if resolved:
        candidates.append(resolved)
    if os.path.isfile(expected_abs) and os.path.basename(expected_abs).lower() == basename.lower():
        candidates.append(expected_abs)

    package_guess = os.path.join(package_root, normalized)
    if os.path.isfile(package_guess):
        candidates.append(package_guess)

    font_guess = os.path.join(root, 'font', normalized.split('/', 1)[1] if normalized.lower().startswith('font/') and '/' in normalized else basename)
    if os.path.isfile(font_guess):
        candidates.append(font_guess)

    if os.path.isfile(os.path.join(root, 'font', basename)):
        candidates.append(os.path.join(root, 'font', basename))

    data_guess = os.path.join(root, 'data', basename)
    if os.path.isfile(data_guess):
        candidates.append(data_guess)

    unique_in_package = find_unique_path_by_basename(package_root, basename)
    if unique_in_package:
        candidates.append(unique_in_package)

    seen = set()
    for candidate in candidates:
        norm = os.path.normcase(os.path.abspath(candidate))
        if norm in seen:
            continue
        seen.add(norm)
        if os.path.isfile(candidate):
            return candidate
    return None


def repair_lifebar_package(root, package_root, main_def_rel):
    package_root = os.path.abspath(package_root)
    main_def_abs = os.path.join(package_root, normalize_rel_path(main_def_rel))
    if not os.path.isfile(main_def_abs):
        return {"moved": 0, "rewritten_defs": 0, "missing": []}

    package_id = os.path.basename(package_root)
    moved_sources = []
    rewritten_defs = 0
    missing = set()
    queue = [main_def_abs]
    seen_defs = set()

    while queue:
        current_def_abs = os.path.abspath(queue.pop(0))
        current_key = os.path.normcase(current_def_abs)
        if current_key in seen_defs or not os.path.isfile(current_def_abs):
            continue
        seen_defs.add(current_key)

        replacements = {}
        for ref in iter_def_asset_refs(current_def_abs, LIFEBAR_ASSET_EXTS):
            src_hint = find_lifebar_repair_source(root, package_root, current_def_abs, current_def_abs, ref)
            expected_abs, public_ref = resolve_lifebar_expected_ref(root, package_root, current_def_abs, ref, package_id, src_hint=src_hint)
            if not expected_abs or not public_ref:
                missing.add(ref)
                continue

            if os.path.isfile(expected_abs) and src_hint and path_is_within(package_root, src_hint) and os.path.abspath(src_hint) != os.path.abspath(expected_abs):
                if same_file_contents(src_hint, expected_abs):
                    os.remove(src_hint)
                    moved_sources.append(src_hint)

            if not os.path.isfile(expected_abs):
                source_abs = find_lifebar_repair_source(root, package_root, current_def_abs, expected_abs, ref)
                if not source_abs:
                    missing.add(ref)
                    continue
                if os.path.abspath(source_abs) != os.path.abspath(expected_abs):
                    os.makedirs(os.path.dirname(expected_abs), exist_ok=True)
                    if os.path.exists(expected_abs):
                        if same_file_contents(source_abs, expected_abs):
                            if path_is_within(package_root, source_abs):
                                os.remove(source_abs)
                                moved_sources.append(source_abs)
                        else:
                            missing.add(ref)
                            continue
                    else:
                        if path_is_within(package_root, source_abs):
                            shutil.move(source_abs, expected_abs)
                            moved_sources.append(source_abs)
                        else:
                            shutil.copy2(source_abs, expected_abs)
                            moved_sources.append(expected_abs)

            original_norm = normalize_package_rel_path(ref)
            if public_ref != ref and public_ref != original_norm:
                replacements[original_norm.casefold()] = public_ref

            if expected_abs.lower().endswith('.def'):
                queue.append(expected_abs)

        if rewrite_def_refs(current_def_abs, replacements):
            rewritten_defs += 1

    cleanup_empty_dirs(moved_sources, package_root)
    return {
        "moved": len(moved_sources),
        "rewritten_defs": rewritten_defs,
        "missing": sorted(missing),
    }


def cleanup_empty_dirs(start_paths, stop_dir):
    stop_dir = os.path.abspath(stop_dir)
    for path in sorted({os.path.abspath(path) for path in start_paths}, key=len, reverse=True):
        current = os.path.dirname(path)
        while current.startswith(stop_dir) and current != stop_dir:
            try:
                if os.path.isdir(current) and not os.listdir(current):
                    os.rmdir(current)
                else:
                    break
            except:
                break
            current = os.path.dirname(current)


def sync_lifebar_missing_meta(package_root, meta, missing):
    target_missing = sorted(set(missing or []))
    current_missing = sorted(set(meta.get("missing", [])))
    if target_missing:
        meta["missing"] = target_missing
    else:
        meta.pop("missing", None)
    if target_missing != current_missing:
        write_lifebar_meta(package_root, meta)
    return meta


def materialize_lifebar_package(mapping, dest_root, move_root=None):
    os.makedirs(dest_root, exist_ok=True)
    moved_sources = []
    stats = {"copied": 0, "moved": 0}
    move_root_abs = os.path.abspath(move_root) if move_root else None
    for rel_path, src_path in mapping.items():
        if not os.path.isfile(src_path):
            continue
        dest_path = safe_join(dest_root, rel_path)
        if os.path.abspath(src_path) == os.path.abspath(dest_path):
            continue
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        if move_root_abs and path_is_within(move_root_abs, src_path):
            shutil.move(src_path, dest_path)
            moved_sources.append(src_path)
            stats["moved"] += 1
        else:
            shutil.copy2(src_path, dest_path)
            stats["copied"] += 1
    if moved_sources and move_root_abs:
        cleanup_empty_dirs(moved_sources, move_root_abs)
    return stats


def ensure_unique_dir(base_root, desired_name):
    desired = slugify_lifebar_name(desired_name, "lifebar")
    candidate = desired
    counter = 2
    while os.path.exists(os.path.join(base_root, candidate)):
        candidate = f"{desired}_{counter}"
        counter += 1
    return os.path.join(base_root, candidate)


def normalize_lifebar_package_from_defs(package_root):
    moved = []
    def_paths = []
    for root, _, files in os.walk(package_root):
        for file_name in files:
            if file_name.lower().endswith('.def'):
                def_paths.append(os.path.join(root, file_name))
    seen_refs = set()
    for def_path in def_paths:
        for ref in iter_def_asset_refs(def_path, LIFEBAR_ASSET_EXTS):
            ref_key = ref.lower()
            if ref_key in seen_refs:
                continue
            seen_refs.add(ref_key)
            dest_path = resolve_lifebar_package_destination(package_root, ref)
            if not dest_path or os.path.isfile(dest_path):
                continue
            src_path = find_package_source_by_basename(package_root, ref)
            if not src_path or os.path.normpath(src_path) == os.path.normpath(dest_path):
                continue
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            shutil.move(src_path, dest_path)
            moved.append({
                "source": os.path.relpath(src_path, package_root).replace('\\', '/'),
                "destination": os.path.relpath(dest_path, package_root).replace('\\', '/')
            })
    return moved


def migrate_active_lifebar(root):
    lifebars_root = ensure_lifebars_root(root)
    motif_path = get_active_motif_path(root)
    if not motif_path or not os.path.isfile(motif_path):
        return {"migrated": False, "error": "No se encontró el motif activo"}
    fight_ref = read_motif_files_value(motif_path, 'fight') or 'fight.def'
    fight_path = resolve_engine_asset_path(root, os.path.dirname(motif_path), fight_ref)
    if not fight_path or not os.path.isfile(fight_path):
        return {"migrated": False, "error": "No se encontró el fight.def activo"}
    if path_is_within(lifebars_root, fight_path):
        rel = os.path.relpath(fight_path, lifebars_root).replace('\\', '/')
        package_dir = os.path.join(lifebars_root, rel.split('/')[0])
        main_def = pick_lifebar_main_def(package_dir)
        repair = repair_lifebar_package(root, package_dir, main_def) if main_def else {"moved": 0, "rewritten_defs": 0, "missing": []}
        meta = build_lifebar_metadata(package_dir, main_def)
        meta = sync_lifebar_missing_meta(package_dir, meta, repair.get("missing", []))
        return {"migrated": False, "active": meta}

    source_root = os.path.dirname(fight_path)
    desired_name = os.path.basename(os.path.dirname(motif_path)) or os.path.splitext(os.path.basename(fight_path))[0]
    dest_root = ensure_unique_dir(lifebars_root, desired_name)
    mapping, missing = collect_lifebar_dependency_map(root, fight_path)
    stats = materialize_lifebar_package(mapping, dest_root, move_root=source_root)
    main_def_rel = os.path.basename(fight_path)
    repair = repair_lifebar_package(root, dest_root, main_def_rel)
    meta = build_lifebar_metadata(dest_root, main_def_rel)
    merged_missing = sorted(set(missing) | set(repair.get("missing", [])))
    meta = sync_lifebar_missing_meta(dest_root, meta, merged_missing)
    new_fight_abs = os.path.join(dest_root, main_def_rel)
    new_fight_ref = os.path.relpath(new_fight_abs, os.path.dirname(motif_path)).replace('\\', '/')
    write_motif_files_value(motif_path, 'fight', new_fight_ref)
    return {
        "migrated": True,
        "active": meta,
        "fight_ref": new_fight_ref,
        "stats": stats,
        "repair": repair,
        "missing": merged_missing,
    }


def list_lifebars(root):
    migration = migrate_active_lifebar(root)
    motif_path = get_active_motif_path(root)
    active_fight_ref = read_motif_files_value(motif_path, 'fight') or 'fight.def'
    active_fight_abs = resolve_engine_asset_path(root, os.path.dirname(motif_path), active_fight_ref)
    lifebars_root = ensure_lifebars_root(root)
    items = []
    if os.path.isdir(lifebars_root):
        for entry in sorted(os.scandir(lifebars_root), key=lambda item: item.name.lower()):
            if not entry.is_dir():
                continue
            main_def = pick_lifebar_main_def(entry.path)
            repair = repair_lifebar_package(root, entry.path, main_def) if main_def else {"moved": 0, "rewritten_defs": 0, "missing": []}
            meta = build_lifebar_metadata(entry.path, main_def)
            meta = sync_lifebar_missing_meta(entry.path, meta, repair.get("missing", []))
            main_def = meta.get("main_def", "")
            if not main_def:
                continue
            main_abs = os.path.join(entry.path, main_def)
            items.append({
                **meta,
                "path": relative_to_root(root, entry.path),
                "main_def_path": relative_to_root(root, main_abs),
                "active": bool(active_fight_abs and os.path.normcase(os.path.abspath(main_abs)) == os.path.normcase(os.path.abspath(active_fight_abs))),
                "repair": repair,
            })
    active_id = next((item["id"] for item in items if item.get("active")), "")
    return {
        "items": items,
        "active_id": active_id,
        "motif": {
            "ref": get_active_motif_ref(root),
            "path": relative_to_root(root, motif_path),
            "fight_ref": active_fight_ref,
        },
        "migration": migration,
    }


def activate_lifebar(root, lifebar_id):
    package_root = os.path.join(get_lifebars_root(root), lifebar_id)
    if not os.path.isdir(package_root):
        raise ValueError("Lifebar no encontrada")
    meta = build_lifebar_metadata(package_root)
    main_def = meta.get("main_def", "")
    if not main_def:
        raise ValueError("La lifebar no tiene un .def principal")
    motif_path = get_active_motif_path(root)
    fight_abs = os.path.join(package_root, main_def)
    fight_ref = os.path.relpath(fight_abs, os.path.dirname(motif_path)).replace('\\', '/')
    write_motif_files_value(motif_path, 'fight', fight_ref)
    return {
        "id": lifebar_id,
        "fight_ref": fight_ref,
        "title": meta.get("title", lifebar_id),
    }


def delete_lifebar(root, lifebar_id):
    lifebars_root = ensure_lifebars_root(root)
    package_root = os.path.abspath(os.path.join(lifebars_root, lifebar_id))
    if not path_is_within(lifebars_root, package_root) or not os.path.isdir(package_root):
        raise ValueError("Lifebar no encontrada")

    motif_path = get_active_motif_path(root)
    active_fight_ref = read_motif_files_value(motif_path, 'fight') or 'fight.def'
    active_fight_abs = resolve_engine_asset_path(root, os.path.dirname(motif_path), active_fight_ref)
    if active_fight_abs and path_is_within(package_root, active_fight_abs):
        raise ValueError("No puedes eliminar la lifebar activa. Activa otra primero.")

    meta = build_lifebar_metadata(package_root)
    title = meta.get("title", lifebar_id)
    shutil.rmtree(package_root)
    return {
        "id": lifebar_id,
        "title": title,
        "path": relative_to_root(root, package_root),
    }


def clean_lifebar_references(root, preferred_id=""):
    lifebars_root = ensure_lifebars_root(root)
    motif_path = get_active_motif_path(root)
    if not motif_path or not os.path.isfile(motif_path):
        raise ValueError("No se encontró el motif activo")

    active_fight_ref = read_motif_files_value(motif_path, 'fight') or 'fight.def'
    active_fight_abs = resolve_engine_asset_path(root, os.path.dirname(motif_path), active_fight_ref)
    valid_items = []
    repaired_packages = 0

    if os.path.isdir(lifebars_root):
        for entry in sorted(os.scandir(lifebars_root), key=lambda item: item.name.lower()):
            if not entry.is_dir():
                continue
            main_def = pick_lifebar_main_def(entry.path)
            if not main_def:
                continue
            repair = repair_lifebar_package(root, entry.path, main_def)
            meta = build_lifebar_metadata(entry.path, main_def)
            meta = sync_lifebar_missing_meta(entry.path, meta, repair.get("missing", []))
            main_def = meta.get("main_def", "")
            if not main_def:
                continue
            main_abs = os.path.join(entry.path, main_def)
            if not os.path.isfile(main_abs):
                continue
            repaired_packages += 1
            valid_items.append({
                "id": meta.get("id", entry.name),
                "title": meta.get("title", entry.name),
                "main_abs": os.path.abspath(main_abs),
                "path": relative_to_root(root, entry.path),
            })

    active_valid = bool(active_fight_abs and os.path.isfile(active_fight_abs) and any(
        os.path.normcase(item["main_abs"]) == os.path.normcase(os.path.abspath(active_fight_abs))
        for item in valid_items
    ))

    preferred_id = normalize_text(preferred_id)
    chosen = None
    if not active_valid and valid_items:
        if preferred_id:
            chosen = next((item for item in valid_items if item["id"] == preferred_id), None)
        if not chosen:
            chosen = valid_items[0]
        new_ref = os.path.relpath(chosen["main_abs"], os.path.dirname(motif_path)).replace('\\', '/')
        write_motif_files_value(motif_path, 'fight', new_ref)

    return {
        "active_valid": active_valid,
        "changed": bool(chosen),
        "active_before": active_fight_ref,
        "active_after": os.path.relpath(chosen["main_abs"], os.path.dirname(motif_path)).replace('\\', '/') if chosen else active_fight_ref,
        "activated_id": chosen["id"] if chosen else "",
        "activated_title": chosen["title"] if chosen else "",
        "available": len(valid_items),
        "repaired_packages": repaired_packages,
    }


def install_lifebar_zip(project_root, zip_name, zip_bytes):
    lifebars_root = ensure_lifebars_root(project_root)
    tmp_root = tempfile.mkdtemp(prefix='ikemen_lifebar_')
    wrapper = None
    try:
        with zipfile.ZipFile(io.BytesIO(zip_bytes), 'r') as zf:
            raw_paths = list_zip_file_paths(zf)
            if not raw_paths:
                raise ValueError("El ZIP no contiene archivos válidos")
            stripped_paths, wrapper = strip_single_wrapper(raw_paths)
            extract_root = tmp_root
            if wrapper is not None:
                copy_zip_entries(zf, extract_root, set(stripped_paths), strip_prefix=wrapper)
            else:
                copy_zip_entries(zf, extract_root, set(raw_paths))

        candidates = find_lifebar_def_candidates(extract_root)
        if not candidates:
            raise ValueError("No se encontró ningún fight.def o lifebar.def dentro del ZIP")
        main_def_abs = candidates[0]
        source_root = os.path.dirname(main_def_abs)
        source_name = os.path.basename(source_root)
        if os.path.normcase(os.path.abspath(source_root)) == os.path.normcase(os.path.abspath(tmp_root)):
            source_name = wrapper or zip_name
        folder_name = slugify_lifebar_name(source_name or zip_name, "lifebar")
        dest_root = ensure_unique_dir(lifebars_root, folder_name)
        shutil.copytree(source_root, dest_root)
        relocated = normalize_lifebar_package_from_defs(dest_root)
        main_def_rel = pick_lifebar_main_def(dest_root)
        repair = repair_lifebar_package(project_root, dest_root, main_def_rel)
        meta = build_lifebar_metadata(dest_root, main_def_rel)
        if repair.get("missing"):
            meta["missing"] = repair["missing"]
            write_lifebar_meta(dest_root, meta)
        return {
            "mode": "lifebar",
            "type": "lifebars",
            "name": meta["id"],
            "installed": [meta["id"]],
            "meta": meta,
            "relocated": relocated,
            "repair": repair,
        }
    finally:
        shutil.rmtree(tmp_root, ignore_errors=True)

# ─── .CMD → MOVELIST PARSER ─────────────────────────────────────────

DIR_MAP = {
    'UB': 'UB', 'UF': 'UF', 'DB': 'DB', 'DF': 'DF',
    'U': 'U',   'D': 'D',   'B': 'B',   'F': 'F',
}
BTN_MAP = {'a': 'A', 'b': 'B', 'c': 'C', 'x': 'X', 'y': 'Y', 'z': 'Z',
           'start': 'St', 'back': 'Bk'}
MOTION_MAP = {
    ('D', 'DF', 'F'): 'QCF',
    ('D', 'DB', 'B'): 'QCB',
    ('F', 'D', 'DF'): 'DP',
    ('B', 'D', 'DB'): 'RDP',
    ('B', 'DB', 'D', 'DF', 'F'): 'HCF',
    ('F', 'DF', 'D', 'DB', 'B'): 'HCB',
}
IMPORTANT_NAME_KEYWORDS = (
    'jutsu', 'special', 'super', 'ultimate', 'secret', 'ougi', 'art',
    'skill', 'technique', 'awakening', 'finisher'
)
TRIVIAL_NAME_PATTERNS = [
    re.compile(r'^(ff|bb|dash|run|walk|recovery|taunt)$', re.I),
    re.compile(r'^[abcxyzswd]$', re.I),
    re.compile(r'^(up|down|back|fwd|forward|air|jump|crouch|stand)[_-]?[abcxyz]$', re.I),
    re.compile(r'^(hold|release)[_-]?[abcxyzbdfu]+$', re.I),
]
AI_COMMAND_NAME_PATTERN = re.compile(r'^\s*ai(?:\d+|[\s_-]|$)', re.I)


def _is_ai_command_name(name):
    return bool(AI_COMMAND_NAME_PATTERN.match(str(name or '')))


def _parse_cmd_token(tok):
    tok = tok.strip()
    if not tok:
        return None
    hold = False
    release = False
    if tok.startswith('~'):
        hold = True
        tok = tok[1:]
    tok = re.sub(r'^\d+', '', tok)
    tok = tok.lstrip('>')
    if tok.startswith('/'):
        release = True
        tok = tok[1:]
    tok = tok.lstrip('$').strip()
    if not tok:
        return None
    upper = tok.upper()
    if upper in DIR_MAP:
        return {'kind': 'dir', 'value': DIR_MAP[upper], 'hold': hold, 'release': release}
    btn_parts = [part.strip().lower() for part in tok.split('+') if part.strip()]
    if btn_parts and all(part in BTN_MAP for part in btn_parts):
        label = '+'.join(BTN_MAP[part] for part in btn_parts)
        if release:
            label = 'Release ' + label
        elif hold:
            label = 'Hold ' + label
        return {'kind': 'btn', 'value': label, 'hold': hold, 'release': release}
    raw = tok.upper()
    if release:
        raw = 'Release ' + raw
    elif hold:
        raw = 'Hold ' + raw
    return {'kind': 'raw', 'value': raw, 'hold': hold, 'release': release}


def _format_dir_sequence(dir_tokens):
    if not dir_tokens:
        return ''
    if all(not token['hold'] and not token['release'] for token in dir_tokens):
        values = tuple(token['value'] for token in dir_tokens)
        if values in MOTION_MAP:
            return MOTION_MAP[values]
    parts = []
    for token in dir_tokens:
        value = token['value']
        if token['hold']:
            parts.append('Charge ' + value)
        elif token['release']:
            parts.append('Release ' + value)
        else:
            parts.append(value)
    return ', '.join(parts)


def _convert_token(tok):
    parsed = _parse_cmd_token(tok)
    if not parsed:
        return ''
    if parsed['kind'] == 'dir':
        return _format_dir_sequence([parsed])
    return parsed['value']


def cmd_to_human(cmd_str):
    """Convert a MUGEN .cmd command string to readable fighting notation."""
    if not cmd_str:
        return ''
    tokens = [_parse_cmd_token(t) for t in cmd_str.split(',')]
    tokens = [token for token in tokens if token]
    result = []
    dir_buffer = []
    for token in tokens:
        if token['kind'] == 'dir':
            dir_buffer.append(token)
            continue
        if dir_buffer:
            motion = _format_dir_sequence(dir_buffer)
            dir_buffer = []
            if token['kind'] == 'btn':
                result.append(f"{motion} + {token['value'].replace('Hold ', '')}")
                continue
            result.append(motion)
        result.append(token['value'])
    if dir_buffer:
        result.append(_format_dir_sequence(dir_buffer))
    text = ' , '.join(part for part in result if part)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def parse_cmd_file(cmd_path):
    """Parse a .cmd file and return list of (name, input_human, raw_command) tuples."""
    moves = []
    try:
        with open(cmd_path, 'r', encoding='utf-8', errors='replace') as f:
            raw = f.read()
    except:
        return moves

    current_name = None
    current_cmd  = None
    for line in raw.split('\n'):
        stripped = line.strip()
        # Strip comments
        ci = stripped.find(';')
        if ci >= 0:
            stripped = stripped[:ci].strip()
        if not stripped:
            continue
        if stripped.lower() == '[command]':
            # Save previous
            if current_name and current_cmd:
                moves.append((current_name, cmd_to_human(current_cmd), current_cmd))
            current_name = None
            current_cmd  = None
        elif stripped.lower().startswith('name') and '=' in stripped:
            val = stripped.split('=', 1)[1].strip().strip('"').strip("'")
            current_name = val
        elif stripped.lower().startswith('command') and '=' in stripped:
            val = stripped.split('=', 1)[1].strip()
            current_cmd = val
    # Last block
    if current_name and current_cmd:
        moves.append((current_name, cmd_to_human(current_cmd), current_cmd))
    return moves


def _command_metrics(raw_cmd):
    tokens = [_parse_cmd_token(t) for t in (raw_cmd or '').split(',')]
    tokens = [token for token in tokens if token]
    dir_count = sum(1 for token in tokens if token['kind'] == 'dir')
    btn_tokens = [token for token in tokens if token['kind'] == 'btn']
    button_count = 0
    multi_button = False
    for token in btn_tokens:
        button_count += len(token['value'].replace('Release ', '').replace('Hold ', '').split('+'))
        if '+' in token['value']:
            multi_button = True
    charge = any(token['kind'] == 'dir' and token['hold'] for token in tokens)
    return {
        'dir_count': dir_count,
        'button_count': button_count,
        'multi_button': multi_button,
        'charge': charge,
    }


def _is_trivial_move_name(name):
    clean = (name or '').strip()
    if not clean:
        return True
    if _is_ai_command_name(clean):
        return True
    for pattern in TRIVIAL_NAME_PATTERNS:
        if pattern.match(clean):
            return True
    return False


def _is_important_move(name, raw_cmd):
    if _is_trivial_move_name(name):
        return False
    metrics = _command_metrics(raw_cmd)
    lower_name = (name or '').lower()
    if any(keyword in lower_name for keyword in IMPORTANT_NAME_KEYWORDS):
        return True
    if metrics['charge'] and metrics['button_count'] >= 1:
        return True
    if metrics['dir_count'] >= 2 and metrics['button_count'] >= 1:
        return True
    if metrics['multi_button'] and metrics['button_count'] >= 2:
        return True
    return False


def _move_type(name, raw_cmd):
    metrics = _command_metrics(raw_cmd)
    lower_name = (name or '').lower()
    if any(keyword in lower_name for keyword in ('super', 'ultimate', 'secret', 'ougi', 'awakening', 'finisher')):
        return 'super'
    if metrics['dir_count'] >= 4 or metrics['multi_button']:
        return 'super'
    return 'special'


def generate_movelist_json(root, char_name):
    """Auto-generate movelist.json from a character's .cmd file."""
    chars_dir = os.path.join(root, 'chars', char_name)
    if not os.path.isdir(chars_dir):
        return None, 'Carpeta no encontrada: chars/' + char_name

    # Find .cmd file
    cmd_file = None
    def_file = None
    for f in os.listdir(chars_dir):
        fl = f.lower()
        if fl.endswith('.cmd') and not cmd_file:
            cmd_file = os.path.join(chars_dir, f)
        if fl.endswith('.def') and not def_file:
            def_file = os.path.join(chars_dir, f)

    # Try to get display name from .def
    display_name = char_name
    if def_file:
        try:
            with open(def_file, 'r', encoding='utf-8', errors='replace') as f:
                for line in f:
                    l = line.strip()
                    if l.lower().startswith('name') and '=' in l:
                        display_name = l.split('=', 1)[1].strip().strip('"').strip("'")
                        break
        except: pass

    if not cmd_file:
        return None, 'No se encontró archivo .cmd'

    raw_moves = parse_cmd_file(cmd_file)

    # Keep only commands that look like meaningful techniques.
    specials, supers = [], []
    seen = set()
    fallback_moves = []
    for name, inp, raw_cmd in raw_moves:
        if _is_ai_command_name(name):
            continue
        key = (name or '').strip().lower()
        if key in seen:
            continue
        seen.add(key)
        move = {'name': name, 'input': inp, 'type': _move_type(name, raw_cmd)}
        if _is_important_move(name, raw_cmd):
            if move['type'] == 'super':
                supers.append(move)
            else:
                specials.append(move)
        else:
            metrics = _command_metrics(raw_cmd)
            if not _is_trivial_move_name(name) and metrics['dir_count'] >= 1 and metrics['button_count'] >= 1:
                fallback_moves.append(move)

    sections = []
    if not specials and not supers and fallback_moves:
        specials = fallback_moves
    if specials: sections.append({'name': 'Especiales', 'moves': specials})
    if supers:   sections.append({'name': 'Supers',     'moves': supers})

    result = {
        'character': display_name,
        'charFolder': char_name,
        'version': '1.0',
        'generated': 'auto-important',
        'sections': sections,
    }
    return result, None


def sanitize_movelist_data(data):
    """Remove internal command entries that should never be shown in move lists."""
    if not isinstance(data, dict):
        data = {}
    result = dict(data)
    sections = []
    for section in data.get('sections') or []:
        if not isinstance(section, dict):
            continue
        moves = []
        for move in section.get('moves') or []:
            if isinstance(move, dict) and not _is_ai_command_name(move.get('name')):
                moves.append(move)
        if moves:
            clean_section = dict(section)
            clean_section['moves'] = moves
            sections.append(clean_section)
    result['sections'] = sections
    return result


def save_movelist(root, char_name, data):
    """Save movelist.json to moves/{charName}/movelist.json."""
    dest = os.path.join(root, 'moves', char_name)
    os.makedirs(dest, exist_ok=True)
    path = os.path.join(dest, 'movelist.json')
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(sanitize_movelist_data(data), f, indent=2, ensure_ascii=False)
    return path


def load_movelist(root, char_name):
    """Load movelist.json for a character."""
    path = os.path.join(root, 'moves', char_name, 'movelist.json')
    if not os.path.isfile(path):
        return None
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return sanitize_movelist_data(json.load(f))
    except:
        return None


class StoryEditorHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args): pass  # Silence console spam


    def end_json(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def end_bytes(self, payload, mime='application/octet-stream', cache_seconds=300):
        self.send_response(200)
        self.send_header('Content-type', mime)
        self.send_header('Content-Length', str(len(payload)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', f'public, max-age={cache_seconds}')
        self.end_headers()
        self.wfile.write(payload)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def _serve_static(self, rel_path):
        """Serve a static file from PROJECT_ROOT."""
        if not PROJECT_ROOT:
            self.send_response(404); self.end_headers(); return
        abs_path = os.path.normpath(os.path.join(PROJECT_ROOT, unquote(rel_path).lstrip('/')))
        # Security: must stay inside PROJECT_ROOT
        if not abs_path.startswith(os.path.normpath(PROJECT_ROOT)):
            self.send_response(403); self.end_headers(); return
        if not os.path.isfile(abs_path):
            self.send_response(404); self.end_headers(); return
        ext = os.path.splitext(abs_path)[1].lower()
        mime = {'.png':'image/png','.jpg':'image/jpeg','.jpeg':'image/jpeg',
                '.gif':'image/gif','.webp':'image/webp',
                '.ogg':'audio/ogg','.mp3':'audio/mpeg',
                '.sff':'application/octet-stream'}.get(ext,'application/octet-stream')
        self.send_response(200)
        self.send_header('Content-type', mime)
        self.send_header('Cache-Control', 'public, max-age=3600')
        self.end_headers()
        with open(abs_path, 'rb') as f:
            self.wfile.write(f.read())

    def do_GET(self):
        global PROJECT_ROOT
        parsed = urlparse(self.path)
        path = parsed.path
        # Serve static project assets
        STATIC_PREFIXES = ('/storymode/', '/stages/', '/chars/', '/lifebars/', '/font/', '/data/')
        if any(path.startswith(p) for p in STATIC_PREFIXES):
            return self._serve_static(path)
        if path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Expires', '0')
            self.end_headers()
            with open(os.path.join(EDITOR_DIR, 'index.html'), 'rb') as f: self.wfile.write(f.read())
        elif path == '/favicon.ico':
            self.send_response(200)
            self.send_header('Content-type', 'image/x-icon')
            self.send_header('Cache-Control', 'public, max-age=3600')
            self.end_headers()
            try:
                with open(os.path.join(EDITOR_DIR, 'favicon.ico'), 'rb') as f: self.wfile.write(f.read())
            except Exception: pass
        elif path == '/api/status':
            self.end_json({"root": PROJECT_ROOT})
        elif path == '/api/list_dir':
            qs = parse_qs(parsed.query)
            target = qs.get('path', ['~'])[0]
            if target == '~': target = os.path.expanduser('~')
            elif not os.path.isdir(target): target = os.path.expanduser('~')
            try:
                dirs = []
                if target == '/' and os.name == 'nt':
                    import string
                    dirs = [f"{d}:\\" for d in string.ascii_uppercase if os.path.exists(f"{d}:\\")]
                    target = parent = "Mi PC"
                else:
                    try:
                        for entry in os.scandir(target):
                            try:
                                if entry.is_dir() and not entry.name.startswith('.'): dirs.append(entry.name)
                            except: pass
                    except PermissionError: pass
                    dirs.sort()
                    parent = os.path.dirname(target) if target != os.path.dirname(target) else target
                self.end_json({"current": target, "parent": parent, "dirs": dirs})
            except Exception as e:
                self.end_json({"error": str(e), "current": target, "dirs": [], "parent": target})
        elif path == '/api/catalog':
            if not PROJECT_ROOT: return self.end_json({"error": "No root path"})
            try:
                cp = os.path.join(PROJECT_ROOT, "storymode", "catalog.json")
                self.end_json(json.load(open(cp, 'r', encoding='utf-8')) if os.path.isfile(cp) else [])
            except Exception as e: self.end_json({"error": str(e)})
        elif path == '/api/assets':
            if not PROJECT_ROOT: return self.end_json({"chars": [], "stages": []})
            self.end_json(self._parse_assets())
        elif path == '/api/chars':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                repair_roster_char_names_from_refs(PROJECT_ROOT)
                pd = parse_select_def_full(PROJECT_ROOT)
                roster = apply_editor_chars_meta(PROJECT_ROOT, pd["chars"])
                available = list_available_chars(PROJECT_ROOT)
                roster_refs = {
                    char_name_key(c.get("char_ref") or c.get("name"))
                    for c in roster
                    if c.get("kind") == "char" and normalize_text(c.get("char_ref") or c.get("name"))
                }
                unused = [c for c in available if char_name_key(c["name"]) not in roster_refs and c["name"] != "null"]
                self.end_json({"roster": roster, "stages": pd["stages"], "available": available, "unused": unused})
            except Exception as e: self.end_json({"error": traceback.format_exc()})
        elif path == '/api/chars/preview_source':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            qs = parse_qs(parsed.query)
            char_name = normalize_text(qs.get('char', [''])[0])
            char_ref = normalize_text(qs.get('ref', [''])[0])
            if not char_name:
                return self.end_json({"error": "char param required"})
            try:
                self.end_json(resolve_char_preview_source(PROJECT_ROOT, char_name, char_ref))
            except Exception:
                self.end_json({"error": traceback.format_exc()})
        elif path == '/api/chars/preview_idle':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            qs = parse_qs(parsed.query)
            char_name = normalize_text(qs.get('char', [''])[0])
            char_ref = normalize_text(qs.get('ref', [''])[0])
            if not char_name:
                return self.end_json({"error": "char param required"})
            try:
                preview = build_char_idle_preview(PROJECT_ROOT, char_name, char_ref)
                mugshot_url = ""
                try:
                    build_char_mugshot_preview(PROJECT_ROOT, char_name, char_ref)
                    mugshot_url = f"/api/chars/mugshot.png?char={quote(char_name)}"
                    if char_ref:
                        mugshot_url += f"&ref={quote(char_ref)}"
                except Exception:
                    mugshot_url = ""
                self.end_json({
                    "display_name": preview["display_name"],
                    "frame_count": preview["frame_count"],
                    "sff_version": preview["sff_version"],
                    "status": preview.get("status", "Action 0 · Idle"),
                    "mugshot_url": mugshot_url,
                    "image_url": (
                        f"/api/chars/preview_idle.png?char={quote(char_name)}"
                        + (f"&ref={quote(char_ref)}" if char_ref else "")
                    ),
                })
            except Exception:
                self.end_json({"error": traceback.format_exc()})
        elif path == '/api/chars/mugshot.png':
            if not PROJECT_ROOT:
                self.send_response(404); self.end_headers(); return
            qs = parse_qs(parsed.query)
            char_name = normalize_text(qs.get('char', [''])[0])
            char_ref = normalize_text(qs.get('ref', [''])[0])
            if not char_name:
                self.send_response(400); self.end_headers(); return
            try:
                preview = build_char_mugshot_preview(PROJECT_ROOT, char_name, char_ref)
                self.end_bytes(preview["image_bytes"], mime=preview["mime"], cache_seconds=300)
            except Exception:
                self.send_response(500)
                self.send_header('Content-type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(traceback.format_exc().encode('utf-8', errors='replace'))
        elif path == '/api/chars/preview_idle.png':
            if not PROJECT_ROOT:
                self.send_response(404); self.end_headers(); return
            qs = parse_qs(parsed.query)
            char_name = normalize_text(qs.get('char', [''])[0])
            char_ref = normalize_text(qs.get('ref', [''])[0])
            if not char_name:
                self.send_response(400); self.end_headers(); return
            try:
                preview = build_char_idle_preview(PROJECT_ROOT, char_name, char_ref)
                self.end_bytes(preview["image_bytes"], mime=preview["mime"], cache_seconds=300)
            except Exception:
                self.send_response(500)
                self.send_header('Content-type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(traceback.format_exc().encode('utf-8', errors='replace'))
        elif path == '/api/stages':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                pd = parse_select_def_full(PROJECT_ROOT)
                available = list_available_stages(PROJECT_ROOT)
                roster_names = set(pd["stages"])
                unused = [s for s in available if s["name"] not in roster_names]
                # Build name map: path → display name (from available + roster)
                name_map = {s["name"]: s["display"] for s in available}
                # Also resolve names for roster stages that may not be in available
                extra_names = resolve_stage_names(PROJECT_ROOT, [s for s in pd["stages"] if s not in name_map])
                name_map.update(extra_names)
                self.end_json({"roster": pd["stages"], "available": available, "unused": unused, "name_map": name_map})
            except Exception as e: self.end_json({"error": traceback.format_exc()})
        elif path == '/api/lifebars':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                self.end_json(list_lifebars(PROJECT_ROOT))
            except Exception as e:
                self.end_json({"error": traceback.format_exc()})
        elif path == '/api/storyboards':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                sb_dir = os.path.join(PROJECT_ROOT, "storymode", "storyboards")
                items = []
                if os.path.isdir(sb_dir):
                    for saga in sorted(os.listdir(sb_dir)):
                        saga_path = os.path.join(sb_dir, saga)
                        if not os.path.isdir(saga_path): continue
                        for f in sorted(os.listdir(saga_path)):
                            if not f.endswith('.def'): continue
                            def_path = os.path.join(saga_path, f)
                            rel = f"storymode/storyboards/{saga}/{f}"
                            # Read storyboard name & params
                            name = f.replace('.def', '')
                            spr = snd = ""
                            duration = 300
                            try:
                                with open(def_path, 'r', encoding='utf-8', errors='replace') as df:
                                    for line in df:
                                        ln = line.strip()
                                        if ln.lower().startswith('spr') and '=' in ln:
                                            spr = ln.split('=',1)[1].split(';')[0].strip()
                                        elif ln.lower().startswith('bgm') and '=' in ln and 'loop' not in ln.lower() and 'volume' not in ln.lower():
                                            snd = ln.split('=',1)[1].split(';')[0].strip()
                                        elif ln.lower().startswith('end.time') and '=' in ln:
                                            try: duration = int(ln.split('=',1)[1].split(';')[0].strip())
                                            except: pass
                            except: pass
                            items.append({"path": rel, "name": name, "saga": saga, "spr": spr, "snd": snd, "duration": duration})
                self.end_json({"storyboards": items})
            except Exception as e: self.end_json({"error": traceback.format_exc()})
        elif path.startswith('/api/storyboards/read'):
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            qs = parse_qs(parsed.query)
            rel_path = qs.get('path', [''])[0]
            abs_path = os.path.join(PROJECT_ROOT, rel_path)
            if os.path.isfile(abs_path):
                try:
                    with open(abs_path, 'r', encoding='utf-8') as f:
                        self.end_json({"content": f.read()})
                except Exception as e: self.end_json({"error": str(e)})
            else: self.end_json({"error": "File not found"})
        elif path == '/api/movelist/get':
            if not PROJECT_ROOT: return self.end_json({'error': 'No root'})
            qs = parse_qs(parsed.query)
            char_name = qs.get('char', [''])[0]
            if not char_name: return self.end_json({'error': 'char param required'})
            ml = load_movelist(PROJECT_ROOT, char_name)
            if ml: self.end_json({'movelist': ml})
            else:  self.end_json({'error': 'No movelist found for ' + char_name})
        elif path == '/api/movelist/generate':
            if not PROJECT_ROOT: return self.end_json({'error': 'No root'})
            qs = parse_qs(parsed.query)
            char_name = qs.get('char', [''])[0]
            if not char_name: return self.end_json({'error': 'char param required'})
            ml, err = generate_movelist_json(PROJECT_ROOT, char_name)
            if err:   self.end_json({'error': err})
            else:
                saved = save_movelist(PROJECT_ROOT, char_name, ml)
                self.end_json({'success': True, 'movelist': ml, 'saved': saved})
        elif path == '/api/movelist/list':
            if not PROJECT_ROOT: return self.end_json({'error': 'No root'})
            moves_dir = os.path.join(PROJECT_ROOT, 'moves')
            result = []
            if os.path.isdir(moves_dir):
                for name in sorted(os.listdir(moves_dir)):
                    ml_path = os.path.join(moves_dir, name, 'movelist.json')
                    if os.path.isfile(ml_path):
                        result.append(name)
            self.end_json({'chars': result})
        else:
            self.send_response(404); self.end_headers()


    def do_POST(self):
        global PROJECT_ROOT
        content_type = self.headers.get('Content-Type', '')

        # Handle multipart uploads
        if 'multipart/form-data' in content_type:
            return self._handle_upload()

        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length) if content_length > 0 else b'{}'
        data = json.loads(post_data.decode('utf-8')) if post_data else {}

        if self.path == '/api/set_root':
            try:
                target_path = data.get('path', '').strip()
                if os.path.isdir(target_path) and os.path.isdir(os.path.join(target_path, "data")):
                    PROJECT_ROOT = target_path
                    self.scaffold_project(target_path)
                    self.end_json({"success": True})
                else:
                    self.end_json({"success": False, "error": "Ruta inválida. Debe contener 'data/'. " + target_path})
            except Exception as e:
                self.end_json({"success": False, "error": traceback.format_exc()})
        elif self.path == '/api/catalog':
            if not PROJECT_ROOT: return self.end_json({"error": "No root path"})
            cp = os.path.join(PROJECT_ROOT, "storymode", "catalog.json")
            with open(cp, 'w', encoding='utf-8') as f: json.dump(data, f, indent=2)
            self.update_select_def_locks(data)
            self.end_json({"success": True})
        elif self.path == '/api/create_storyboard':
            if not PROJECT_ROOT: return self.end_json({"error": "No root path"})
            try:
                name = data.get('name', 'custom_intro')
                sff_path, snd_path = data.get('sff', ''), data.get('snd', '')
                dur, saga = data.get('duration', 300), data.get('saga', 'General')
                saga_dir = re.sub(r'[^a-zA-Z0-9_\-]', '_', saga.strip()) or 'General'
                sb_dir = os.path.join(PROJECT_ROOT, "storymode", "storyboards", saga_dir)
                os.makedirs(sb_dir, exist_ok=True)
                final_sff, final_snd = "", ""
                if sff_path:
                    abs_sff = os.path.join(PROJECT_ROOT, sff_path)
                    if os.path.isfile(abs_sff):
                        base_sff = os.path.basename(abs_sff)
                        dest_sff = os.path.join(sb_dir, base_sff)
                        if os.path.abspath(abs_sff) != os.path.abspath(dest_sff): shutil.move(abs_sff, dest_sff)
                        final_sff = base_sff
                if snd_path:
                    abs_snd = os.path.join(PROJECT_ROOT, snd_path)
                    if os.path.isfile(abs_snd):
                        base_snd = os.path.basename(abs_snd)
                        dest_snd = os.path.join(sb_dir, base_snd)
                        if os.path.abspath(abs_snd) != os.path.abspath(dest_snd): shutil.move(abs_snd, dest_snd)
                        final_snd = f"storymode/storyboards/{saga_dir}/{base_snd}"
                content = f"[SceneDef]\nspr = {final_sff}\n\n[Scene 0]\nfadein.time = 40\nfadein.col = 0,0,0\nfadeout.time = 40\nfadeout.col = 0,0,0\nclearcolor = 0,0,0\nbgm = {final_snd}\nbgm.loop = 0\nend.time = {dur}\n"
                with open(os.path.join(sb_dir, name + ".def"), 'w', encoding='utf-8') as f: f.write(content)
                self.end_json({"success": True})
            except Exception as e: self.end_json({"success": False, "error": str(e)})

        # ─── Character endpoints ─────────────────────────
        elif self.path == '/api/chars/save':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                existing = parse_select_def_full(PROJECT_ROOT)
                roster = normalize_char_roster(data.get("roster", []))
                write_select_def(PROJECT_ROOT, roster, data.get("stages", existing["stages"]), existing["options"])
                save_editor_chars_meta(PROJECT_ROOT, roster)
                self.end_json({"success": True})
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/chars/rename':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                old_name, new_name = normalize_text(data.get("old_name", "")), normalize_text(data.get("new_name", ""))
                rename_disk = data.get("rename_disk", False)
                if not old_name or not new_name: return self.end_json({"success": False, "error": "Nombre vacío"})
                if not rename_disk:
                    return self.end_json({
                        "success": False,
                        "error": "Renombrar solo el roster no es seguro para personajes: IKEMEN usa ese valor como ruta de carga. Activa 'Renombrar carpeta en disco'."
                    })
                target = resolve_char_rename_target(PROJECT_ROOT, old_name)
                old_keys = set(target["match_keys"])
                old_folder_name = sanitize_char_folder_name(target["folder_name"])
                if not old_keys:
                    old_keys = {char_name_key(old_name)}
                if rename_disk and not old_folder_name:
                    return self.end_json({"success": False, "error": f"No se pudo resolver la carpeta del personaje: {old_name}"})

                parsed = parse_select_def_full(PROJECT_ROOT)
                roster = apply_editor_chars_meta(PROJECT_ROOT, parsed["chars"])
                roster_renamed = 0
                for c in roster:
                    if c.get("kind") != "char":
                        continue
                    if char_name_key(c.get("name")) in old_keys or char_name_key(c.get("char_ref")) in old_keys:
                        c["name"] = new_name
                        if rename_disk:
                            c["char_ref"] = new_name
                        roster_renamed += 1

                disk_stats = {"char_dir_renamed": False, "move_dir_renamed": False, "def_renamed": False}
                if rename_disk:
                    safe_new_name = sanitize_char_folder_name(new_name)
                    if not safe_new_name:
                        return self.end_json({"success": False, "error": f"Nombre de carpeta inválido: {new_name}"})
                    chars_dir = os.path.join(PROJECT_ROOT, "chars")
                    old_path, new_path = os.path.join(chars_dir, old_folder_name), os.path.join(chars_dir, safe_new_name)
                    if not os.path.isdir(old_path):
                        return self.end_json({"success": False, "error": f"No existe la carpeta del personaje: chars/{old_folder_name}"})
                    if os.path.exists(new_path):
                        return self.end_json({"success": False, "error": f"Ya existe chars/{safe_new_name}"})

                    old_primary_def = find_primary_char_def(PROJECT_ROOT, old_folder_name)
                    if os.path.isdir(old_path):
                        os.rename(old_path, new_path)
                        disk_stats["char_dir_renamed"] = True

                    if old_primary_def:
                        old_primary_name = os.path.basename(old_primary_def)
                        old_primary_after_move = os.path.join(new_path, old_primary_name)
                        new_primary_after_move = os.path.join(new_path, safe_new_name + ".def")
                        if (
                            os.path.isfile(old_primary_after_move)
                            and os.path.abspath(old_primary_after_move) != os.path.abspath(new_primary_after_move)
                            and not os.path.exists(new_primary_after_move)
                        ):
                            os.rename(old_primary_after_move, new_primary_after_move)
                            disk_stats["def_renamed"] = True

                    old_moves = os.path.join(PROJECT_ROOT, "moves", old_folder_name)
                    new_moves = os.path.join(PROJECT_ROOT, "moves", safe_new_name)
                    if os.path.isdir(old_moves) and not os.path.exists(new_moves):
                        os.rename(old_moves, new_moves)
                        disk_stats["move_dir_renamed"] = True

                write_select_def(PROJECT_ROOT, roster, parsed["stages"], parsed["options"])
                save_editor_chars_meta(PROJECT_ROOT, roster)
                catalog_stats = rename_char_in_story_catalog(PROJECT_ROOT, old_keys, new_name) if rename_disk else {
                    "chapters_changed": 0, "p1_renamed": 0, "p2_renamed": 0
                }
                self.end_json({
                    "success": True,
                    "roster_renamed": roster_renamed,
                    "disk": disk_stats,
                    "catalog": catalog_stats,
                })
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/chars/get-displaynames':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                result = []
                chars_dir = os.path.join(PROJECT_ROOT, "chars")
                if os.path.isdir(chars_dir):
                    for folder in sorted(os.listdir(chars_dir)):
                        folder_path = os.path.join(chars_dir, folder)
                        if not os.path.isdir(folder_path):
                            continue
                        def_path = find_primary_char_def(PROJECT_ROOT, folder)
                        if not def_path:
                            continue
                        sections = parse_def_sections(def_path)
                        info = sections.get("info", {})
                        raw_name = strip_wrapping_quotes(info.get("name", ""))
                        raw_display = strip_wrapping_quotes(info.get("displayname", ""))
                        display = raw_display or raw_name
                        # Check if displayname looks wrong (doesn't match folder name)
                        folder_key = char_name_key(folder)
                        display_key = char_name_key(display)
                        name_key = char_name_key(raw_name)
                        mismatch = (
                            display_key != folder_key
                            and display_key != name_key
                        )
                        result.append({
                            "folder": folder,
                            "def_name": raw_name,
                            "def_displayname": raw_display,
                            "effective_displayname": display,
                            "mismatch": mismatch,
                            "def_path": os.path.basename(def_path),
                        })
                self.end_json({"success": True, "chars": result})
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/chars/fix-displaynames':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                fixes = data.get("fixes", [])
                if not isinstance(fixes, list):
                    return self.end_json({"success": False, "error": "fixes debe ser una lista"})
                fixed = 0
                errors = []
                for fix in fixes:
                    folder = normalize_text(fix.get("folder", ""))
                    new_displayname = normalize_text(fix.get("displayname", ""))
                    update_name = fix.get("update_name", False)
                    if not folder or not new_displayname:
                        continue
                    def_path = find_primary_char_def(PROJECT_ROOT, folder)
                    if not def_path:
                        errors.append(f"No se encontró .def para {folder}")
                        continue
                    try:
                        with open(def_path, 'r', encoding='utf-8', errors='replace') as f:
                            lines = f.readlines()
                        new_lines = []
                        dn_found = False
                        name_found = False
                        in_info = False
                        for raw_line in lines:
                            stripped = raw_line.strip()
                            if stripped.startswith('[') and stripped.endswith(']'):
                                in_info = stripped[1:-1].strip().casefold() == 'info'
                            if in_info:
                                line_no_comment = raw_line.split(';', 1)[0]
                                if '=' in line_no_comment:
                                    key = line_no_comment.split('=', 1)[0].strip().casefold()
                                    if key == 'displayname':
                                        # Preserve original indentation/style
                                        prefix = raw_line[:raw_line.lower().index('displayname')]
                                        eol = '\r\n' if raw_line.endswith('\r\n') else '\n'
                                        new_lines.append(f'{prefix}displayname ="{new_displayname}"{eol}')
                                        dn_found = True
                                        continue
                                    if key == 'name' and update_name:
                                        prefix = raw_line[:raw_line.lower().index('name')]
                                        eol = '\r\n' if raw_line.endswith('\r\n') else '\n'
                                        new_lines.append(f'{prefix}name ="{new_displayname}"{eol}')
                                        name_found = True
                                        continue
                            new_lines.append(raw_line)
                        # If displayname was never found, add it after [Info]
                        if not dn_found:
                            final_lines = []
                            for raw_line in new_lines:
                                final_lines.append(raw_line)
                                stripped = raw_line.strip()
                                if stripped.casefold() == '[info]':
                                    eol = '\r\n' if raw_line.endswith('\r\n') else '\n'
                                    final_lines.append(f'displayname ="{new_displayname}"{eol}')
                            new_lines = final_lines
                        with open(def_path, 'w', encoding='utf-8') as f:
                            f.writelines(new_lines)
                        fixed += 1
                    except Exception as ex:
                        errors.append(f"{folder}: {str(ex)}")
                self.end_json({
                    "success": True,
                    "fixed": fixed,
                    "errors": errors,
                })
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/chars/delete':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                raw_names = data.get("names")
                if not isinstance(raw_names, list):
                    raw_names = [data.get("name", "")]
                names = collect_valid_char_names(raw_names)
                if not names:
                    return self.end_json({"success": False, "error": "No se recibieron personajes válidos"})

                remove_refs = data.get("remove_references", True)
                remove_files = data.get("remove_files", False)
                select_stats = remove_chars_from_select(PROJECT_ROOT, names)
                catalog_stats = remove_chars_from_story_catalog(PROJECT_ROOT, names) if remove_refs else {
                    "chapters_changed": 0, "p1_removed": 0, "p2_removed": 0, "p2ai_trimmed": 0
                }
                disk_stats = delete_char_files(PROJECT_ROOT, names) if remove_files else {
                    "char_dirs_removed": 0, "move_dirs_removed": 0
                }
                message = (
                    f"{len(names)} personaje(s) eliminado(s). "
                    f"Roster: {select_stats['roster_removed']}, "
                    f"capítulos afectados: {catalog_stats['chapters_changed']}, "
                    f"carpetas chars/: {disk_stats['char_dirs_removed']}, "
                    f"moves/: {disk_stats['move_dirs_removed']}."
                )
                self.end_json({
                    "success": True,
                    "deleted": names,
                    "select": select_stats,
                    "catalog": catalog_stats,
                    "disk": disk_stats,
                    "message": message,
                })
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/chars/replace_missing_with_random':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                result = replace_missing_roster_chars_with_random(PROJECT_ROOT)
                message = (
                    f"{result['changed']} personaje(s) faltante(s) reemplazado(s) por randomselect."
                    if result["changed"] else
                    "No se encontraron personajes faltantes en el roster."
                )
                self.end_json({"success": True, **result, "message": message})
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        # ─── Movelist endpoints ──────────────────────────
        elif self.path == '/api/movelist/save':
            if not PROJECT_ROOT: return self.end_json({'error': 'No root'})
            try:
                char_name = data.get('char', '')
                ml_data   = data.get('movelist', {})
                if not char_name: return self.end_json({'success': False, 'error': 'char required'})
                saved = save_movelist(PROJECT_ROOT, char_name, ml_data)
                self.end_json({'success': True, 'saved': saved})
            except Exception as e: self.end_json({'success': False, 'error': str(e)})

        # ─── Stage endpoints ─────────────────────────────

        elif self.path == '/api/stages/save':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                existing = parse_select_def_full(PROJECT_ROOT)
                write_select_def(PROJECT_ROOT, existing["chars"], data.get("stages", []), existing["options"])
                self.end_json({"success": True})
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/stages/delete':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                raw_names = data.get("names")
                if not isinstance(raw_names, list):
                    raw_names = [data.get("name", "")]
                names = collect_valid_stage_names(raw_names)
                if not names:
                    return self.end_json({"success": False, "error": "No se recibieron stages válidos"})

                remove_refs = data.get("remove_references", True)
                remove_files = data.get("remove_files", False)
                select_stats = remove_stages_from_select(PROJECT_ROOT, names)
                catalog_stats = remove_stages_from_story_catalog(PROJECT_ROOT, names) if remove_refs else {
                    "chapters_changed": 0
                }
                disk_stats = delete_stage_files(PROJECT_ROOT, names) if remove_files else {
                    "defs_removed": 0, "asset_files_removed": 0, "dirs_removed": 0
                }
                message = (
                    f"{len(names)} stage(s) eliminado(s). "
                    f"ExtraStages: {select_stats['stages_removed']}, "
                    f"chars con stage limpiado: {select_stats['char_stage_refs_cleared']}, "
                    f"capítulos afectados: {catalog_stats['chapters_changed']}, "
                    f"defs borrados: {disk_stats['defs_removed']}, "
                    f"assets: {disk_stats['asset_files_removed']}, "
                    f"carpetas: {disk_stats['dirs_removed']}."
                )
                self.end_json({
                    "success": True,
                    "deleted": names,
                    "select": select_stats,
                    "catalog": catalog_stats,
                    "disk": disk_stats,
                    "message": message,
                })
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/stages/clean_missing':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                result = clean_missing_stage_references(PROJECT_ROOT)
                total = result["removed_stage_refs"] + result["cleared_char_stage_refs"] + result["chapters_changed"]
                message = (
                    f"Limpieza lista. ExtraStages removidos: {result['removed_stage_refs']}, "
                    f"chars limpiados: {result['cleared_char_stage_refs']}, "
                    f"capítulos a random: {result['chapters_changed']}."
                    if total else
                    "No se encontraron referencias rotas de stages."
                )
                self.end_json({"success": True, **result, "message": message})
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/lifebars/activate':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                lifebar_id = normalize_text(data.get("id", ""))
                if not lifebar_id:
                    return self.end_json({"success": False, "error": "Falta el ID de la lifebar"})
                result = activate_lifebar(PROJECT_ROOT, lifebar_id)
                self.end_json({"success": True, **result})
            except Exception as e:
                self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/lifebars/delete':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                lifebar_id = normalize_text(data.get("id", ""))
                if not lifebar_id:
                    return self.end_json({"success": False, "error": "Falta el ID de la lifebar"})
                result = delete_lifebar(PROJECT_ROOT, lifebar_id)
                self.end_json({
                    "success": True,
                    **result,
                    "message": f"Lifebar eliminada: {result['title']}",
                })
            except Exception as e:
                self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/lifebars/clean_missing':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                preferred_id = normalize_text(data.get("preferred_id", ""))
                result = clean_lifebar_references(PROJECT_ROOT, preferred_id=preferred_id)
                message = (
                    f"Lifebar activa reparada: {result['activated_title'] or result['activated_id']}."
                    if result["changed"] else
                    "No se encontraron referencias rotas de lifebars."
                )
                self.end_json({"success": True, **result, "message": message})
            except Exception as e:
                self.end_json({"success": False, "error": traceback.format_exc()})

        else:
            self.send_response(404); self.end_headers()

    def _handle_upload(self):
        """Handle multipart file upload for ZIP chars/stages and storyboard assets."""
        if not PROJECT_ROOT: return self.end_json({"error": "No root"})
        try:
            content_type = self.headers['Content-Type']
            boundary = content_type.split('boundary=')[1].encode()
            content_length = int(self.headers['Content-Length'])
            body = self.rfile.read(content_length)

            parts = body.split(b'--' + boundary)
            file_data = None
            file_name = ""
            upload_type = "chars"
            saga = "General"

            for part in parts:
                if b'Content-Disposition' not in part: continue
                header_end = part.find(b'\r\n\r\n')
                if header_end < 0: continue
                headers = part[:header_end].decode('utf-8', errors='replace')
                payload = part[header_end + 4:]
                if payload.endswith(b'\r\n'): payload = payload[:-2]

                if 'name="file"' in headers or 'name="zipfile"' in headers:
                    fn_match = re.search(r'filename="([^"]*)"', headers)
                    if fn_match: file_name = fn_match.group(1)
                    file_data = payload
                elif 'name="type"' in headers:
                    upload_type = payload.decode().strip()
                elif 'name="saga"' in headers:
                    saga = payload.decode().strip()

            if not file_data or not file_name:
                return self.end_json({"success": False, "error": "No se recibió archivo"})

            # Storyboard asset upload (SFF, OGG, MP3)
            ext = os.path.splitext(file_name)[1].lower()
            if upload_type == "storyboard_asset" and ext in ('.sff', '.ogg', '.mp3'):
                saga_dir = saga.replace(" ", "_")
                sb_dir = os.path.join(PROJECT_ROOT, "storymode", "storyboards", saga_dir)
                os.makedirs(sb_dir, exist_ok=True)
                dest = os.path.join(sb_dir, file_name)
                with open(dest, 'wb') as f: f.write(file_data)
                rel = f"storymode/storyboards/{saga_dir}/{file_name}"
                return self.end_json({"success": True, "name": file_name, "path": rel, "type": "storyboard_asset"})

            # Archive upload for chars/stages/lifebars
            valid_exts = ('.zip', '.rar', '.7z')
            if not any(file_name.lower().endswith(e) for e in valid_exts):
                return self.end_json({"success": False, "error": "Formato no soportado. Usa .zip, .rar o .7z"})

            # Convert .rar/.7z to zip in memory
            if not file_name.lower().endswith('.zip'):
                file_name, file_data = convert_archive_to_zip_bytes(file_name, file_data)

            if upload_type == "lifebars":
                result = install_lifebar_zip(PROJECT_ROOT, file_name, file_data)
            else:
                result = install_upload_zip(PROJECT_ROOT, file_name, file_data, upload_type)
            result["success"] = True
            self.end_json(result)
        except Exception as e:
            self.end_json({"success": False, "error": traceback.format_exc()})

    def _parse_assets(self):
        chars, stages = [], []
        try:
            sp = get_select_def_path(PROJECT_ROOT)
            with open(sp, 'r', encoding='utf-8') as f: lines = f.readlines()
            mode = "chars"
            for line in lines:
                line = line.split(';')[0].strip()
                if not line: continue
                if line.startswith('['):
                    if '[Characters]' in line: mode = "chars"
                    elif '[ExtraStages]' in line: mode = "stages"
                    else: mode = "ignore"
                    continue
                if mode == "ignore": continue
                if mode == "chars":
                    if line in ('randomselect', '}') or line.startswith('slot='): continue
                    cd = line.split(',')[0].strip()
                    if cd and cd not in chars: chars.append(cd)
                elif mode == "stages":
                    sd = line.split(',')[0].strip()
                    if sd: stages.append(sd)
        except Exception as e: print("Error parsing select", e)
        try:
            for a in list_available_chars(PROJECT_ROOT):
                if a["name"] not in chars and a["name"] != "null":
                    chars.append(a["name"])
        except Exception as e: print("Error merging available chars", e)
        sb_dir = os.path.join(PROJECT_ROOT, "storymode", "storyboards")
        snd_dir = os.path.join(PROJECT_ROOT, "sound")
        sb_defs, sb_sffs, sb_sounds = [], [], []
        if os.path.isdir(sb_dir):
            for p, _, files in os.walk(sb_dir):
                for f in files:
                    rel = os.path.relpath(os.path.join(p, f), PROJECT_ROOT).replace('\\', '/')
                    if f.endswith('.def'): sb_defs.append(rel)
                    elif f.endswith('.sff'): sb_sffs.append(rel)
                    elif f.endswith(('.mp3', '.ogg')): sb_sounds.append(rel)
        if os.path.isdir(snd_dir):
            for p, _, files in os.walk(snd_dir):
                for f in files:
                    if f.endswith(('.mp3', '.ogg')): sb_sounds.append(os.path.relpath(os.path.join(p, f), PROJECT_ROOT).replace('\\', '/'))
        return {"chars": chars, "stages": stages, "storyboard_defs": sorted(sb_defs), "storyboard_sffs": sorted(sb_sffs), "storyboard_sounds": sorted(sb_sounds)}

    def update_select_def_locks(self, catalog):
        if not PROJECT_ROOT: return
        enemies = set()
        for arc in catalog:
            for ch in arc.get("chapters", []):
                for p2 in ch.get("p2", []): enemies.add(p2.split('/')[0])
        try:
            sp = get_select_def_path(PROJECT_ROOT)
            with open(sp, 'r', encoding='utf-8') as f: content = f.read()
            new_lines = []
            for line in content.split('\n'):
                tl = line.split(';')[0].strip()
                if tl and not tl.startswith('[') and tl != 'randomselect':
                    cb = tl.split(',')[0].strip()
                    if cb in enemies:
                        if 'dofile("storymode/common.lua")' not in line:
                            line += f', hidden=3, unlock=(dofile("storymode/common.lua")).isCharacterUnlocked("{cb}")'
                        else:
                            line = re.sub(r'(\bhidden\s*=\s*)[123]\b', r'\g<1>3', line)
                    else:
                        if 'hidden=' in line and 'storymode/common.lua' in line:
                            line = re.sub(r',?\s*hidden=[123]\s*,\s*unlock=\(dofile\("storymode/common\.lua"\)\)\.isCharacterUnlocked\("[^"]+"\)', '', line)
                new_lines.append(line)
            with open(sp, 'w', encoding='utf-8') as f: f.write('\n'.join(new_lines))
        except Exception as e: print("Failed to lock", e)

    def scaffold_project(self, root):
        sm_dir = os.path.join(root, "storymode")
        os.makedirs(os.path.join(root, "lifebars"), exist_ok=True)
        os.makedirs(os.path.join(sm_dir, "storyboards", "cutscenes"), exist_ok=True)
        cat_file = os.path.join(sm_dir, "catalog.json")
        if not os.path.isfile(cat_file):
            with open(cat_file, 'w', encoding='utf-8') as f: json.dump([], f, indent=2)
        catalog_lua = os.path.join(sm_dir, "catalog.lua")
        if not os.path.isfile(catalog_lua):
            with open(catalog_lua, 'w', encoding='utf-8') as f:
                f.write('local catalogStr = main.f_fileRead("storymode/catalog.json")\nif catalogStr == "" then return {} end\nlocal ok, decoded = pcall(function() return json.decode(catalogStr) end)\nif not ok then return {} end\nreturn decoded\n')
        main_lua = os.path.join(sm_dir, "main.lua")
        if not os.path.isfile(main_lua):
            with open(main_lua, 'w', encoding='utf-8') as f:
                f.write('-- Scaffolded main.lua\nlocal story = dofile("storymode/common.lua")\nlocal catalog = dofile("storymode/catalog.lua")\n')
        common_lua = os.path.join(sm_dir, "common.lua")
        if not os.path.isfile(common_lua):
            src = "/home/renzo/naruto-r36s/storymode/common.lua"
            if os.path.isfile(src): shutil.copy2(src, common_lua)
            else:
                with open(common_lua, 'w', encoding='utf-8') as f: f.write('-- common.lua placeholder\n')
        sel_def = get_select_def_path(root)
        try:
            with open(sel_def, 'r', encoding='utf-8') as f: content = f.read()
            if "storymode/main.lua" not in content:
                with open(sel_def, 'a', encoding='utf-8') as f:
                    f.write("\n\n[StoryMode]\nname = cronicas_ninja\ndisplayname = \"Historia\"\npath = storymode/main.lua\nunlock = true\n")
        except: pass


if __name__ == '__main__':
    try:
        server = HTTPServer(('127.0.0.1', 8080), StoryEditorHandler)
        print("Iniciando Story Editor...")
        print("Abre esta direccion en tu navegador: http://localhost:8080")
        server.serve_forever()
    except Exception as e: print("Error bindeando puerto 8080:", e)
