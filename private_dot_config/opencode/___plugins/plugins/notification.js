/**
 * OpenCode notification plugin
 *
 * Sends a desktop notification when a session becomes idle.
 * Includes an action button to focus the terminal that launched opencode.
 *
 * Uses Bun.spawnSync with gdbus to send the notification non-blockingly and
 * get the notification ID immediately. notify-send --action blocks until user
 * interaction, which is not suitable for an event handler.
 *
 * We use Bun.spawnSync (array form) instead of Bun shell template literals to
 * avoid shell parsing issues with multi-word session titles and special chars.
 *
 * Window focus: at plugin init we find the Hyprland window that hosts this
 * opencode process and store it once for all session.idle events.
 *
 * Two cases:
 *   - Direct (no $TMUX): walk ppid chain from process.pid upward until a pid
 *     matches a Hyprland client entry from `hyprctl clients -j`.
 *   - Inside tmux ($TMUX is set): the ppid chain leads to the tmux SERVER
 *     (parent = PID 1), never reaching the terminal emulator. The aoe tool
 *     architecture creates a HEADLESS tmux session — there is no "tmux client"
 *     in the list-clients sense. Instead, the viewing terminal (e.g. foot
 *     running as a pyprland scratchpad) attaches via `tmux attach-session -t
 *     <session_name>`. We find it by scanning each Hyprland window's child
 *     process tree (depth 2 via `pgrep -P`) for a process whose cmdline
 *     contains "tmux" and our session name.
 */

// ---------------------------------------------------------------------------
// File logger — redirects all debug output away from stdout so OpenCode does
// not inject log lines into the chat input area.
// ---------------------------------------------------------------------------
import { appendFileSync, mkdirSync } from "fs";

const _logDir = `${process.env.HOME}/.config/opencode/logs/notification`;
mkdirSync(_logDir, { recursive: true });

function _logDate() {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD
}
function log(...args) {
  const line = `[${new Date().toISOString()}] ${args.join(" ")}\n`;
  appendFileSync(`${_logDir}/${_logDate()}.log`, line);
}

// ---------------------------------------------------------------------------

/**
 * Build a pid→{address,windowClass} map from hyprctl clients.
 * Returns null if hyprctl fails or output is unparseable.
 *
 * @returns {Map<number, { address: string, windowClass: string }> | null}
 */
function buildHyprClientMap() {
  const clientsProc = Bun.spawnSync(["hyprctl", "clients", "-j"]);
  if (clientsProc.exitCode !== 0) return null;

  let clients;
  try {
    clients = JSON.parse(clientsProc.stdout.toString());
  } catch {
    return null;
  }

  /** @type {Map<number, { address: string, windowClass: string }>} */
  const pidToClient = new Map();
  for (const client of clients) {
    if (typeof client.pid === "number" && typeof client.address === "string") {
      pidToClient.set(client.pid, { address: client.address, windowClass: client.class ?? "" });
    }
  }
  return pidToClient;
}

/**
 * Walk ppid chain upward from startPid.
 * Returns the first entry found in pidToClient, or null.
 *
 * @param {number} startPid
 * @param {Map<number, { address: string, windowClass: string }>} pidToClient
 * @returns {{ address: string, windowClass: string } | null}
 */
function walkPpidToHyprClient(startPid, pidToClient) {
  let pid = startPid;
  const visited = new Set();

  while (pid > 1 && !visited.has(pid)) {
    visited.add(pid);

    if (pidToClient.has(pid)) {
      return pidToClient.get(pid);
    }

    const psProc = Bun.spawnSync(["ps", "-p", String(pid), "-o", "ppid="]);
    if (psProc.exitCode !== 0) break;

    const ppid = parseInt(psProc.stdout.toString().trim(), 10);
    if (!ppid || isNaN(ppid) || ppid === pid) break;

    pid = ppid;
  }

  return null;
}

/**
 * Read /proc/<pid>/cmdline and return it as a space-joined string, or "".
 *
 * @param {number} pid
 * @returns {string}
 */
function readCmdline(pid) {
  try {
    // cmdline fields are NUL-separated; replace NULs with spaces.
    return Bun.file(`/proc/${pid}/cmdline`).textSync().replace(/\0/g, " ").trim();
  } catch {
    return "";
  }
}

/**
 * Return the direct children of pid via `pgrep -P <pid>`.
 * Returns an array of pids (may be empty on error or no children).
 *
 * @param {number} pid
 * @returns {number[]}
 */
