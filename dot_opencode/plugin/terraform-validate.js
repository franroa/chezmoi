/**
 * Terraform Validate-on-Edit Plugin
 *
 * Automatically runs `terraform fmt -check` and `terraform validate`
 * after any .tf file is edited, warning the user of issues.
 */

import { spawn } from "child_process";
import { dirname } from "path";

/**
 * Run a command and capture output
 */
function runCommand(command, args, cwd) {
  return new Promise((resolve) => {
    const proc = spawn(command, args, {
      cwd,
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
        code,
      });
    });

    proc.on("error", (err) => {
      resolve({
        success: false,
        stdout: "",
        stderr: err.message,
        code: -1,
      });
    });
  });
}

/**
 * Check if terraform CLI is available
 */
async function isTerraformInstalled() {
  const result = await runCommand("terraform", ["version"], process.cwd());
  return result.success;
}

/**
 * Run terraform fmt -check
 */
async function checkFormatting(workDir) {
  const result = await runCommand("terraform", ["fmt", "-check", "-diff"], workDir);
  return {
    ok: result.success,
    output: result.stdout || result.stderr,
  };
}

/**
 * Run terraform validate
 */
async function runValidate(workDir) {
  const result = await runCommand("terraform", ["validate"], workDir);
  return {
    ok: result.success,
    output: result.stdout || result.stderr,
  };
}

export const TerraformValidate = async ({ client, $ }) => {
  // Check once at startup if terraform is available
  let terraformAvailable = null;

  return {
    "tool.execute.after": async (input, output) => {
      // Only trigger on edit or write tools
      if (input.tool !== "edit" && input.tool !== "write") {
        return;
      }

      // Get the file path from the tool arguments
      const filePath = output.args?.filePath;
      if (!filePath) {
        return;
      }

      // Only trigger for .tf files
      if (!filePath.endsWith(".tf")) {
        return;
      }

      // Check if terraform is installed (cache the result)
      if (terraformAvailable === null) {
        terraformAvailable = await isTerraformInstalled();
      }

      if (!terraformAvailable) {
        console.log("⚠ Terraform CLI not found, skipping validation");
        return;
      }

      // Get the working directory (where the .tf file is)
      const workDir = dirname(filePath);

      // Run formatting check
      const fmtResult = await checkFormatting(workDir);

      // Run validation
      const validateResult = await runValidate(workDir);

      // Build output message
      if (fmtResult.ok && validateResult.ok) {
        console.log("✓ Terraform: formatting OK, validation passed");
        return;
      }

      // There are issues - build warning message
      let warning = "⚠ Terraform issues detected:\n";

      if (!fmtResult.ok) {
        warning += "\nFormatting:\n";
        warning += fmtResult.output
          .split("\n")
          .map((line) => "  " + line)
          .join("\n");
      }

      if (!validateResult.ok) {
        warning += "\nValidation:\n";
        warning += validateResult.output
          .split("\n")
          .map((line) => "  " + line)
          .join("\n");
      }

      console.log(warning);
    },
  };
};
