/**
 * Environment Protection Plugin
 *
 * Prevents OpenCode from:
 * 1. Reading .env files
 * 2. Accessing specific environment variables via bash commands
 *
 * Configure protected env vars in the PROTECTED_ENV_VARS array below.
 */

// Exact environment variable names to protect
const PROTECTED_ENV_VARS = [
  "DATABASE_PASSWORD",
  "DB_PASSWORD",
  "API_SECRET",
  "SECRET",
  // Add more as needed
];

// Patterns (suffix matching) - blocks any env var ending with these
const PROTECTED_ENV_PATTERNS = [
  /.*KEY$/i, // *KEY - blocks API_KEY, SECRET_KEY, PRIVATE_KEY, etc.
  /.*TOKEN$/i, // *TOKEN - blocks AUTH_TOKEN, ACCESS_TOKEN, SESSION_TOKEN, etc.
  /.*PASSWORD$/i,
  /.*PSSWD$/i,
];

// Patterns that might be used to read env vars
const ENV_READ_PATTERNS = [
  /\becho\s+\$\{?(\w+)\}?/gi, // echo $VAR or echo ${VAR}
  /\bprintenv\s+(\w+)/gi, // printenv VAR
  /\benv\b/gi, // env command (lists all)
  /\$\{?(\w+)\}?/g, // $VAR or ${VAR} references
  /\bexport\b/gi, // export command
  /\bset\b\s*$/gi, // set command (lists all)
  /\/proc\/\d+\/environ/gi, // reading process environment
  /cat\s+.*\/environ/gi, // cat /proc/*/environ
];

/**
 * Check if an env var name matches protected patterns
 */
function isProtectedEnvVar(varName) {
  // Check exact matches
  if (PROTECTED_ENV_VARS.includes(varName.toUpperCase())) {
    return true;
  }

  // Check pattern matches (e.g., *KEY, *TOKEN)
  for (const pattern of PROTECTED_ENV_PATTERNS) {
    if (pattern.test(varName)) {
      return true;
    }
  }

  return false;
}

/**
 * Extract env var names from a command
 */
function extractEnvVarNames(command) {
  const varNames = [];

  // Match $VAR or ${VAR}
  const varPattern = /\$\{?([A-Z_][A-Z0-9_]*)\}?/gi;
  let match;
  while ((match = varPattern.exec(command)) !== null) {
    varNames.push(match[1]);
  }

  // Match printenv VAR
  const printenvPattern = /\bprintenv\s+([A-Z_][A-Z0-9_]*)/gi;
  while ((match = printenvPattern.exec(command)) !== null) {
    varNames.push(match[1]);
  }

  return varNames;
}

/**
 * Check if a command attempts to read protected env vars
 */
function detectEnvVarAccess(command) {
  const violations = [];

  // Extract all env var references and check each one
  const varNames = extractEnvVarNames(command);
  for (const varName of varNames) {
    if (isProtectedEnvVar(varName)) {
      violations.push(varName);
    }
  }

  // Check for commands that dump all env vars
  const dumpAllPatterns = [
    /\bprintenv\s*$/gi, // printenv with no args
    /\benv\s*$/gi, // env with no args
    /\bexport\s+-p\b/gi, // export -p
    /\bset\s*$/gi, // set with no args
    /\/proc\/\d+\/environ/gi,
    /cat\s+.*\/environ/gi,
  ];

  for (const pattern of dumpAllPatterns) {
    if (pattern.test(command)) {
      violations.push("ALL_ENV_VARS");
    }
  }

  return [...new Set(violations)];
}

export const EnvProtection = async ({ client, $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      // Block reading .env files
      if (input.tool === "read" && output.args.filePath) {
        const filePath = output.args.filePath.toLowerCase();
        if (
          filePath.includes(".env") ||
          filePath.endsWith(".env") ||
          filePath.match(/\.env\.\w+$/)
        ) {
          throw new Error(
            "Access denied: Reading .env files is not allowed for security reasons.",
          );
        }
      }

      // Block bash commands that access protected env vars
      if (input.tool === "bash" && output.args.command) {
        const command = output.args.command;
        const violations = detectEnvVarAccess(command);

        if (violations.length > 0) {
          if (violations.includes("ALL_ENV_VARS")) {
            throw new Error(
              "Access denied: Commands that dump all environment variables are not allowed for security reasons.",
            );
          }
          throw new Error(
            `Access denied: Accessing protected environment variable(s): ${violations.join(", ")}. ` +
              "These contain sensitive credentials.",
          );
        }
      }

      // Block grep/cat on files that might contain secrets
      if (input.tool === "bash" && output.args.command) {
        const command = output.args.command;
        const secretFilePatterns = [
          /\.(env|secret|credentials|key|pem)\b/i,
          /credentials/i,
          /secrets?\//i,
        ];

        for (const pattern of secretFilePatterns) {
          if (
            pattern.test(command) &&
            /\b(cat|less|more|head|tail)\b/.test(command)
          ) {
            throw new Error(
              "Access denied: Reading files that may contain secrets is not allowed.",
            );
          }
        }
      }
    },
  };
};