function getChildren(pid) {
  const proc = Bun.spawnSync(["pgrep", "-P", String(pid)]);
  if (proc.exitCode !== 0) return [];
  return proc.stdout
    .toString()
    .split("\n")
    .map((s) => parseInt(s.trim(), 10))
    .filter((n) => !isNaN(n) && n > 0);
}

/**
 * When running inside a headless tmux session ($TMUX is set), the ppid chain
 * from opencode leads to the tmux SERVER (parent = PID 1), never the terminal.
 *
 * The viewing terminal (e.g. a foot window acting as a pyprland scratchpad)
 * attaches to our session via:
 *   foot → aoe → tmux attach-session -t <session_name>
 *
 * We find it by scanning each Hyprland window pid's child tree (depth 2) for a
 * process whose cmdline contains "tmux" and our session name.
 *
 * Returns the matching { address, windowClass } entry, or null.
 *
 * @param {string} sessionName
 * @param {Map<number, { address: string, windowClass: string }>} pidToClient
 * @returns {{ address: string, windowClass: string } | null}
 */
function findWindowForTmuxSession(sessionName, pidToClient) {
  for (const [windowPid, clientInfo] of pidToClient) {
    const depth1 = getChildren(windowPid);
    for (const childPid of depth1) {
      // Check the child itself
      const childCmd = readCmdline(childPid);
      if (childCmd.includes("tmux") && childCmd.includes(sessionName)) {
        log(`[notification] tmux match at depth 1: pid=${childPid} cmd="${childCmd}"`);
        return clientInfo;
      }
      // Check grandchildren (depth 2)
      const depth2 = getChildren(childPid);
      for (const grandPid of depth2) {
        const grandCmd = readCmdline(grandPid);
        if (grandCmd.includes("tmux") && grandCmd.includes(sessionName)) {
          log(`[notification] tmux match at depth 2: pid=${grandPid} cmd="${grandCmd}"`);
          return clientInfo;
        }
      }
    }
  }
  return null;
}

/**
 * Find the Hyprland window that hosts this opencode process.
 * Returns { address, windowClass } or null.
 *
 * @returns {{ address: string, windowClass: string } | null}
 */
const _defaultFindTerminalWindowDeps = {
  tmuxEnv: process.env.TMUX,
  spawnSync: Bun.spawnSync,
};

export function findTerminalWindow(deps = _defaultFindTerminalWindowDeps) {
  const spawnSync = deps.spawnSync ?? Bun.spawnSync;
  const pidToClient = buildHyprClientMap();
  if (!pidToClient) return null;

  // Only trust `tmux display-message` if we are actually INSIDE a tmux session.
  // The $TMUX environment variable is set by the tmux client when it starts a
  // shell — it is NOT set in a plain terminal even if a tmux server is running.
  //
  // Without this guard, `tmux display-message` exits 0 and returns the last
  // active session name even from outside tmux, causing regular foot/ghostty
  // terminals to be misidentified as the aoe scratchpad.
  if (deps.tmuxEnv) {
    const sessionProc = spawnSync(["tmux", "display-message", "-p", "#{session_name}"]);
    if (sessionProc.exitCode === 0) {
      const sessionName = sessionProc.stdout.toString().trim();
      if (sessionName) {
        // The aoe tool runs opencode in a tmux session named aoe_<branch>_<hash>.
        // The viewing terminal (aoe-cwd foot window) is a pyprland scratchpad
        // with windowClass "aoe-cwd". Skip the window scan and return the known
        // windowClass directly so findPyprScratchpadName() can do its job.
        if (/^aoe_/.test(sessionName)) {
          log(`[notification] aoe session detected: "${sessionName}" → using aoe-cwd scratchpad directly`);
          return { address: null, windowClass: "aoe-cwd", tmuxSessionName: sessionName };
        }
        const result = findWindowForTmuxSession(sessionName, pidToClient);
        if (result) return result;
        log(`[notification] tmux session "${sessionName}" not found in any hyprland window's child tree`);
      }
    }
  }

  // Non-tmux (or tmux fallback): walk ppid chain from process.pid.
  return walkPpidToHyprClient(process.pid, pidToClient);
}

const PYPR_BIN = "/home/froa/.nix-profile/bin/pypr";

/**
 * Deduplication: OpenCode emits session.idle twice per idle in rapid succession
 * (~1ms apart). We suppress the second event for the same sessionID if it fires
 * within IDLE_DEDUP_MS of the first.
 *
 * @type {Map<string, number>}
 */
const lastIdleTime = new Map();
const IDLE_DEDUP_MS = 2000;

