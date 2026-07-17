#!/usr/bin/env python3
"""Profile + Docker-sandbox indicator wrapper around yet-another-statusline (yas).

yas itself is left completely untouched. This wrapper runs yas's normal
``main()``, captures the rendered statusline, and splices up to four badges
into the model/effort row:

* a **context-files** badge (📄``N`` or 📄``src/total``) -- distinct files pulled
  into context this session (agentsview ``show_context_files`` parity). ``src``
  counts only files under a working root -- the launch ``project_dir`` plus any
  ``/add-dir`` directory, each widened to its git repo root -- i.e. your source
  code; ``total`` counts every loaded file regardless of location, so it is
  exact even for reads outside any root. Renders ``src/total`` when they differ,
  else just ``N``. Suppressed when no files are loaded or via ``YAS_FILES=0``;
* a **memory-files** badge (🧠``N``) -- distinct memory / CLAUDE.md files
  auto-loaded into context (``nested_memory`` attachments), tracked separately
  so they don't skew the 📄 source/total figure. Same ``YAS_FILES=0`` opt-out;
* an **AOE profile** glych (🧑‍💻 ``work`` / 🌳 ``personal``) -- shown on the host
  *and* inside a sandbox; and
* a **Docker** glyph (🐳) -- shown only when running inside a container/sandbox.

When present they sit side by side (``files`` then ``memory`` then ``profile``
then ``docker``) immediately left of the model/effort cluster.

Profile resolution (``_resolve_profile``)
------------------------------------------
AOE does not inject the profile into the sandbox environment, so we derive it
from AOE's own state. Each AOE profile is a directory under
``~/.config/agent-of-empires/profiles/<name>/`` whose ``sessions.json`` lists the
sessions that belong to it. We read the Claude ``session_id`` off the statusline
stdin payload and match it against each session's ``agent_session_id`` (works on
host and in-sandbox); as a sandbox-native fallback we match the container
hostname against the stored ``sandbox_info.container_id`` prefix. Inside a
sandbox that ``profiles`` dir is made readable via an ``extra_volumes`` RO mount
at the *same* path, so the exact same resolution code runs in both places. If no
session matches we fall back to ``$AGENT_OF_EMPIRES_PROFILE`` and then the
``default_profile`` from ``config.toml`` -- which is what the host's main
(non-AOE) session shows.

Sandbox detection (``_in_docker_sandbox``) primarily uses the ``/.dockerenv``
marker that the Docker runtime creates inside every container, plus a few extra
fingerprints so podman / other OCI runtimes and bind-mount edge cases are still
caught. Set ``YAS_DOCKER_FORCE=1`` to force the docker glyph on (useful to
confirm the wrapper is actually the active statusline command), or
``YAS_DOCKER_DEBUG=1`` to write a one-line detection report to
``~/.claude/yas-docker-wrapper.log``.

The splice is width-neutral: it replaces exactly ``N`` padding cells immediately
before the cluster with ``N`` cells of badges (each emoji is rendered as a
double-width cell plus one separating space), so the box stays aligned. The
border/cluster SGRs are matched generically, so this works regardless of the
active theme.
"""
from __future__ import annotations

import io
import json
import os
import re
import socket
import sys
import tempfile
from pathlib import Path

# Whale emoji (U+1F433). Full-colour, double-width -- reads noticeably bigger
# than a monochrome Nerd-Font PUA glyph. yas measures it as 2 columns
# (yas.render.text._is_wide: 0x1F300-0x1FAFF), matching how terminals render
# emoji-presentation glyphs, so the box stays aligned. Encoded as an escape so
# the bytes survive editor / diff round-trips.
DOCKER_GLYPH = '\U0001F433'
DOCKER_GLYPH_W = 2

