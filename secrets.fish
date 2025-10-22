
# Prompt for KeePassXC password once
read -sP "Enter KeePassXC master password: " KEEPASS_PASSWORD


export GRAFANA_API_KEY="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "grafana_api_key" -a password --quiet)"
export GRAFANA_URL="https://grafana.technosylva.io/"

export GEMINI_API_KEY="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "gemini_api_key" -a password --quiet)"

export DEFAULT_MODEL=ollama/llama3.2:3b
export API_BASE_URL=http://localhost:11434
export USE_LITELLM=true
export OPENAI_API_KEY=bad_key
export SHELL_INTERACTION=false
export PRETTIFY_MARKDOWN=false
export OS_NAME="Ubuntu"
export SHELL_NAME=fish


export TF_HTTP_PASSWORD=$GITLAB_PERSONAL_ACCESS_TOKEN
export TF_HTTP_USERNAME="froa-tsyl"


export GITLAB_URL="https://gitlab.com:1235/"
export OPENAI_API_KEY="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "openai_api_key" -a password --quiet)"
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_MODEL="qwen/qwen3-coder:free"


export SSHPASS="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "gaproweb2.firesponse.com" -a password --quiet)"
export SSHPASS2="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "gaproweb2.firesponse.com" -a password --quiet)"
export ANSIBLE_VAULT_PASSWORD="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "Vault" -a password --quiet)"
export NOTION_API_KEY="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "notion_fran" -a password --quiet)"
export JIRA_API_TOKEN="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "jira_token" -a password --quiet)"

export GITLAB_PERSONAL_ACCESS_TOKEN="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "gitlab_personal_token" -a password --quiet)"

export GITLAB_TOKEN=$GITLAB_PERSONAL_ACCESS_TOKEN
export GITLAB_API_KEY=$GITLAB_PERSONAL_ACCESS_TOKEN
export GITLAB_VIM_URL=$GITLAB_PERSONAL_ACCESS_TOKEN

export CI_DEPLOY_USER="froa-tsyl"
export CI_DEPLOY_PASSWORD=$GITLAB_PERSONAL_ACCESS_TOKEN
export CI_REGISTRY="registry.gitlab.com"

export SENTRY_AUTH_TOKEN="$(echo "$KEEPASS_PASSWORD" | keepassxc-cli show "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx" "sentry" -a password --quiet)"
set -e KEEPASS_PASSWORD
