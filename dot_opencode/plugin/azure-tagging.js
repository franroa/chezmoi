/**
 * Azure Resource Tagging Enforcement Plugin
 *
 * Warns when creating Azure resources without required tags.
 * Configure required tags in the REQUIRED_TAGS array below.
 */

// Required tags for Azure resources (case-insensitive matching)
const REQUIRED_TAGS = [
  "environment",
  "owner",
  "project",
  "cost-center",
];

// Keywords that indicate resource creation
const CREATION_KEYWORDS = [
  "create",
  "new",
  "deploy",
  "provision",
  "add",
];

/**
 * Check if an Azure operation is creating a resource
 */
function isCreationOperation(toolName, args) {
  if (!toolName.startsWith("azure_")) {
    return false;
  }

  // Check tool name for creation hints
  const lowerToolName = toolName.toLowerCase();
  for (const keyword of CREATION_KEYWORDS) {
    if (lowerToolName.includes(keyword)) {
      return true;
    }
  }

  // Check intent/command parameters
  const fieldsToCheck = [
    args.intent,
    args.command,
  ].filter(Boolean);

  for (const field of fieldsToCheck) {
    const lowerField = field.toLowerCase();
    for (const keyword of CREATION_KEYWORDS) {
      if (lowerField.includes(keyword)) {
        return true;
      }
    }
  }

  return false;
}

/**
 * Extract tags from various possible locations in args
 */
function extractTags(args) {
  // Direct tags parameter
  if (args.tags && typeof args.tags === "object") {
    return args.tags;
  }

  // Nested in parameters
  if (args.parameters?.tags && typeof args.parameters.tags === "object") {
    return args.parameters.tags;
  }

  // Check for tags in nested properties object
  if (args.properties?.tags && typeof args.properties.tags === "object") {
    return args.properties.tags;
  }

  return null;
}

/**
 * Get list of missing required tags
 */
function getMissingTags(providedTags) {
  if (!providedTags) {
    return REQUIRED_TAGS; // All tags missing
  }

  // Get provided tag keys (lowercase for comparison)
  const providedKeys = Object.keys(providedTags).map((k) => k.toLowerCase());

  // Find which required tags are missing
  const missing = REQUIRED_TAGS.filter(
    (required) => !providedKeys.includes(required.toLowerCase())
  );

  return missing;
}

/**
 * Format the warning message
 */
function formatWarning(missingTags) {
  let warning = "⚠ Azure resource creation detected without required tags.\n\n";
  warning += `Missing tags: ${missingTags.join(", ")}\n\n`;
  warning += "Recommended tags for governance:\n";
  warning += "  - environment: prod/staging/dev\n";
  warning += "  - owner: team or individual\n";
  warning += "  - project: project name\n";
  warning += "  - cost-center: billing code\n";

  return warning;
}

export const AzureTaggingEnforcement = async ({ client, $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      const toolName = input.tool;
      const args = output.args || {};

      // Only check Azure tools
      if (!toolName.startsWith("azure_")) {
        return;
      }

      // Only check creation operations
      if (!isCreationOperation(toolName, args)) {
        return;
      }

      // Extract tags from args
      const providedTags = extractTags(args);

      // Check for missing tags
      const missingTags = getMissingTags(providedTags);

      if (missingTags.length === 0) {
        return; // All required tags present
      }

      // Warn about missing tags (but don't block)
      console.log(formatWarning(missingTags));
    },
  };
};
