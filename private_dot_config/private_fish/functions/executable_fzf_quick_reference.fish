#!/usr/bin/env fish
# Quick reference for FZF completion system

function fzf_quick_reference --description "Quick reference for FZF completion"
    echo ""
    echo "FZF COMPLETION - QUICK REFERENCE"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "TRY THESE RIGHT NOW:"
    echo "  git checkout<TAB>         Find and checkout a branch"
    echo "  kubectl get<TAB>          Select resource type"
    echo "  docker exec<TAB>          Choose running container"
    echo "  cd ~/D<TAB>               Find directory starting with D"
    echo ""
    echo "KEYBOARD SHORTCUTS:"
    echo "  TAB          Trigger completion"
    echo "  ↑↓           Navigate in FZF menu"
    echo "  Enter        Select highlighted item"
    echo "  Ctrl+C       Cancel"
    echo "  Type         Search/filter in FZF"
    echo ""
    echo "DOCUMENTATION:"
    echo "  fzf_completion_guide      Full documentation"
    echo "  fzf_completion_cheatsheet Detailed reference"
    echo "  __show_completions        Debug completions"
    echo ""
    echo "From Which-Key:"
    echo "  Space → f → C             Completion help"
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo ""
end

# Run if called directly
fzf_quick_reference
