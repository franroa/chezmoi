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
import { isSessionFocused } from "../notification.js";

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
