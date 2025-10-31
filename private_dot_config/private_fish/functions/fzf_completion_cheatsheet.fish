#!/usr/bin/env fish
# FZF Completion Quick Reference Card

function fzf_completion_cheatsheet
    clear
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║            FZF Tab Completion - Quick Reference               ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Keyboard Shortcuts
    echo "KEYBOARD SHORTCUTS"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  TAB               → Trigger completion (insert mode)"
    echo "  ↑ / ↓             → Navigate in FZF menu"
    echo "  Enter             → Select highlighted item"
    echo "  Ctrl+C            → Cancel and close FZF menu"
    echo "  Ctrl+A            → Select all items in FZF"
    echo "  Ctrl+D            → Deselect all items"
    echo ""
    
    # Command Patterns
    echo "COMMAND PATTERNS FOR FZF COMPLETION"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  GIT COMPLETION"
    echo "  ──────────────"
    echo "    git checkout<TAB>        Show branches with commit preview"
    echo "    git switch<TAB>          Switch branches with preview"
    echo "    git merge<TAB>           Merge branches with preview"
    echo "    git rebase<TAB>          Rebase branches with preview"
    echo ""
    
    echo "  KUBECTL COMPLETION"
    echo "  ──────────────────"
    echo "    kubectl get<TAB>         Show resource types"
    echo "    kubectl exec<TAB>        Select pod with preview"
    echo "    kubectl logs<TAB>        Select pod for logs"
    echo "    kubectl describe<TAB>    Select pod to describe"
    echo ""
    
    echo "  DOCKER COMPLETION"
    echo "  ────────────────"
    echo "    docker exec<TAB>         Select container"
    echo "    docker logs<TAB>         Select container"
    echo "    docker run<TAB>          Select image"
    echo "    docker pull<TAB>         Select image"
    echo ""
    
    echo "  FILE COMPLETION"
    echo "  ───────────────"
    echo "    cd ~/D<TAB>              Show matching directories"
    echo "    cat /etc/c<TAB>          Show matching files"
    echo "    vim ./s<TAB>             Show matching files"
    echo ""
    
    # Which-Key Integration
    echo "WHICH-KEY MENU INTEGRATION"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  Space → f → C    Show completion mode help and info"
    echo "  Space → f → h    Show command history (existing)"
    echo "  Space → f → p    Show running processes (existing)"
    echo "  Space → f → v    Show environment variables (existing)"
    echo ""
    
    # How to Trigger
    echo "HOW IT WORKS"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  THRESHOLD LOGIC"
    echo "  ───────────────"
    echo "    0 completions     → Fish default behavior"
    echo "    1 completion      → Applied automatically"
    echo "    2-10 completions  → Fish menu (default)"
    echo "    11+ completions   → FZF interactive menu"
    echo ""
    echo "  This balances speed (few options) with discoverability (many)"
    echo ""
    
    # Documentation
    echo "DOCUMENTATION COMMANDS"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  fzf_completion_guide     → Read full documentation"
    echo "  test_fzf_completion      → See testing examples"
    echo "  fzf_completion_cheatsheet → This reference (you are here)"
    echo "  __show_completions       → Debug completions for current cmd"
    echo ""
    
    # File Locations
    echo "CONFIGURATION FILES"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  Main Configuration"
    echo "  ~/.config/fish/conf.d/fzf-tab-completion.fish"
    echo ""
    echo "  Supporting Functions"
    echo "  ~/.config/fish/functions/_fzf_tab_helper.fish"
    echo "  ~/.config/fish/functions/_fzf_completion_preview.fish"
    echo ""
    echo "  Modified Files"
    echo "  ~/.config/fish/conf.d/which_key.fish (added 'C' option)"
    echo ""
    
    # Examples
    echo "PRACTICAL EXAMPLES"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  Example 1: Select Git Branch"
    echo "  $ git checkout fea<TAB>"
    echo "  FZF menu appears showing branches starting with 'fea'"
    echo "  Select 'feature/new-api' and press Enter"
    echo "  Result: git checkout feature/new-api"
    echo ""
    
    echo "  Example 2: Select kubectl Pod"
    echo "  $ kubectl logs <TAB>"
    echo "  FZF menu shows available pods"
    echo "  Navigate to 'api-server-xyz' and press Enter"
    echo "  Result: kubectl logs api-server-xyz"
    echo ""
    
    echo "  Example 3: Select Docker Container"
    echo "  $ docker exec -it <TAB>"
    echo "  FZF menu shows running containers"
    echo "  Select 'postgres-dev' and press Enter"
    echo "  Result: docker exec -it postgres-dev"
    echo ""
    
    # Troubleshooting Quick Fixes
    echo "QUICK TROUBLESHOOTING"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  Issue: TAB doesn't show FZF menu"
    echo "  Fix:   source ~/.config/fish/conf.d/fzf-tab-completion.fish"
    echo ""
    
    echo "  Issue: FZF menu shows wrong completions"
    echo "  Fix:   Run __show_completions to debug"
    echo ""
    
    echo "  Issue: Need to customize completion behavior"
    echo "  Fix:   Edit fzf-tab-completion.fish, search for threshold (10)"
    echo ""
    
    # Footer
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "Press 'q' or Ctrl+C to exit this reference"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    # Wait for user input or timeout
    read -l -P "" 2>/dev/null
end

# Run the function if called directly
fzf_completion_cheatsheet