/**
 * If windowClass matches a pyprland scratchpad, return the scratchpad name.
 * Returns null if not a scratchpad or pypr is unavailable.
 *
 * @param {string} windowClass
 * @returns {string | null}
 */
function findPyprScratchpadName(windowClass) {
  if (!windowClass) return null;
  const pyprProc = Bun.spawnSync([PYPR_BIN, "dumpjson"]);
  if (pyprProc.exitCode !== 0) return null;

  let config;
  try {
    config = JSON.parse(pyprProc.stdout.toString());
  } catch {
    return null;
  }

  const scratchpads = config.scratchpads ?? {};
  for (const [name, info] of Object.entries(scratchpads)) {
    if (info.class === windowClass) {
      return name;
    }
  }
  return null;
}

/**
 * Default dependencies for isSessionFocused — use real system calls.
 */
const _defaultIsSessionFocusedDeps = {
  readFile: (path) => {
    try {
      return Bun.file(path).textSync();
    } catch {
      return null;
    }
  },
  hyprctlClients: () => {
    const proc = Bun.spawnSync(["hyprctl", "clients", "-j"]);
    if (proc.exitCode !== 0) return null;
    try {
      return JSON.parse(proc.stdout.toString());
    } catch {
      return null;
    }
  },
};

/**
 * Check if the session is focused (visible on screen).
 * 
 * Returns true if:
 *   - The hyprctl client for the window class is visible (not on special workspace)
 *   - AND the session ID matches the current aoe session (if provided)
 * 
 * @param {string | null} sessionID - The session ID from the idle event
 * @param {string | null} currentAoeSessionDir - The current aoe session's directory (from tmux)
 * @param {string | null} windowClass
 * @param {typeof _defaultIsSessionFocusedDeps} [deps]
 * @returns {boolean}
 */
export function isSessionFocused(sessionDirectory, currentAoeSessionDir, windowClass, deps = _defaultIsSessionFocusedDeps) {
  log(`[notification] isSessionFocused check: sessionDir=${sessionDirectory}, currentAoeDir=${currentAoeSessionDir}, class=${windowClass}`);
  
  if (!windowClass) {
    log(`[notification] isSessionFocused: false - null windowClass`);
    return false;
  }

  // Check hyprctl FIRST: find a client with matching class
  const clients = deps.hyprctlClients();
  log(`[notification] isSessionFocused: hyprctl returned ${clients?.length ?? 'null'} clients`);
  if (!clients) {
    log(`[notification] isSessionFocused: false - hyprctl failed`);
    return false;
  }

  const match = clients.find((c) => c.class === windowClass);
  log(`[notification] isSessionFocused: found client: ${match ? JSON.stringify({class: match.class, hidden: match.hidden, workspace: match.workspace?.name}) : 'none'}`);
  if (!match) {
    log(`[notification] isSessionFocused: false - no client with class ${windowClass}`);
    return false;
  }

  // In pyprland, scratchpads are on special workspaces when hidden (e.g., special:S-aoe)
  const workspaceName = match.workspace?.name ?? "";
  const isOnSpecialWorkspace = workspaceName.startsWith("special:");
  log(`[notification] isSessionFocused: workspace="${workspaceName}", isOnSpecial=${isOnSpecialWorkspace}`);
  
  if (isOnSpecialWorkspace) {
    log(`[notification] isSessionFocused: false - client is on special workspace (hidden)`);
    return false;
  }

  // Window is visible. Check if the session directory matches the current aoe session's directory.
  if (currentAoeSessionDir && sessionDirectory && currentAoeSessionDir === sessionDirectory) {
    log(`[notification] isSessionFocused: TRUE - session dir matches current aoe session`);
    return true;
  }

  // No directory match
  log(`[notification] isSessionFocused: false - directory mismatch`);
  return false;
}