# Context-files badge: 📄 (U+1F4C4, page-facing-up) followed by the count of
# distinct files pulled into context this session. The emoji is double-width
# (yas range 0x1F300-0x1FAFF) and each appended digit is one cell, so a badge's
# display width is FILE_GLYPH_W + len(str(count)). The count mirrors agentsview's
# `show_context_files` definition exactly (see _context_file_count). Set
# YAS_FILES=0 to suppress the badge.
FILE_GLYPH = '\U0001F4C4'
FILE_GLYPH_W = 2
# tool_use names that pull file content into context (agentsview parity).
FILE_TOOLS = frozenset({'Read', 'Edit', 'Write', 'MultiEdit', 'NotebookEdit'})

# Memory-files badge: 🧠 (U+1F9E0, brain) + count of distinct memory files in
# context, defined to MATCH `/context`'s "Memory Files" section: the CLAUDE.md
# hierarchy (User/Project) plus the auto-memory MEMORY.md index (AutoMem). NOTE
# what is NOT memory here: the individual auto-memory ENTRY files
# (memory/<slug>.md) the recall skill reads -- `/context` puts those in "Messages"
# as ordinary reads, so they count as 📄, not 🧠. The CLAUDE.md hierarchy is folded
# into the system prompt (not logged as a transcript attachment in every session),
# so 🧠 is computed from DISK in _memory_files_on_disk(), unioned with any
# `nested_memory` attachments. Double-width emoji: width MEMORY_GLYPH_W + digits.
MEMORY_GLYPH = '\U0001F9E0'
MEMORY_GLYPH_W = 2
# Path classifiers for file-tool reads (used by _scan_transcript):
#   * _MEMORY_FILE_RX -> a memory file (CLAUDE.md / CLAUDE.local.md anywhere, or a
#     `memory/MEMORY.md` index) -> kept out of 📄 (it belongs to 🧠).
#   * _PLAN_PATH_RX   -> plan-mode files under a Claude config `plans/` dir; dropped
#     entirely (authored artifacts, not reads, must not inflate 📄).
# Everything else read via a file tool -- including auto-memory ENTRY files -- is a
# genuine 📄 read, matching `/context`'s "Messages" accounting.
_MEMORY_FILE_RX = re.compile(r'(?:^|/)CLAUDE(?:\.local)?\.md$|/memory/MEMORY\.md$')
_PLAN_PATH_RX   = re.compile(r'(?:/\.claude/|/claude-profiles/)(?:.*/)?plans/[^/]+$')

# Per-profile badges: (glyph, visible terminal width in cells). 🧑‍💻 (technologist
# / "person at computer") is a ZWJ sequence (U+1F9D1 U+200D U+1F4BB) but modern
# terminals render it as a single double-width cell, so its display width is 2.
# 🌳 (deciduous tree) is a single double-width codepoint. Anything else (unknown
# profile name) gets no badge.
_WORK_W = int(os.environ.get('YAS_PROFILE_WIDTH') or 2)
PROFILE_GLYPHS: dict[str, tuple[str, int]] = {
    'default':  ('\U0001F9D1\u200D\U0001F4BB', _WORK_W),  # person at computer (ZWJ) \u2014 work/Technosylva account (host ~/.claude)
    'personal': ('\U0001F333', 2),                        # 🌳 tree
}

# The model/effort cluster on the model row is right-anchored and starts with
# either the gradient "pill" left-cap (PILL_LEFT ▐, shown when a thinking-effort
# level is active) or the bare model glyph (GLYPH_MODEL 󰢹, no-effort form). A run
# of padding spaces always precedes it in the wide/medium layouts; we consume
# exactly as many of those cells as the badges occupy (each glyph + one
# separating space) so the splice is width-neutral and the other rows' borders
# stay aligned. SGRs are matched generically, so this is theme-independent.
_SGR         = r'(?:\x1b\[[0-9;]*m)+'
_PILL_LEFT   = '▐'            # PILL_LEFT ▐ (effort pill cap)
_GLYPH_MODEL = '\U000f08b9'   # GLYPH_MODEL 󰢹 (no-effort form)
_CLUSTER_CORE = _SGR + '(?:' + re.escape(_PILL_LEFT) + '|' + re.escape(_GLYPH_MODEL) + ')'


