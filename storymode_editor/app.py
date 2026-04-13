import os, json, re, shutil, zipfile, traceback
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

PROJECT_ROOT = None
EDITOR_CHARS_META = os.path.join("save", "editor_chars_meta.json")

def get_select_def_path(root_path):
    motif_path = "data/system.def"
    config_path = os.path.join(root_path, "save", "config.json")
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                cfg = json.load(f)
                if "Motif" in cfg and cfg["Motif"]:
                    motif_path = cfg["Motif"].replace('\\', '/')
        except: pass
    motif_full = os.path.join(root_path, motif_path)
    select_rel = "select.def"
    if os.path.exists(motif_full):
        try:
            with open(motif_full, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line.lower().startswith('select') and '=' in line:
                        select_rel = line.split('=', 1)[1].split(';')[0].strip().replace('\\', '/')
                        break
        except: pass
    if '/' not in select_rel:
        return os.path.normpath(os.path.join(os.path.dirname(motif_full), select_rel))
    return os.path.normpath(os.path.join(root_path, select_rel))

# ─── Select.def parsing ─────────────────────────────────────────────

def make_char_entry(name):
    return {
        "kind": "char",
        "name": name,
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

def get_editor_chars_meta_path(root):
    return os.path.join(root, EDITOR_CHARS_META)

def load_editor_chars_meta(root):
    mp = get_editor_chars_meta_path(root)
    if not os.path.isfile(mp):
        return {"slot_locks": []}
    try:
        with open(mp, 'r', encoding='utf-8') as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return {"slot_locks": []}
        if not isinstance(data.get("slot_locks"), list):
            data["slot_locks"] = []
        return data
    except:
        return {"slot_locks": []}

def apply_editor_chars_meta(root, roster):
    meta = load_editor_chars_meta(root)
    locks = meta.get("slot_locks", [])
    out = []
    for i, entry in enumerate(roster or []):
        item = dict(entry)
        item["slot_locked"] = bool(locks[i]) if i < len(locks) else bool(entry.get("slot_locked", False))
        out.append(item)
    return out

def save_editor_chars_meta(root, roster):
    mp = get_editor_chars_meta_path(root)
    os.makedirs(os.path.dirname(mp), exist_ok=True)
    data = {"slot_locks": [bool(entry.get("slot_locked", False)) for entry in roster or []]}
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
            entry["stage"] = str(raw.get("stage", "")).strip()
            entry["hidden"] = _to_int(raw.get("hidden"), 0)
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
            if key == "hidden": entry["hidden"] = int(val) if val.isdigit() else 0
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

def list_available_chars(root):
    chars_dir = os.path.join(root, "chars")
    available = []
    if not os.path.isdir(chars_dir): return available
    for entry in os.scandir(chars_dir):
        if entry.is_dir():
            has_def = any(f.endswith('.def') for f in os.listdir(entry.path) if os.path.isfile(os.path.join(entry.path, f)))
            available.append({"name": entry.name, "type": "folder", "has_def": has_def})
        elif entry.name.endswith('.zip'):
            available.append({"name": entry.name, "type": "zip", "has_def": True})
    available.sort(key=lambda x: x["name"].lower())
    return available

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

# ─── .CMD → MOVELIST PARSER ─────────────────────────────────────────

DIR_MAP = {
    'UB': '↖', 'UF': '↗', 'DB': '↙', 'DF': '↘',
    'U': '↑',  'D': '↓',  'B': '←',  'F': '→',
}
BTN_MAP = {'a': 'A', 'b': 'B', 'c': 'C', 'x': 'X', 'y': 'Y', 'z': 'Z',
           'start': 'St', 'back': 'Bk'}


def _convert_token(tok):
    """Convert a single .cmd token to a human-readable symbol."""
    tok = tok.strip()
    if not tok:
        return ''
    prefix = ''
    if tok.startswith('~'):
        prefix = 'Hold '
        tok = tok[1:]
    if tok.startswith('/'):
        prefix = 'rel '
        tok = tok[1:]
    upper = tok.upper()
    if upper in DIR_MAP:
        return prefix + DIR_MAP[upper]
    if tok.lower() in BTN_MAP:
        return '+' + BTN_MAP[tok.lower()]
    return prefix + tok


def cmd_to_human(cmd_str):
    """Convert a MUGEN .cmd command string to human-readable input notation."""
    if not cmd_str:
        return ''
    parts = [t.strip() for t in cmd_str.split(',')]
    tokens = [_convert_token(t) for t in parts if t.strip()]
    result = []
    for t in tokens:
        if t.startswith('+'):
            result.append(t)
        else:
            result.append(' ' + t if result else t)
    return ''.join(result).strip()


def parse_cmd_file(cmd_path):
    """Parse a .cmd file and return list of (name, input_human) tuples."""
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
                moves.append((current_name, cmd_to_human(current_cmd)))
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
        moves.append((current_name, cmd_to_human(current_cmd)))
    return moves


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

    # Group into sections: normal (single button), special (direction+button), super (3+ tokens)
    normals, specials, supers = [], [], []
    seen = set()
    for name, inp in raw_moves:
        if name in seen:
            continue
        seen.add(name)
        # Heuristic: count direction arrows
        arrows = sum(1 for ch in inp if ch in '↑↓←→↖↗↙↘')
        if arrows == 0:
            normals.append({'name': name, 'input': inp, 'type': 'normal'})
        elif arrows >= 4:
            supers.append({'name': name, 'input': inp, 'type': 'super'})
        else:
            specials.append({'name': name, 'input': inp, 'type': 'special'})

    sections = []
    if normals:  sections.append({'name': 'Normales',   'moves': normals})
    if specials: sections.append({'name': 'Especiales', 'moves': specials})
    if supers:   sections.append({'name': 'Supers',     'moves': supers})

    result = {
        'character': display_name,
        'charFolder': char_name,
        'version': '1.0',
        'generated': 'auto',
        'sections': sections,
    }
    return result, None


def save_movelist(root, char_name, data):
    """Save movelist.json to moves/{charName}/movelist.json."""
    dest = os.path.join(root, 'moves', char_name)
    os.makedirs(dest, exist_ok=True)
    path = os.path.join(dest, 'movelist.json')
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    return path


def load_movelist(root, char_name):
    """Load movelist.json for a character."""
    path = os.path.join(root, 'moves', char_name, 'movelist.json')
    if not os.path.isfile(path):
        return None
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
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
        abs_path = os.path.normpath(os.path.join(PROJECT_ROOT, rel_path.lstrip('/')))
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
        STATIC_PREFIXES = ('/storymode/', '/stages/', '/chars/', '/font/', '/data/')
        if any(path.startswith(p) for p in STATIC_PREFIXES):
            return self._serve_static(path)
        if path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            with open('index.html', 'rb') as f: self.wfile.write(f.read())
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
                pd = parse_select_def_full(PROJECT_ROOT)
                roster = apply_editor_chars_meta(PROJECT_ROOT, pd["chars"])
                available = list_available_chars(PROJECT_ROOT)
                roster_names = set(c["name"] for c in roster if c.get("kind") == "char")
                unused = [c for c in available if c["name"] not in roster_names and c["name"] != "null"]
                self.end_json({"roster": roster, "stages": pd["stages"], "available": available, "unused": unused})
            except Exception as e: self.end_json({"error": traceback.format_exc()})
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
                old_name, new_name = data.get("old_name", ""), data.get("new_name", "").strip()
                rename_disk = data.get("rename_disk", False)
                if not old_name or not new_name: return self.end_json({"success": False, "error": "Nombre vacío"})
                if rename_disk:
                    chars_dir = os.path.join(PROJECT_ROOT, "chars")
                    old_path, new_path = os.path.join(chars_dir, old_name), os.path.join(chars_dir, new_name)
                    if os.path.isdir(old_path):
                        os.rename(old_path, new_path)
                        old_def, new_def = os.path.join(new_path, old_name + ".def"), os.path.join(new_path, new_name + ".def")
                        if os.path.isfile(old_def): os.rename(old_def, new_def)
                parsed = parse_select_def_full(PROJECT_ROOT)
                for c in parsed["chars"]:
                    if c.get("kind") == "char" and c.get("name") == old_name:
                        c["name"] = new_name
                write_select_def(PROJECT_ROOT, parsed["chars"], parsed["stages"], parsed["options"])
                self.end_json({"success": True})
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

        elif self.path == '/api/chars/delete':
            if not PROJECT_ROOT: return self.end_json({"error": "No root"})
            try:
                parsed = parse_select_def_full(PROJECT_ROOT)
                roster = apply_editor_chars_meta(PROJECT_ROOT, parsed["chars"])
                parsed["chars"] = [c for c in roster if c.get("kind") != "char" or c["name"] != data.get("name", "")]
                write_select_def(PROJECT_ROOT, parsed["chars"], parsed["stages"], parsed["options"])
                save_editor_chars_meta(PROJECT_ROOT, parsed["chars"])
                if data.get("remove_files"):
                    cp = os.path.join(PROJECT_ROOT, "chars", data.get("name", ""))
                    if os.path.isdir(cp): shutil.rmtree(cp)
                self.end_json({"success": True})
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
                stage_name = data.get("name", "")
                parsed = parse_select_def_full(PROJECT_ROOT)
                parsed["stages"] = [s for s in parsed["stages"] if s != stage_name]
                write_select_def(PROJECT_ROOT, parsed["chars"], parsed["stages"], parsed["options"])
                self.end_json({"success": True})
            except Exception as e: self.end_json({"success": False, "error": traceback.format_exc()})

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

            # ZIP upload for chars/stages
            if not file_name.endswith('.zip'):
                return self.end_json({"success": False, "error": "Archivo ZIP no válido"})

            dest_dir = os.path.join(PROJECT_ROOT, "chars" if upload_type == "chars" else "stages")
            os.makedirs(dest_dir, exist_ok=True)

            tmp_zip = os.path.join(dest_dir, file_name)
            with open(tmp_zip, 'wb') as f: f.write(file_data)
            folder_name = extract_zip_to(tmp_zip, dest_dir)
            if os.path.isfile(tmp_zip): os.remove(tmp_zip)

            extracted_path = os.path.join(dest_dir, folder_name)
            has_def = False
            if os.path.isdir(extracted_path):
                for f in os.listdir(extracted_path):
                    if f.endswith('.def'): has_def = True; break

            self.end_json({"success": True, "name": folder_name, "has_def": has_def, "type": upload_type})
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
                            line += f', hidden=2, unlock=(dofile("storymode/common.lua")).isCharacterUnlocked("{cb}")'
                    else:
                        if 'hidden=2' in line and 'storymode/common.lua' in line:
                            line = re.sub(r',?\s*hidden=2\s*,\s*unlock=\(dofile\("storymode/common\.lua"\)\)\.isCharacterUnlocked\("[^"]+"\)', '', line)
                new_lines.append(line)
            with open(sp, 'w', encoding='utf-8') as f: f.write('\n'.join(new_lines))
        except Exception as e: print("Failed to lock", e)

    def scaffold_project(self, root):
        sm_dir = os.path.join(root, "storymode")
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
