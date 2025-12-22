/**
 * K8s Context Protection Plugin
 *
 * Blocks all kubectl commands when the current context matches
 * production patterns, unless the user has confirmed.
 */

import { spawn } from "child_process";

// Patterns that indicate a production context (case-insensitive)
const PRODUCTION_PATTERNS = [
  "prod",
  "production",
  "prd",
  "live",
];

// Phrases that count as confirmation (case-insensitive)
const CONFIRMATION_PHRASES = [
  "yes, delete",
  "confirm delete",
  "go ahead and delete",
  "delete it",
  "remove it",
  "i confirm",
  "yes, run it",
  "go ahead",
  "yes, do it",
  "confirmed",
];

// How many recent user messages to check for confirmation
const MESSAGES_TO_CHECK = 3;

/**
 * Run a command and capture output
 */
function runCommand(command, args) {
  return new Promise((resolve) => {
    const proc = spawn(command, args, {
      shell: true,
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    proc.stdout?.on("data", (data) => {
      stdout += data.toString();
    });

    proc.stderr?.on("data", (data) => {
      stderr += data.toString();
    });

    proc.on("close", (code) => {
      resolve({
        success: code === 0,
        stdout: stdout.trim(),
        stderr: stderr.trim(),
      });
    });

    proc.on("error", (err) => {
      resolve({
        success: false,
        stdout: "",
        stderr: err.message,
      });
    });
  });
}

/**
 * Get the current kubectl context
 */
async function getCurrentContext() {
  const result = await runCommand("kubectl", ["config", "current-context"]);
  if (result.success) {
    return result.stdout;
  }
  return null;
}

/**
 * Check if a context name matches production patterns
 */
function isProductionContext(contextName) {
  if (!contextName) {
    return false;
  }

  const lowerContext = contextName.toLowerCase();

  for (const pattern of PRODUCTION_PATTERNS) {
    if (lowerContext.includes(pattern)) {
      return true;
    }
  }

  return false;
}

/**
 * Check if any recent user messages contain a confirmation phrase
 */
function hasUserConfirmation(messages) {
  if (!messages || !Array.isArray(messages)) {
    return false;
  }

  // Get last N user messages
  const userMessages = messages
    .filter((msg) => msg.role === "user")
    .slice(-MESSAGES_TO_CHECK);

  for (const msg of userMessages) {
    const content = typeof msg.content === "string"
      ? msg.content
      : JSON.stringify(msg.content);

    const lowerContent = content.toLowerCase();

    for (const phrase of CONFIRMATION_PHRASES) {
      if (lowerContent.includes(phrase.toLowerCase())) {
        return true;
      }
    }
  }

  return false;
}

/**
 * Check if a command contains kubectl
 */
function isKubectlCommand(command) {
  return /\bkubectl\b/.test(command);
}

export const K8sContextProtection = async ({ client, $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      // Only check bash commands
      if (input.tool !== "bash") {
        return;
      }

      const command = output.args?.command;
      if (!command) {
        return;
      }

      // Only check kubectl commands
      if (!isKubectlCommand(command)) {
        return;
      }

      // Get current context
      const currentContext = await getCurrentContext();

      if (!currentContext) {
        // Can't determine context, allow command
        return;
      }

      // Check if it's a production context
      if (!isProductionContext(currentContext)) {
        return; // Not production, allow
      }

      // Production context - check for confirmation
      if (hasUserConfirmation(input.messages)) {
        return; // User confirmed, allow
      }

      // Block the command
      throw new Error(
        `⚠ Production context detected: "${currentContext}"\n\n` +
        `You're about to run kubectl against a production context.\n` +
        `Please confirm by saying something like "yes, run it" or "I confirm" ` +
        `in your message, then try again.`
      );
    },
  };
};