def _version_key(v: str) -> tuple[int, ...]:
    nums = tuple(int(x) for x in re.findall(r'\d+', v))
    return nums or (0,)


def _yas_dir_cache_path() -> str:
    return os.path.join(tempfile.gettempdir(), 'yas-wrapper-yasdir.json')


def _plugins_roots_sig(roots: set[Path]) -> list[list[object]]:
    """Cheap fingerprint of the plugin dirs the glob search would scan.

    A new/removed yas version changes the mtime of one of these directories
    (the versioned parent, or the marketplace dir itself), so comparing mtimes
    is enough to know whether a cached resolution is still valid -- without
    re-running the glob scan itself.
    """
    sig: list[list[object]] = []
    for root in sorted(roots, key=str):
        for rel in ('plugins/cache/yet-another-statusline/yas',
                    'plugins/marketplaces/yet-another-statusline/claude'):
            p = root / rel
            try:
                sig.append([str(p), p.stat().st_mtime])
            except OSError:
                sig.append([str(p), None])
    return sig


def _resolve_yas_dir() -> str | None:
    """Locate the packaged ``yas`` (returns the dir to put on sys.path).

    The package-based yas lives under ``~/.claude/plugins`` (NOT under
    ``CLAUDE_CONFIG_DIR`` -- that may point at a profile that only carries an
    older, differently-structured copy). We collect every ``.../claude/yas``
    package across the cache + marketplace and pick the highest version, so the
    wrapper keeps working after a yas upgrade. An explicit ``YAS_DIR`` env var
    (pointing at the dir that *contains* the ``yas`` package) overrides all of it.

    This runs once per statusline refresh *per active session* (``glob.glob``
    over the plugins tree on every call), which adds up with several sessions
    open at ``refreshInterval: 1``. The result is cached on disk, keyed by the
    mtimes of the dirs the scan would visit, so a cache hit (the overwhelmingly
    common case -- yas is upgraded rarely) skips the filesystem walk and the
    ``glob`` import entirely.
    """
    if os.environ.get('YAS_DIR'):
        cand = Path(os.environ['YAS_DIR'])
        if (cand / 'yas').is_dir():
            return str(cand)

    home  = Path(os.path.expanduser('~'))
    roots = {
        home / '.claude',
        Path(os.environ.get('CLAUDE_CONFIG_DIR', str(home / '.claude'))),
    }
    sig = _plugins_roots_sig(roots)

    cache_path = _yas_dir_cache_path()
    try:
        with open(cache_path, encoding='utf-8') as fh:
            cached = json.load(fh)
        if isinstance(cached, dict) and cached.get('sig') == sig:
            return cached.get('result')
    except (OSError, ValueError):
        pass

    import glob  # only needed on a cache miss

    versioned: list[tuple[tuple[int, ...], str]] = []
    marketplace: list[str] = []
    for root in roots:
        base = root / 'plugins'
        for pkg in glob.glob(str(base / 'cache/yet-another-statusline/yas/*/claude/yas')):
            m = re.search(r'/yas/([0-9][^/]*)/claude/yas$', pkg)
            if m:
                versioned.append((_version_key(m.group(1)), str(Path(pkg).parent)))
        marketplace += glob.glob(str(base / 'marketplaces/yet-another-statusline/claude/yas'))

    if versioned:
        result = max(versioned, key=lambda t: t[0])[1]
    elif marketplace:
        result = str(Path(sorted(marketplace)[0]).parent)
    else:
        result = None

    try:  # atomic write so overlapping refreshes can't read a half file
        tmp = f'{cache_path}.{os.getpid()}'
        with open(tmp, 'w', encoding='utf-8') as fh:
            json.dump({'sig': sig, 'result': result}, fh)
        os.replace(tmp, cache_path)
    except OSError:
        pass
    return result