export const NotificationPlugin = async ({ client }) => {
  // Walk the process tree once at init to find the terminal window.
  const terminalWindow = findTerminalWindow();
  const windowAddress = terminalWindow?.address ?? null;
  const windowClass = terminalWindow?.windowClass ?? null;
  const tmuxSessionName = terminalWindow?.tmuxSessionName ?? null;

  // Check if the terminal is a pyprland scratchpad — if so, we need `pypr show`
  // to make it visible, not just `hyprctl dispatch focuswindow`.
  const pyprScratchpadName = windowClass ? findPyprScratchpadName(windowClass) : null;

  if (pyprScratchpadName) {
    log(`[notification] terminal is pyprland scratchpad: ${pyprScratchpadName} (${windowClass})`);
  } else if (windowAddress) {
    log(`[notification] terminal window address: ${windowAddress}`);
  } else {
    log("[notification] could not determine terminal window address; focus action will be skipped");
  }

  return {
    event: async ({ event }) => {
      if (event.type !== "session.idle") return;

      // Log the pyprScratchpadName at event time for debugging
      log(`[notification] event: pyprScratchpadName=${pyprScratchpadName}, windowClass=${windowClass}`);

      const sessionID = event.properties.sessionID;

      // Deduplicate: OpenCode fires session.idle twice per idle (~1ms apart).
      // Suppress the second event for the same sessionID within IDLE_DEDUP_MS.
      const now = Date.now();
      const lastFired = lastIdleTime.get(sessionID) ?? 0;
      if (now - lastFired < IDLE_DEDUP_MS) {
        log(`[notification] suppressing duplicate session.idle for ${sessionID} (${now - lastFired}ms since last)`);
        return;
      }
      lastIdleTime.set(sessionID, now);

      // Only notify for sessions running in the aoe pyprland scratchpad
      // Re-check at runtime using the stored windowClass
      const runtimePyprName = windowClass ? findPyprScratchpadName(windowClass) : null;
      log(`[notification] runtime check: runtimePyprName=${runtimePyprName}, windowClass=${windowClass}`);
      if (!runtimePyprName || runtimePyprName !== "aoe") {
        log(`[notification] skipping notification: not in aoe scratchpad (runtimePyprName=${runtimePyprName})`);
        return;
      }

      // Fetch session title and directory
      let sessionTitle = "Session idle";
      let sessionDirectory = null;
      try {
        const resp = await client.session.get({ path: { id: sessionID } });
        if (resp?.data?.title) sessionTitle = resp.data.title;
        // directory can be an object {path: "..."} or a string - handle both
        const dir = resp?.data?.directory;
        if (dir) {
          sessionDirectory = typeof dir === "string" ? dir : dir?.path ?? null;
        }
        log(`[notification] session ${sessionID}: title="${sessionTitle}", dir="${sessionDirectory}"`);
      } catch {}

      // Get the session that's currently displayed in the aoe scratchpad
      // Read from temp file set by scratchpad-toggle.sh or aoe-nvim-cwd.sh
      let scratchpadProjectBranch = null;
      try {
        const sessionFile = Bun.file("/tmp/aoe_session_name");
        const cwdFile = Bun.file("/tmp/aoe_cwd_target");
        
        if (await sessionFile.exists()) {
          scratchpadProjectBranch = (await sessionFile.text()).trim();
        } else if (await cwdFile.exists()) {
          // Fallback: derive from CWD
          const cwd = (await cwdFile.text()).trim();
          const project = cwd.split("/").pop();
          const gitProc = Bun.spawnSync(["git", "-C", cwd, "branch", "--show-current"]);
          const branch = gitProc.exitCode === 0 ? gitProc.stdout.toString().trim().replace("/", "-") : "main";
          scratchpadProjectBranch = `${project}_${branch}`;
        }
        log(`[notification] scratchpad project_branch: ${scratchpadProjectBranch}`);
      } catch {}

      // Get session's project_branch from directory (not title, since titles can be custom)
      let sessionProjectBranch = null;
      if (sessionDirectory) {
        const project = sessionDirectory.split("/").pop();
        const gitProc = Bun.spawnSync(["git", "-C", sessionDirectory, "branch", "--show-current"]);
        const branch = gitProc.exitCode === 0 ? gitProc.stdout.toString().trim().replace("/", "-") : "main";
        sessionProjectBranch = `${project}_${branch}`;
      }
      log(`[notification] session project_branch: ${sessionProjectBranch}, dir: ${sessionDirectory}`);

      // Check if the aoe-cwd scratchpad is visible (not on special workspace)
      const hyprClients = (Bun.spawnSync(["hyprctl", "clients", "-j"]).stdout.toString());
      let scratchpadVisible = false;
      try {
        const clients = JSON.parse(hyprClients);
        const aoeClient = clients.find((c) => c.class === "aoe-cwd");
        if (aoeClient) {
          const workspaceName = aoeClient.workspace?.name ?? "";
          scratchpadVisible = !workspaceName.startsWith("special:");
          log(`[notification] scratchpad: visible=${scratchpadVisible}, workspace=${workspaceName}`);
        }
      } catch {}

      // If scratchpad is hidden → notify for all sessions
      // If scratchpad is visible → only notify for sessions NOT currently in the scratchpad
      if (!scratchpadVisible) {
        log(`[notification] scratchpad hidden → will notify`);
      } else {
        // Scratchpad is visible - compare project_branch derived from directories
        if (scratchpadProjectBranch && sessionProjectBranch && scratchpadProjectBranch === sessionProjectBranch) {
          log(`[notification] suppressing: same project_branch (${scratchpadProjectBranch})`);
          return;
        }
        // Different session → notify (it's running in the background)
        log(`[notification] scratchpad visible, different project_branch → will notify`);
      }

      // Track latest notification for "goto latest" keybinding
      try {
        if (sessionDirectory) {
          Bun.write("/tmp/aoe_latest_notif_cwd", sessionDirectory);
          if (sessionProjectBranch) {
            Bun.write("/tmp/aoe_latest_notif_session", sessionProjectBranch);
          }
          log(`[notification] tracked latest notification: ${sessionProjectBranch} (${sessionDirectory})`);
        }
      } catch {}

      // Send notification via gdbus - returns immediately with the notification
      // ID. notify-send --action blocks until user interaction.
      // gdbus args follow freedesktop.org Notifications spec:
      //   Notify(app_name, replaces_id, app_icon, summary, body,
      //          actions, hints, expire_timeout)
      const iconPath = process.env.OPENCODE_NOTIF_NO_ICON
        ? ""
        : new URL("opencode.png", import.meta.url).pathname;

      const notifProc = Bun.spawnSync([
        "gdbus", "call",
        "--session",
        "--dest", "org.freedesktop.Notifications",
        "--object-path", "/org/freedesktop/Notifications",
        "--method", "org.freedesktop.Notifications.Notify",
        "opencode",                       // app-name
        "0",                              // replaces-id (0 = new notification)
        iconPath,                         // app-icon (empty string = no icon)
        "OpenCode",                       // summary
        sessionTitle,                     // body
        "['focus', 'Go to session']",     // actions (key, label pairs)
        "{'resident': <true>}",           // hints: keep in history even after action click
        "--",                             // end of gdbus flags (prevents -1 being parsed as flag)
        "-1",                             // expire-timeout (-1 = never expire, keeps in history)
      ]);

      // Output is: (uint32 <id>,)
      const notifId = notifProc.stdout
        .toString()
        .match(/uint32 (\d+)/)?.[1];

      if (!notifId) return;

      // Build the watchScript.
      //
      // When the user clicks "Go to session":
      //   1. Write the session's directory to /tmp/aoe_cwd_target
      //   2. Write project_branch to /tmp/aoe_session_name
      //   3. Close the existing aoe-cwd foot window (if any) so pyprland recreates it
      //   4. pypr show aoe — pyprland will spawn a new foot window
      //
      // For non-aoe sessions (no pyprScratchpadName / no sessionDirectory), fall
      // back to focusing the terminal window directly.
      let watchScript;
      if (pyprScratchpadName && sessionDirectory) {
        // Derive project_branch from sessionDirectory
        const project = sessionDirectory.split("/").pop();
        const gitProc = Bun.spawnSync(["git", "-C", sessionDirectory, "branch", "--show-current"]);
        const branch = gitProc.exitCode === 0 ? gitProc.stdout.toString().trim().replace("/", "-") : "main";
        const sessionProjectBranch = `${project}_${branch}`;
        
        log(`[notification] watchScript: pyprScratchpadName=${pyprScratchpadName}, sessionProjectBranch=${sessionProjectBranch}`);
        
        watchScript = `
          gdbus monitor --session --dest org.freedesktop.Notifications \\
            --object-path /org/freedesktop/Notifications \\
            | grep --line-buffered 'ActionInvoked' \\
            | while IFS= read -r line; do
                if echo "$line" | grep -qF '${notifId}'; then
                  /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "${sessionDirectory}" "${sessionProjectBranch}"
                  break
                fi
              done
        `;
      } else {
        const focusCmd = windowAddress
          ? `hyprctl dispatch focuswindow address:${windowAddress}`
          : `true`;
        watchScript = `
          gdbus monitor --session --dest org.freedesktop.Notifications \\
            --object-path /org/freedesktop/Notifications \\
            | grep --line-buffered 'ActionInvoked' \\
            | while IFS= read -r line; do
                if echo "$line" | grep -qF '${notifId}'; then
                  ${focusCmd}
                  break
                fi
              done
        `;
      }

      log(`[notification] spawning watchScript for notifId=${notifId} dir=${sessionDirectory}`);
      const proc = Bun.spawn(["bash", "-c", watchScript], {
        stdout: "ignore",
        stderr: "ignore",
        stdin: "ignore",
      });
      proc.unref();
    },
  };
};

export default NotificationPlugin;
