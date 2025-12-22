/**
 * Deletion Protection Plugin
 *
 * Prevents OpenCode from deleting Azure and Grafana resources
 * unless the user has explicitly confirmed in recent messages.
 *
 * Configure confirmation phrases and message history depth below.
 */

// Phrases that count as deletion confirmation (case-insensitive)
const CONFIRMATION_PHRASES = [
  "yes, delete",
  "confirm delete",
  "go ahead and delete",
  "delete it",
  "remove it",
  "i confirm",
];

// How many recent user messages to check for confirmation
const MESSAGES_TO_CHECK = 3;

// Azure destructive keywords in commands/intents
const AZURE_DESTRUCTIVE_KEYWORDS = [
  "delete",
  "remove",
  "purge",
  "destroy",
];

// Grafana tools that perform deletions
const GRAFANA_DELETE_TOOLS = [
  "grafana_delete_alert_rule",
];

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
 * Check if an Azure tool call is destructive
 */
function isAzureDestructive(toolName, args) {
  if (!toolName.startsWith("azure_")) {
    return false;
  }

  // Check the command or intent parameters
  const checkFields = [
    args.command,
    args.intent,
    toolName,
  ].filter(Boolean);

  for (const field of checkFields) {
    const lowerField = field.toLowerCase();
    for (const keyword of AZURE_DESTRUCTIVE_KEYWORDS) {
      if (lowerField.includes(keyword)) {
        return true;
      }
    }
  }

  return false;
}

/**
 * Check if a Grafana tool call is destructive
 */
function isGrafanaDestructive(toolName) {
  // Explicit delete tools
  if (GRAFANA_DELETE_TOOLS.includes(toolName)) {
    return true;
  }

  // Catch any future grafana_delete_* tools
  if (toolName.startsWith("grafana_delete_")) {
    return true;
  }

  return false;
}

/**
 * Extract a human-readable description of what's being deleted
 */
function getDeleteDescription(toolName, args) {
  // Try to find a name or identifier in common fields
  const identifiers = [
    args.name,
    args.resourceName,
    args.resource_name,
    args.uid,
    args.id,
    args.projectKey,
    args.intent,
  ].filter(Boolean);

  const identifier = identifiers[0] || "resource";
  
  if (toolName.startsWith("azure_")) {
    return `Azure ${toolName.replace("azure_", "")} (${identifier})`;
  }
  
  if (toolName.startsWith("grafana_")) {
    return `Grafana ${toolName.replace("grafana_", "").replace(/_/g, " ")} (${identifier})`;
  }

  return `${toolName} (${identifier})`;
}

export const DeletionProtection = async ({ client, $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      const toolName = input.tool;
      const args = output.args || {};

      // Check if this is a destructive Azure operation
      const azureDestructive = isAzureDestructive(toolName, args);
      
      // Check if this is a destructive Grafana operation
      const grafanaDestructive = isGrafanaDestructive(toolName);

      if (!azureDestructive && !grafanaDestructive) {
        return; // Not a destructive operation, allow it
      }

      // Check for user confirmation in recent messages
      if (hasUserConfirmation(input.messages)) {
        return; // User confirmed, allow the deletion
      }

      // Block the deletion
      const description = getDeleteDescription(toolName, args);
      throw new Error(
        `Deletion blocked: You're about to delete ${description}.\n\n` +
        `Please confirm by saying something like "yes, delete it" or "confirm delete" ` +
        `in your message, then try again.`
      );
    },
  };
};