def _in_docker_sandbox() -> bool:
    """True when running inside a Docker (or compatible) container/sandbox."""
    if os.environ.get('YAS_DOCKER_FORCE') == '1':
        return True
    # Definitive marker files dropped by the container runtime.
    if os.path.exists('/.dockerenv') or os.path.exists('/run/.containerenv'):
        return True
    # Generic hint set by podman / systemd-nspawn / many sandbox launchers.
    if os.environ.get('container'):
        return True
    # cgroup of *this* process. On a bare host this is the host slice (e.g.
    # ``0::/init.scope``) and matches nothing; inside a container it names the
    # runtime. mountinfo is intentionally not checked -- a host running Docker
    # has /var/lib/docker mounts that would false-positive.
    for proc_path in ('/proc/self/cgroup', '/proc/1/cgroup'):
        try:
            blob = Path(proc_path).read_text(errors='ignore')
        except OSError:
            continue
        if any(tok in blob for tok in ('docker', 'containerd', 'kubepods', '/lxc/', 'libpod')):
            return True
    return False


def _profiles_dirs() -> list[Path]:
    """Candidate ``agent-of-empires/profiles`` dirs, host or sandbox (same path)."""
    dirs: list[Path] = []
    xdg = os.environ.get('XDG_CONFIG_HOME')
    if xdg:
        dirs.append(Path(xdg) / 'agent-of-empires' / 'profiles')
    dirs.append(Path(os.path.expanduser('~')) / '.config' / 'agent-of-empires' / 'profiles')
    return dirs


def _default_profile() -> str | None:
    """The ``default_profile`` from AOE's ``config.toml`` (host fallback)."""
    for base in _profiles_dirs():
        try:
            txt = (base.parent / 'config.toml').read_text()
        except OSError:
            continue
        m = re.search(r'(?m)^\s*default_profile\s*=\s*"([^"]*)"', txt)
        if m and m.group(1):
            return m.group(1)
    return None


def _resolve_profile(session_id: str) -> str | None:
    """Resolve the AOE profile name for this session.

    Matches the Claude ``session_id`` against each profile's
    ``sessions.json[*].agent_session_id``; as a sandbox-native fallback matches
    the container hostname against ``sandbox_info.container_id``. Falls back to
    ``$AGENT_OF_EMPIRES_PROFILE`` then the config's ``default_profile``.
    """
    try:
        host = socket.gethostname()
    except OSError:
        host = ''

    seen: set[str] = set()
    for base in _profiles_dirs():
        key = str(base)
        if key in seen or not base.is_dir():
            continue
        seen.add(key)
        for sj in sorted(base.glob('*/sessions.json')):
            try:
                sessions = json.loads(sj.read_text())
            except (OSError, ValueError):
                continue
            if not isinstance(sessions, list):
                continue
            for s in sessions:
                if not isinstance(s, dict):
                    continue
                if session_id and s.get('agent_session_id') == session_id:
                    return sj.parent.name
                cid = (s.get('sandbox_info') or {}).get('container_id') or ''
                if host and len(host) >= 12 and cid.startswith(host):
                    return sj.parent.name

    prof = os.environ.get('AGENT_OF_EMPIRES_PROFILE')
    if prof:
        return prof
    # Host session that selected a profile via CLAUDE_CONFIG_DIR=.../claude-profiles/<name>
    # (the only signal a non-AOE `claude-personal`/`claude-work` run carries). AOE
    # host/sandbox sessions point CLAUDE_CONFIG_DIR at ~/.claude or /root/.claude
    # (basename "claude", parent not "claude-profiles"), so they're unaffected.
    ccd = os.environ.get('CLAUDE_CONFIG_DIR', '')
    if ccd and Path(ccd).parent.name == 'claude-profiles':
        return Path(ccd).name
    # Per-context HOME approach (side-by-side accounts): the active config dir
    # ($CLAUDE_CONFIG_DIR, else $HOME/.claude) symlinks INTO claude-profiles/<name>
    # — e.g. HOME=~/.aoe-homes/personal makes $HOME/.claude → claude-profiles/personal.
    # Resolve through symlinks and use the real dir's name if it's under
    # claude-profiles. (The `default` profile uses the real ~/.claude — parent is
    # the home dir, not claude-profiles — so it correctly falls through.)
    cfg = ccd or os.path.join(os.environ.get('HOME', ''), '.claude')
    try:
        real = Path(cfg).resolve()
        if real.parent.name == 'claude-profiles':
            return real.name
    except (OSError, RuntimeError):
        pass
    return _default_profile()


