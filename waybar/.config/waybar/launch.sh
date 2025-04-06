#!/bin/bash

# Use XDG directories for better portability
WAYBAR_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
COLORS_CSS="$WAYBAR_CONFIG_DIR/colors.css"

# Ensure the Waybar config directory and colors.css exist
mkdir -p "$WAYBAR_CONFIG_DIR" && touch "$COLORS_CSS"

# Define an ordered list of terminals with their execution flags
terminals=(
    "alacritty -e"
    "kitty"
    "konsole -e"
    "gnome-terminal --"
    "xfce4-terminal -e"
)

# Find the first available terminal
for term in "${terminals[@]}"; do
    cmd=${term%% *}  # Extract the command name (first word)
    if command -v "$cmd" &>/dev/null; then
        export TERMINAL_CMD="$term"
        break
    fi
done

# Notify if no terminal is found
if [[ -z "$TERMINAL_CMD" ]]; then
    notify-send -a "Waybar" -u critical "Waybar" "No compatible terminal found. Install alacritty, kitty, konsole, gnome-terminal, or xfce4-terminal."
    exit 1
fi

# Launch Waybar
exec waybar
