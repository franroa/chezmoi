function aoen --description "Interactive Jira-API integrated branch creator for Agent of Empires"
    # Validar que las dependencias existan en el sistema
    if not type -q jq; or not type -q curl
        echo "❌ Error: Se requieren 'curl' y 'jq' instalados."
        return 1
    end

    # Validar que las variables base estén configuradas
    if not set -q JIRA_BASE_URL; or not set -q JIRA_EMAIL
        echo "❌ Error: Asegúrate de tener JIRA_BASE_URL y JIRA_EMAIL en tu entorno."
        return 1
    end

    # Seleccionar token disponible
    set -l jira_auth_token ""
    if set -q JIRA_TOKEN
        set jira_auth_token $JIRA_TOKEN
    else
        set jira_auth_token $JIRA_API_TOKEN
    end

    # Menú interactivo para el prefijo remoto
    echo "Select branch standard (for remote repository):"
    echo "1) feat"
    echo "2) fix"
    echo "3) poc"
    echo "4) chore"
    echo "5) refactor"

    set -l type ""
    while test -z "$type"
        read -P "Choose a number [1-5]: " choice
        switch "$choice"
            case 1
                set type feat
            case 2
                set type fix
            case 3
                set type poc
            case 4
                set type chore
            case 5
                set type refactor
            case '*'
                echo "Invalid selection. Pick a number from the menu."
        end
    end

    # 1. Solicitar el ID del Ticket de Jira
    read -P "Enter Jira Ticket ID (e.g. P0004-703): " jira_id
    set -l clean_jira (string upper "$jira_id" | string replace -r -a '\s+' '')

    echo "🔍 Fetching ticket summary from Jira..."

    # 2. Consultar la API de Jira
    set -l ticket_summary (curl -s -u "$JIRA_EMAIL:$jira_auth_token" \
        -H "Accept: application/json" \
        "$JIRA_BASE_URL/rest/api/2/issue/$clean_jira" | jq -r '.fields.summary' 2>/dev/null)

    if test -z "$ticket_summary"; or test "$ticket_summary" = null
        echo "❌ Error: No se pudo obtener el ticket '$clean_jira'."
        return 1
    end

    echo "🎫 Ticket found: \"$ticket_summary\""

    # 3. Solicitar sufijo opcional para la sesión local
    read -P "Enter optional suffix for session name (or press Enter to skip): " session_suffix

    # 4. Construir el NOMBRE CORTO (Para la Sesión de AOE/Tmux y Rama Local)
    set -l session_name "$clean_jira"
    if test -n "$session_suffix"
        set -l clean_suffix (string lower "$session_suffix" | string replace -r -a '[^a-z0-9\s-]' '' | string replace -r -a '[\s-]+' '-')
        set session_name "$clean_jira-$clean_suffix"
    end

    # 5. Limpieza del texto de Jira para la RAMA REMOTA (Larga y formal)
    set -l clean_desc (string lower "$ticket_summary" | string replace -r -a '[^a-z0-9\s-]' '' | string replace -r -a '[\s-]+' '-')
    set clean_desc (string trim -c '-' "$clean_desc")

    # Nombre oficial largo que se enviará a GitLab/GitHub
    set -l remote_branch "$type/$clean_jira-$clean_desc"

    echo "🆔 Local Session & Branch Name : $session_name"
    echo "🌍 Upstream Remote Branch Name: $remote_branch"
    echo "🚀 Spawning local isolated environment..."

    # 6. Crear el entorno en aoe usando el nombre corto (así no lleva prefijos ni textos largos)
    aoe add . -w "$session_name" -b

    # 7. MAPEO MÁGICO DE GIT: Forzar a que esta rama local apunte a la rama remota larga
    set -l worktree_path ".aoe-worktrees/$session_name"
    if test -d "$worktree_path"
        # Configura el upstream para que 'git push' sepa exactamente a dónde ir de forma automática
        git -C "$worktree_path" config branch.$session_name.remote origin
        git -C "$worktree_path" config branch.$session_name.merge refs/heads/$remote_branch
        echo "🔗 Git tracking linked successfully to remote: $remote_branch"
    end
end