def _scan_cache_path(transcript_path: str) -> str:
    """Per-transcript cache file under the temp dir (keyed by the session id)."""
    name = os.path.basename(transcript_path) or 'unknown'
    return os.path.join(tempfile.gettempdir(), 'yas-ctxfiles', name + '.json')


def _scan_transcript(transcript_path: str) -> tuple[set[str], set[str]]:
    """Single pass over the transcript -> (code-file paths, memory-file paths).

    Combines what were two separate full reads (📄 file reads via FILE_TOOLS
    tool_use, and 🧠 nested_memory attachment paths) into ONE pass, and caches
    the result keyed by the transcript's byte size. JSONL transcripts are
    append-only, so an unchanged size means unchanged content: on a cache hit we
    skip reading the file entirely. That keeps the per-second statusline refresh
    near-free between turns even on multi-MB transcripts (a raw scan there costs
    ~100ms+). Mirrors agentsview's ``show_context_files`` definition. Paths are
    normalised so the repo-scoping test (see _repo_root) is reliable.
    """
    files: set[str] = set()
    mem: set[str] = set()
    if not transcript_path:
        return files, mem
    try:
        size = os.path.getsize(transcript_path)
    except OSError:
        return files, mem

    cache = _scan_cache_path(transcript_path)
    try:
        with open(cache, encoding='utf-8') as fh:
            c = json.load(fh)
        if isinstance(c, dict) and c.get('v') == 5 and c.get('size') == size:
            return set(c.get('files', [])), set(c.get('mem', []))
    except (OSError, ValueError):
        pass

    try:
        fh = open(transcript_path, encoding='utf-8', errors='ignore')
    except OSError:
        return files, mem
    with fh:
        for line in fh:
            tu = '"tool_use"' in line
            nm = '"nested_memory"' in line
            if not (tu or nm):
                continue
            try:
                obj = json.loads(line)
            except ValueError:
                continue
            if not isinstance(obj, dict):
                continue
            if tu:
                msg = obj.get('message')
                content = msg.get('content') if isinstance(msg, dict) else None
                if isinstance(content, list):
                    for c in content:
                        if isinstance(c, dict) and c.get('type') == 'tool_use' \
                                and c.get('name') in FILE_TOOLS:
                            inp = c.get('input')
                            if isinstance(inp, dict):
                                p = inp.get('file_path') or inp.get('notebook_path')
                                if isinstance(p, str) and p:
                                    np = os.path.normpath(p)
                                    if _MEMORY_FILE_RX.search(np):
                                        mem.add(np)        # CLAUDE.md / MEMORY.md -> 🧠
                                    elif not _PLAN_PATH_RX.search(np):
                                        files.add(np)      # genuine source read -> 📄
                                    # plan-mode artifacts: dropped (not a real read)
            if nm and obj.get('type') == 'attachment':
                a = obj.get('attachment')
                if isinstance(a, dict) and a.get('type') == 'nested_memory':
                    p = a.get('path')
                    if isinstance(p, str) and p:
                        mem.add(os.path.normpath(p))

    try:  # atomic write so overlapping refreshes can't read a half file
        os.makedirs(os.path.dirname(cache), exist_ok=True)
        tmp = f'{cache}.{os.getpid()}'
        with open(tmp, 'w', encoding='utf-8') as fh:
            json.dump({'v': 5, 'size': size, 'files': sorted(files), 'mem': sorted(mem)}, fh)
        os.replace(tmp, cache)
    except OSError:
        pass
    return files, mem


