#!/usr/bin/env fish
# Load secrets from KeePassXC into environment (fish)

function __chezmoi_load_secrets
    # Require keepassxc-cli
    if not type -q keepassxc-cli
        echo "keepassxc-cli not found; install KeePassXC CLI." 1>&2
        return 1
    end

    # Use -g for global (or -U for universal if you want it saved
    # permanently, which is fine for a path).
    set -g KP_DB "/mnt/c/Users/froa/Nextcloud/froa/froa.kdbx"

    # Prompt once for KeePassXC master password
    # Add -g to make the variable global
    read -s -g -P "Enter KeePassXC master password: " KEEPASS_PASSWORD
    if test -z "$KEEPASS_PASSWORD"
        echo "No password entered; aborting." 1>&2
        return 1
    end

    # This function will now work, because it can access
    # the global $KEEPASS_PASSWORD and $KP_DB variables.
    function kp_show --argument-names entry
        echo $KEEPASS_PASSWORD | keepassxc-cli show "$KP_DB" "$entry" -a password --quiet
    end

    # Tokens from KeePassXC
    set -gx GRAFANA_API_KEY (kp_show "grafana_api_key")
    set -gx GEMINI_API_KEY (kp_show "gemini_api_key")
    set -gx OPENAI_API_KEY (kp_show "openai_api_key")
    set -gx SSHPASS (kp_show "gaproweb2.firesponse.com")
    set -gx SSHPASS2 (kp_show "gaproweb2.firesponse.com")
    set -gx ANSIBLE_VAULT_PASSWORD (kp_show "Vault")
    set -gx NOTION_API_KEY (kp_show "notion_fran")
    set -gx JIRA_API_TOKEN (kp_show "jira_token")
    set -gx SENTRY_AUTH_TOKEN (kp_show "sentry")
    set -gx GITLAB_PERSONAL_ACCESS_TOKEN (kp_show "gitlab_personal_token")

    # Derived GitLab variables
    set -gx GITLAB_TOKEN $GITLAB_PERSONAL_ACCESS_TOKEN
    set -gx GITLAB_API_KEY $GITLAB_PERSONAL_ACCESS_TOKEN
    set -gx GITLAB_VIM_URL $GITLAB_PERSONAL_ACCESS_TOKEN

    # Terraform creds
    set -gx TF_HTTP_USERNAME froa-tsyl
    set -gx TF_HTTP_PASSWORD $GITLAB_PERSONAL_ACCESS_TOKEN

    # Static config
    set -gx GRAFANA_URL https://grafana.technosylva.io/
    set -gx DEFAULT_MODEL ollama/llama3.2:3b
    set -gx API_BASE_URL http://localhost:11434
    set -gx USE_LITELLM true
    set -gx SHELL_INTERACTION false
    set -gx PRETTIFY_MARKDOWN false
    set -gx OS_NAME Ubuntu
    set -gx SHELL_NAME fish
    set -gx GITLAB_URL https://gitlab.com:1235/
    set -gx OPENAI_BASE_URL https://openrouter.ai/api/v1
    set -gx OPENAI_MODEL qwen/qwen3-coder:free
    set -gx CI_DEPLOY_USER froa-tsyl
    set -gx CI_DEPLOY_PASSWORD $GITLAB_PERSONAL_ACCESS_TOKEN
    set -gx CI_REGISTRY registry.gitlab.com

    # Cleanup
    functions -e kp_show
    set -e KP_DB
    set -e KEEPASS_PASSWORD

    return 0
end

# Execute and then remove the loader function to avoid leaking it
__chezmoi_load_secrets
functions -e __chezmoi_load_secrets
