#!/bin/bash

# Use XDG directories for better portability
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Define the Waybar config directory
WAYBAR_CONFIG_DIR="$XDG_CONFIG_HOME/waybar"
COLORS_CSS="$WAYBAR_CONFIG_DIR/colors.css"

# Ensure the Waybar config directory exists
mkdir -p "$WAYBAR_CONFIG_DIR"

# Create an empty colors.css file
touch "$COLORS_CSS"

# Launch Waybar
waybar &