def _memory_files_on_disk(project_dir: str, transcript_path: str) -> set[str]:
    """Memory files Claude Code loads for this session, mirroring ``/context``'s
    "Memory Files" rows -- the bits that are NOT visible by scanning the transcript
    because they are folded into the system prompt rather than logged as
    ``nested_memory`` attachments:

      * User CLAUDE.md  -- ``$CLAUDE_CONFIG_DIR/CLAUDE.md`` and/or ``~/.claude/CLAUDE.md``
      * Project CLAUDE.md / CLAUDE.local.md -- walking up from ``project_dir``
      * AutoMem MEMORY.md -- the per-project auto-memory index that sits beside the
        transcript's project dir (``<transcript dir>/memory/MEMORY.md``)

    Paths are real-path'd so a profile symlink (e.g. a per-context config dir whose
    CLAUDE.md links into ``~/.claude``) collapses to one entry. Cheap stat calls,
    fine for the per-second refresh. Unioned with ``nested_memory`` in main().
    """
    found: set[str] = set()
    home = os.path.expanduser('~')
    for base in (os.environ.get('CLAUDE_CONFIG_DIR', ''), os.path.join(home, '.claude')):
        if base:
            u = os.path.join(base, 'CLAUDE.md')
            if os.path.isfile(u):
                found.add(os.path.realpath(u))
    cur = os.path.normpath(os.path.abspath(project_dir)) if project_dir else ''
    while cur:
        for name in ('CLAUDE.md', 'CLAUDE.local.md'):
            p = os.path.join(cur, name)
            if os.path.isfile(p):
                found.add(os.path.realpath(p))
        parent = os.path.dirname(cur)
        if parent == cur:
            break
        cur = parent
    if transcript_path:
        m = os.path.join(os.path.dirname(transcript_path), 'memory', 'MEMORY.md')
        if os.path.isfile(m):
            found.add(os.path.realpath(m))
    return found


def _repo_root(start: str) -> str | None:
    """Nearest ancestor of ``start`` that contains a ``.git`` entry, else None.

    This is the boundary for "my source code": files under it are repo files,
    files outside it (config under ~/.claude, scratch dirs, other repos) are not.
    Walks up by ``os.path.dirname`` and stops at the filesystem root, so it is a
    handful of cheap ``os.path.exists`` stats -- fine for the per-second refresh.
    """
    if not start:
        return None
    cur = os.path.normpath(os.path.abspath(start))
    while True:
        if os.path.exists(os.path.join(cur, '.git')):
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            return None
        cur = parent


def _under_root(path: str, root: str) -> bool:
    """True when ``path`` is ``root`` itself or lives somewhere beneath it."""
    return path == root or path.startswith(root + os.sep)


def _source_roots(project_dir: str, added_dirs: list[object]) -> list[str]:
    """Working roots that count as "my source code".

    The launch ``project_dir`` plus every ``/add-dir`` directory
    (``workspace.added_dirs`` in the statusline payload). Each is resolved to its
    enclosing git repo root when it sits inside one, else taken as-is, so a file
    loaded from any added directory is correctly counted as source -- not as an
    external read. Deduplicated, order-preserving.
    """
    roots: list[str] = []
    seen: set[str] = set()
    for d in [project_dir, *added_dirs]:
        if not isinstance(d, str) or not d:
            continue
        r = _repo_root(d) or os.path.normpath(os.path.abspath(d))
        if r not in seen:
            seen.add(r)
            roots.append(r)
    return roots


def _files_badge(src: int, total: int) -> tuple[str, int] | None:
    """Build the 📄 badge: source-file count, with ``/total`` when they differ.

    ``src`` is files under the repo root, ``total`` is every file in context.
    Shows ``📄N`` when all loaded files are source files (or no repo root was
    found, in which case the caller passes src==total), else ``📄src/total`` so
    the repo figure stays the headline while the overall load is still visible.
    Returns None (no badge) when nothing is loaded.
    """
    if total <= 0:
        return None
    label = str(src) if src == total else f'{src}/{total}'
    return (f'{FILE_GLYPH}{label}', FILE_GLYPH_W + len(label))


