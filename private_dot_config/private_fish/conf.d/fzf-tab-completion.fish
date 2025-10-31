# FZF Tab Completion Enhancement - Configuration Loading
# This file is loaded EARLY (conf.d), so we only set up the binding here.
# The actual functions are defined in functions/ directory and will be
# autoloaded when needed.
#
# NOTE: DO NOT define functions that use _fzf_wrapper in conf.d
# They must be in the functions/ directory instead!

if not status is-interactive
    exit
end

# The key bindings and function definitions have been moved to:
# - functions/__fzf_tab_completion.fish (main tab completion logic)
# - functions/__fzf_tab_handler.fish (tab key handler)
#
# These are loaded after fzf.fish is initialized, ensuring all
# dependencies like _fzf_wrapper are available when needed.
