#!/usr/bin/env bash
# Consumer: files loaded into context this session.
#
# "Which files entered the context" = tool_use calls that pull file content
# (Read / Edit / Write / MultiEdit / NotebookEdit). Preferred source: agentsview
# `session tool-calls <id>` (maintained parser over the JSONL). If agentsview is
# missing, falls back to a direct jq scrape of the transcript. @-mentions and
# CLAUDE.md show up in the `f` view.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

pane="$(ci_find_claude_pane)"
dir="$(ci_project_dir "$pane")"; [ -n "$dir" ] || dir="$PWD"
t="$(ci_transcript_for_dir "$dir")"
out="$(mktemp)"

# "<count>\t<file_path>" per file, sorted desc by count. Via agentsview.
ci_context_files_av() {
    local id="$1"
    agentsview session tool-calls "$id" --format json 2>/dev/null | jq -r '
        [ .tool_calls[]?
          | select(.category=="Read" or .category=="Edit" or .category=="Write"
                   or .category=="MultiEdit" or .category=="NotebookEdit")
          | (try (.input_json | fromjson) catch {}) as $in
          | ($in.file_path // $in.notebook_path)
          | select(. != null)
        ]
        | group_by(.) | map({f: .[0], n: length})
        | sort_by(-.n)
        | .[] | "\(.n)\t\(.f)"
    ' 2>/dev/null
}

# Fallback: direct jq scrape of the transcript.
ci_context_files_jq() {
    [ -n "$t" ] && [ -f "$t" ] || return 1
    jq -rs '
        [ .[] | .message.content? // empty
          | select(type=="array") | .[]
          | select(.type=="tool_use")
          | select(.name=="Read" or .name=="Edit" or .name=="Write"
                   or .name=="MultiEdit" or .name=="NotebookEdit")
          | (.input.file_path // .input.notebook_path)
          | select(. != null)
        ]
        | group_by(.) | map({f: .[0], n: length})
        | sort_by(-.n)
        | .[] | "\(.n)\t\(.f)"
    ' "$t" 2>/dev/null
}

{
    if ci_have_agentsview; then
        echo "═══ Archivos cargados al contexto (agentsview) ═══"
    else
        echo "═══ Archivos cargados al contexto (esta sesión) ═══"
    fi
    echo
    if [ -z "$t" ] || [ ! -f "$t" ]; then
        echo "No se encontró transcript para este cwd."
        echo "Buscado en: $CI_PROJECTS_DIR/$(ci_slug_for_dir "$dir")/"
    else
        echo "transcript: $t"
        echo
        if ci_have_agentsview; then
            ci_sync_session "$t"
            rows="$(ci_context_files_av "$(ci_session_id "$t")")"
        else
            rows="$(ci_context_files_jq)"
        fi
        if [ -z "$rows" ]; then
            echo "Sin archivos leídos/editados todavía en esta sesión."
        else
            # Misma lógica que el badge 📄src/total de la statusline: un archivo es
            # "fuente" si vive dentro de un repo git (cubre el repo actual y los
            # dirs /add-dir, que aparecen como repos extra); lo demás es "externo".
            # El popup no recibe added_dirs, así que la pertenencia a repo (.git
            # ancestro) es el equivalente robusto e independiente del payload.
            rowsf="$(mktemp)"
            printf '%s\n' "$rows" > "$rowsf"
            python3 - "$dir" "$rowsf" "$t" <<'PY'
import json, os, sys

proj = sys.argv[1] or ""
rows_path = sys.argv[2]
transcript = sys.argv[3] if len(sys.argv) > 3 else ""

def git_root(p):
    cur = os.path.abspath(p)
    if not os.path.isdir(cur):
        cur = os.path.dirname(cur)
    while True:
        if os.path.exists(os.path.join(cur, ".git")):
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            return None
        cur = parent

entries = []  # (count, path, repo_root|None)
with open(rows_path, encoding="utf-8", errors="ignore") as fh:
    for line in fh:
        n, _, path = line.rstrip("\n").partition("\t")
        if not path.strip():
            continue
        path = os.path.normpath(path)
        entries.append((int(n) if n.strip().isdigit() else 0, path, git_root(path)))

cur_repo = git_root(proj) if proj else None
groups, other = {}, []
for count, path, root in entries:
    bucket = other if root is None else groups.setdefault(root, [])
    bucket.append((count, path))

# Memory / CLAUDE.md files auto-loaded into context: `nested_memory` attachments
# in the transcript (CLAUDE.md hierarchy + rule files). Distinct category from
# the code reads above -- same split the statusline 🧠 badge uses. (MEMORY.md
# auto-memory is a system reminder, not nested_memory, so it isn't listed here.)
mem = set()
if transcript:
    try:
        with open(transcript, encoding="utf-8", errors="ignore") as fh:
            for line in fh:
                if '"nested_memory"' not in line:
                    continue
                try:
                    o = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(o, dict) or o.get("type") != "attachment":
                    continue
                a = o.get("attachment")
                if isinstance(a, dict) and a.get("type") == "nested_memory" \
                        and isinstance(a.get("path"), str) and a["path"]:
                    mem.add(os.path.normpath(a["path"]))
    except OSError:
        pass

total = len(entries)
ext   = len(other)
src   = total - ext
nrepos = len(groups)

print(f"— {src} fuente · {ext} externos · {total} cargados (total)"
      f"  ({nrepos} repo{'s' if nrepos != 1 else ''}, × = veces tocado, desc)")
if mem:
    print(f"  + {len(mem)} archivos de memoria / CLAUDE.md (auto-cargados)")
print()
print("  ¿Qué significa? (= el badge 📄fuente/total · 🧠memoria de la statusline)")
print("    fuente   · dentro de tu repo o dirs de trabajo (/add-dir) — tu código")
print("    externos · cargados al contexto pero FUERA de tus repos (config, /tmp…)")
print("    cargados · TODOS los archivos que entraron al contexto (fuente+externos)")
print("    memoria  · CLAUDE.md + reglas auto-inyectadas (no son lecturas tuyas)")
print()

# Repo actual primero, luego por nº de archivos desc, luego ruta.
for root in sorted(groups, key=lambda r: (r != cur_repo, -len(groups[r]), r)):
    files = sorted(groups[root], key=lambda t: (-t[0], t[1]))
    tag = " · repo actual" if root == cur_repo else ""
    print(f"▸ {root}{tag}  ({len(files)})")
    for count, path in files:
        print(f"    {count:>3}×  {os.path.relpath(path, root)}")
    print()

if other:
    other.sort(key=lambda t: (-t[0], t[1]))
    print(f"▸ Otros · fuera de repo  ({len(other)})")
    for count, path in other:
        print(f"    {count:>3}×  {path}")
    print()

if mem:
    home = os.path.expanduser("~")
    print(f"▸ Memoria / CLAUDE.md · auto-cargados  ({len(mem)})")
    for path in sorted(mem):
        disp = "~" + path[len(home):] if path.startswith(home + os.sep) else path
        print(f"         {disp}")
    print()
PY
            rm -f "$rowsf"
        fi
    fi
    echo
    echo "Nota: archivos = tool_use Read/Edit/Write/MultiEdit/NotebookEdit;"
    echo "memoria = attachments nested_memory (los realmente cargados esta sesión)."
    echo "La vista f muestra la jerarquía CLAUDE.md completa del disco · @-mentions: el chat."
} > "$out"
ci_popup_file "$out"
