#!/usr/bin/env python3
"""Profile + Docker-sandbox indicator wrapper around yet-another-statusline (yas).

yas itself is left completely untouched. This wrapper runs yas's normal
``main()``, captures the rendered statusline, and splices up to two badges into
the model/effort row:

* an **AOE profile** glych (🧑‍💻 ``work`` / 🌳 ``personal``) -- shown on the host
  *and* inside a sandbox; and
* a **Docker** glyph (🐳) -- shown only when running inside a container/sandbox.

When both are present they sit side by side (``profile`` then ``docker``)
immediately left of the model/effort cluster.

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

import glob
import io
import json
import os
import re
import socket
import sys
from pathlib import Path

# Whale emoji (U+1F433). Full-colour, double-width -- reads noticeably bigger
# than a monochrome Nerd-Font PUA glyph. yas measures it as 2 columns
# (yas.render.text._is_wide: 0x1F300-0x1FAFF), matching how terminals render
# emoji-presentation glyphs, so the box stays aligned. Encoded as an escape so
# the bytes survive editor / diff round-trips.
DOCKER_GLYPH = '\U0001F433'
DOCKER_GLYPH_W = 2

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


def _resolve_yas_dir() -> str | None:
    """Locate the packaged ``yas`` (returns the dir to put on sys.path).

    The package-based yas lives under ``~/.claude/plugins`` (NOT under
    ``CLAUDE_CONFIG_DIR`` -- that may point at a profile that only carries an
    older, differently-structured copy). We collect every ``.../claude/yas``
    package across the cache + marketplace and pick the highest version, so the
    wrapper keeps working after a yas upgrade. An explicit ``YAS_DIR`` env var
    (pointing at the dir that *contains* the ``yas`` package) overrides all of it.
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
        return max(versioned, key=lambda t: t[0])[1]
    if marketplace:
        return str(Path(sorted(marketplace)[0]).parent)
    return None


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


def _inject(out: str, profile: str | None, in_docker: bool) -> str:
    """Splice the profile + docker badges left of the model/effort cluster.

    Builds an ordered badge list (profile first, then docker), then replaces the
    matching number of padding cells just before the cluster with ``glyph + ' '``
    per badge -- same visible width in, same out, so the layout is unchanged.
    No-ops (returns ``out`` unchanged) when there are no badges or the layout has
    too little padding to host them.
    """
    if not out:
        return out

    badges: list[tuple[str, int]] = []
    if profile in PROFILE_GLYPHS:
        badges.append(PROFILE_GLYPHS[profile])
    if in_docker:
        badges.append((DOCKER_GLYPH, DOCKER_GLYPH_W))
    if not badges:
        return out

    prefix = ''.join(f'{glyph} ' for glyph, _ in badges)
    cells  = sum(width + 1 for _, width in badges)
    rx = re.compile('( {' + str(cells) + ',})(' + _CLUSTER_CORE + ')')

    def _sub(m: re.Match[str]) -> str:
        pad, cluster = m.group(1), m.group(2)
        return f'{pad[:-cells]}{prefix}{cluster}'

    return rx.sub(_sub, out, count=1)


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
    try:
        info = json.loads(raw)
        if isinstance(info, dict) and isinstance(info.get('session_id'), str):
            session_id = info['session_id']
    except ValueError:
        pass

    real_stdout, saved_stdin = sys.stdout, sys.stdin
    buf = io.StringIO()
    sys.stdout, sys.stdin = buf, io.StringIO(raw)
    try:
        yas_main()  # renders the statusline into our buffer
    finally:
        sys.stdout, sys.stdin = real_stdout, saved_stdin

    out       = buf.getvalue()
    in_docker = _in_docker_sandbox()
    profile   = _resolve_profile(session_id)
    _debug(in_docker, profile, session_id)
    sys.stdout.write(_inject(out, profile, in_docker))


if __name__ == '__main__':
    main()