def _count_badge(glyph: str, glyph_w: int, n: int) -> tuple[str, int] | None:
    """Generic ``<glyph><n>`` badge; None when ``n`` is zero (so it's hidden)."""
    if n <= 0:
        return None
    return (f'{glyph}{n}', glyph_w + len(str(n)))


def _inject(out: str, profile: str | None, in_docker: bool,
            lead_badges: list[tuple[str, int]] | None = None) -> str:
    """Splice the profile + docker + lead badges left of the model cluster.

    Priority order (left to right): profile glyph, docker, then ``lead_badges``
    (🧠 memory, 📄 files). Identity/environment first so a narrow layout keeps the
    profile badge (e.g. the ``default`` account's 🧑‍💻) and drops the file/memory
    counts instead. Replaces padding cells just before the cluster with
    ``glyph + ' '`` per badge -- same visible width in, same out, so the layout is
    unchanged. When the padding run is too short for every badge it fits the
    highest-priority contiguous prefix rather than dropping the whole lot. No-ops
    when there are no badges or no padding run precedes the cluster.
    """
    if not out:
        return out

    badges: list[tuple[str, int]] = []
    if profile in PROFILE_GLYPHS:
        badges.append(PROFILE_GLYPHS[profile])
    if in_docker:
        badges.append((DOCKER_GLYPH, DOCKER_GLYPH_W))
    badges += list(lead_badges or [])
    if not badges:
        return out

    # Anchor on the padding run immediately before the model cluster, then fit
    # badges into whatever that run offers (each costs width + 1 separating cell).
    # A narrow layout therefore still shows the leading badges instead of dropping
    # all of them -- the previous all-or-nothing `{cells,}` match meant one cell
    # short hid even the profile/docker glyphs entirely.
    rx = re.compile('( +)(' + _CLUSTER_CORE + ')')
    m = rx.search(out)
    if not m:
        return out
    avail = len(m.group(1))

    chosen: list[tuple[str, int]] = []
    used = 0
    for glyph, width in badges:
        cost = width + 1
        if used + cost > avail:
            break
        chosen.append((glyph, width))
        used += cost
    if not chosen:
        return out

    prefix = ''.join(f'{glyph} ' for glyph, _ in chosen)

    def _sub(mm: re.Match[str]) -> str:
        pad, cluster = mm.group(1), mm.group(2)
        return f'{pad[:-used]}{prefix}{cluster}'

    return rx.sub(_sub, out, count=1)


def _session_facts_cache_path(session_id: str) -> str:
    return os.path.join(tempfile.gettempdir(), 'yas-session-facts', (session_id or 'unknown') + '.json')


def _session_facts(session_id: str) -> tuple[bool, str | None]:
    """(in_docker, profile) -- both fixed for the lifetime of a session.

    ``_resolve_profile`` globs every AOE profile's ``sessions.json`` and JSON-parses
    each one; ``_in_docker_sandbox`` reads ``/proc/self/cgroup``. Neither can change
    mid-session, but both ran on every statusline refresh (every second, per active
    session). Computed once on the first call for a given ``session_id`` -- i.e. at
    session start -- and cached to disk keyed by that id, so every later refresh this
    session just reads a few bytes back instead of redoing the filesystem work.
    """
    path = _session_facts_cache_path(session_id)
    if session_id:
        try:
            with open(path, encoding='utf-8') as fh:
                cached = json.load(fh)
            if isinstance(cached, dict) and 'in_docker' in cached:
                return bool(cached['in_docker']), cached.get('profile')
        except (OSError, ValueError):
            pass

    in_docker = _in_docker_sandbox()
    profile   = _resolve_profile(session_id)

    if session_id:
        try:  # atomic write so overlapping refreshes can't read a half file
            os.makedirs(os.path.dirname(path), exist_ok=True)
            tmp = f'{path}.{os.getpid()}'
            with open(tmp, 'w', encoding='utf-8') as fh:
                json.dump({'in_docker': in_docker, 'profile': profile}, fh)
            os.replace(tmp, path)
        except OSError:
            pass
    return in_docker, profile


