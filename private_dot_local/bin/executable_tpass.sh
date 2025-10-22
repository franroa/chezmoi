#!/bin/bash

# Check if argument is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <filename_without_extension>"
  echo "Example: $0 bcproweb1"
  exit 1
fi

# Get the filename without extension
FILENAME="$1"
VAULT_KEY="vault_${FILENAME}"
YAML_FILE="/home/froa/Projects/ts/ansible-playbooks/vault/${FILENAME}.yml"

# Check if the YAML file exists
if [ ! -f "$YAML_FILE" ]; then
  echo "Error: File $YAML_FILE not found"
  exit 1
fi

# Create a temporary file with just the vault content
TEMP_FILE=$(mktemp)

# Extract the vault content (everything from $ANSIBLE_VAULT onwards, preserving indentation)
awk "/^${VAULT_KEY}:.*!vault \|/{flag=1; next} flag && /^[^ \t]/{flag=0} flag{sub(/^  /, \"\"); print}" "$YAML_FILE" >"$TEMP_FILE"

# Check if we found the vault content
if [ ! -s "$TEMP_FILE" ]; then
  echo "Error: Property $VAULT_KEY not found in $YAML_FILE"
  rm -f "$TEMP_FILE"
  exit 1
fi

# Decrypt the vault content
VAULT_VALUE=$(ansible-vault decrypt --vault-password-file /home/froa/vault_password_file.sh --output=- "$TEMP_FILE" 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "Error: Failed to decrypt vault content"
  rm -f "$TEMP_FILE"
  exit 1
fi

# Clean up temporary file
rm -f "$TEMP_FILE"

# Copy to clipboard
echo "$VAULT_VALUE" | xclip -selection clipboard
echo "Decrypted value of $VAULT_KEY copied to clipboard" >&2
