/**
 * Tests for isSessionFocused()
 *
 * isSessionFocused(sessionDirectory, currentAoeSessionDir, windowClass, deps)
 * 
 * Returns true when:
 *   - Window class is visible (not on special workspace)
 *   - AND sessionDirectory matches currentAoeSessionDir
 *
 * Returns false when:
 *   - windowClass is null
 *   - hyprctl fails
 *   - no matching client
 *   - client is on special workspace (hidden)
 *   - sessionDirectory doesn't match currentAoeSessionDir
 */

import { test, expect, describe } from "bun:test";
import { isSessionFocused, findTerminalWindow } from "../notification.js";

// Helper to build a minimal hyprctl client entry
function makeClient({ class: cls = "aoe-cwd", hidden = false, workspace = null } = {}) {
  return { class: cls, hidden, address: "0xdeadbeef", mapped: true, workspace };
}

describe("isSessionFocused", () => {
  test("returns true when sessionDirectory matches currentAoeSessionDir and window is visible", () => {
    const deps = {
      readFile: () => null,
      hyprctlClients: () => [makeClient({ hidden: false, workspace: { name: "1" } })],
    };
    // Both sessions at the same directory
    expect(isSessionFocused("/home/froa/Projects/ts/platform-core", "/home/froa/Projects/ts/platform-core", "aoe-cwd", deps)).toBe(true);
  });

  test("returns false when sessionDirectory does not match currentAoeSessionDir", () => {
    const deps = {
      readFile: () => null,
      hyprctlClients: () => [makeClient({ hidden: false, workspace: { name: "1" } })],
    };
    // Different directories
    expect(isSessionFocused("/home/froa/Projects/ts/platform-core", "/home/froa/Projects/ts/azure_backup", "aoe-cwd", deps)).toBe(false);
  });

  test("returns false when hyprctl returns no clients", () => {
    const deps = {
      readFile: () => null,
      hyprctlClients: () => null,
    };
    expect(isSessionFocused("/home/froa/Projects/ts/platform-core", "/home/froa/Projects/ts/platform-core", "aoe-cwd", deps)).toBe(false);
  });

  test("returns false when no client matches the window class", () => {
    const deps = {
      readFile: () => null,
      hyprctlClients: () => [makeClient({ class: "kitty", hidden: false })],
    };
    expect(isSessionFocused("/home/froa/Projects/ts/platform-core", "/home/froa/Projects/ts/platform-core", "aoe-cwd", deps)).toBe(false);
  });

  test("returns false when matching client is on special workspace (hidden scratchpad)", () => {
    const deps = {
      readFile: () => null,
      hyprctlClients: () => [makeClient({ hidden: false, workspace: { name: "special:S-aoe" } })],
    };
    expect(isSessionFocused("/home/froa/Projects/ts/platform-core", "/home/froa/Projects/ts/platform-core", "aoe-cwd", deps)).toBe(false);
  });

  test("returns false when windowClass is null", () => {
    const deps = {
      readFile: () => null,
      hyprctlClients: () => [makeClient({ hidden: false })],
    };
    expect(isSessionFocused("/home/froa/Projects/ts/platform-core", "/home/froa/Projects/ts/platform-core", null, deps)).toBe(false);
  });

  test("returns false when currentAoeSessionDir is null (not in aoe session)", () => {
    const deps = {
      readFile: () => null,
      hyprctlClients: () => [makeClient({ hidden: false, workspace: { name: "1" } })],
    };
    // Even with window visible, if not in aoe session, don't suppress
    expect(isSessionFocused("/home/froa/Projects/ts/platform-core", null, "aoe-cwd", deps)).toBe(false);
  });

  test("handles multiple clients — uses the matching class that is visible", () => {
    const deps = {
      readFile: () => null,
      hyprctlClients: () => [
        makeClient({ class: "kitty", hidden: false, workspace: { name: "1" } }),
        makeClient({ class: "aoe-cwd", hidden: false, workspace: { name: "2" } }),
      ],
    };
    expect(isSessionFocused("/home/froa/Projects/ts/platform-core", "/home/froa/Projects/ts/platform-core", "aoe-cwd", deps)).toBe(true);
  });
});

/**
 * Tests for findTerminalWindow()
 *
 * The bug: `tmux display-message` exits 0 and returns the last active session
 * name even when run OUTSIDE of tmux, as long as a tmux server is running.
 * This caused regular terminals (foot/ghostty) to be misidentified as the
 * aoe scratchpad after the aoe session had been opened once.
 *
 * The fix: only trust `tmux display-message` if we are actually INSIDE a tmux
 * session, indicated by the $TMUX environment variable being set.
 */
describe("findTerminalWindow", () => {
  // Helper: hyprctl pid map with a single foot window
  function makeHyprMap(pid = 12345) {
    return new Map([[pid, { address: "0xdeadbeef", windowClass: "foot" }]]);
  }

  test("returns aoe-cwd when $TMUX is set and tmux session name starts with aoe_", () => {
    const deps = {
      tmuxEnv: "/tmp/tmux-1000/default,12345,0",  // $TMUX is set → inside tmux
      spawnSync: (cmd) => {
        if (cmd[0] === "tmux") return { exitCode: 0, stdout: Buffer.from("aoe_main_abc123\n") };
        if (cmd[0] === "hyprctl") return { exitCode: 0, stdout: Buffer.from("[]") };
        return { exitCode: 1, stdout: Buffer.from("") };
      },
    };
    const result = findTerminalWindow(deps);
    expect(result).not.toBeNull();
    expect(result.windowClass).toBe("aoe-cwd");
  });

  test("does NOT return aoe-cwd when $TMUX is unset even if tmux server has an aoe_ session", () => {
    // This is the bug scenario: a regular terminal (not inside tmux) where a
    // tmux server happens to be running with an aoe_ session active.
    const deps = {
      tmuxEnv: undefined,  // $TMUX is NOT set → not inside tmux
      spawnSync: (cmd) => {
        // tmux display-message succeeds and returns an aoe_ session name
        // (because the tmux server is running with that session)
        if (cmd[0] === "tmux") return { exitCode: 0, stdout: Buffer.from("aoe_main_abc123\n") };
        // hyprctl returns empty — no windows with our pid
        if (cmd[0] === "hyprctl") return { exitCode: 0, stdout: Buffer.from("[]") };
        // ps ppid chain — no match
        if (cmd[0] === "ps") return { exitCode: 1, stdout: Buffer.from("") };
        return { exitCode: 1, stdout: Buffer.from("") };
      },
    };
    const result = findTerminalWindow(deps);
    // Must NOT return aoe-cwd — this is a plain terminal, not the aoe scratchpad
    expect(result?.windowClass).not.toBe("aoe-cwd");
  });
});