def _debug(in_docker: bool, profile: str | None, session_id: str) -> None:
    if os.environ.get('YAS_DOCKER_DEBUG') != '1':
        return
    try:
        home = Path(os.path.expanduser('~'))
        log  = Path(os.environ.get('CLAUDE_CONFIG_DIR', str(home / '.claude'))) / 'yas-docker-wrapper.log'
        signals = {
            'force':              os.environ.get('YAS_DOCKER_FORCE') == '1',
            '/.dockerenv':        os.path.exists('/.dockerenv'),
            '/run/.containerenv': os.path.exists('/run/.containerenv'),
            'container_env':      bool(os.environ.get('container')),
        }
        log.write_text(
            f'in_docker={in_docker} profile={profile!r} '
            f'session_id={session_id!r} signals={signals}\n'
        )
    except OSError:
        pass


def main() -> None:
    yas_dir = _resolve_yas_dir()
    if yas_dir and yas_dir not in sys.path:
        sys.path.insert(0, yas_dir)
    from yas.app import main as yas_main  # imported after sys.path is set

    # Match yas: force UTF-8 on the real stdout so PUA / box / emoji glyphs encode.
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')

    # Read the statusline payload once, pull the Claude session_id off it, then
    # replay the identical bytes to yas (which does its own json.loads(stdin)).
    raw = sys.stdin.read()
    session_id = ''
    transcript_path = ''
    project_dir = ''
    added_dirs: list[object] = []
    try:
        info = json.loads(raw)
        if isinstance(info, dict):
            if isinstance(info.get('session_id'), str):
                session_id = info['session_id']
            if isinstance(info.get('transcript_path'), str):
                transcript_path = info['transcript_path']
            ws = info.get('workspace') if isinstance(info.get('workspace'), dict) else {}
            if isinstance(ws.get('project_dir'), str):
                project_dir = ws['project_dir']
            if not project_dir and isinstance(info.get('cwd'), str):
                project_dir = info['cwd']
            if isinstance(ws.get('added_dirs'), list):
                added_dirs = ws['added_dirs']
    except ValueError:
        pass

    real_stdout, saved_stdin = sys.stdout, sys.stdin
    buf = io.StringIO()
    sys.stdout, sys.stdin = buf, io.StringIO(raw)
    try:
        yas_main()  # renders the statusline into our buffer
    finally:
        sys.stdout, sys.stdin = real_stdout, saved_stdin

    out                 = buf.getvalue()
    in_docker, profile  = _session_facts(session_id)

    lead_badges: list[tuple[str, int]] = []
    if os.environ.get('YAS_FILES') != '0':
        files, mem_files = _scan_transcript(transcript_path)  # one cached pass
        # 🧠 memory files match /context's "Memory Files" = CLAUDE.md hierarchy +
        # AutoMem MEMORY.md. Most aren't transcript-visible (folded into the system
        # prompt), so union the on-disk set with any nested_memory attachments;
        # real-path everything so a symlinked profile CLAUDE.md collapses to one.
        mem = {os.path.realpath(p) for p in mem_files} | _memory_files_on_disk(project_dir, transcript_path)
        # 📄 source reads = every other file pulled in; subtract memory so the two
        # badges never double-count. `src` = reads under a working root (project
        # dir + /add-dir dirs, each widened to its git root); `total` = all reads.
        files = {os.path.realpath(f) for f in files} - mem
        total = len(files)
        roots = _source_roots(project_dir, added_dirs)
        src   = sum(1 for f in files if any(_under_root(f, r) for r in roots)) if roots else total
        # Order within the lead group: 🧠 memory before 📄 files.
        for badge in (_count_badge(MEMORY_GLYPH, MEMORY_GLYPH_W, len(mem)),
                      _files_badge(src, total)):
            if badge is not None:
                lead_badges.append(badge)

    _debug(in_docker, profile, session_id)
    sys.stdout.write(_inject(out, profile, in_docker, lead_badges))


if __name__ == '__main__':
    main()
