# XDG directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# Source bashrc
[[ -f $XDG_CONFIG_HOME/bash/bashrc ]] && . $XDG_CONFIG_HOME/bash/bashrc
