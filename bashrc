# ~/.bashrc - Interactive shell configuration

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Source shared config
[[ -f ~/.config/bash/core ]] && source ~/.config/bash/core
[[ -f ~/.config/bash/aliases ]] && source ~/.config/bash/aliases

# Source OS-specific config
if [[ "$(uname)" == "Darwin" ]]; then
    [[ -f ~/.config/bash/macos ]] && source ~/.config/bash/macos
else
    [[ -f ~/.config/bash/linux ]] && source ~/.config/bash/linux
fi

# Source sync functions (rsync project tooling)
[[ -f ~/.config/bash/sync-functions ]] && source ~/.config/bash/sync-functions
