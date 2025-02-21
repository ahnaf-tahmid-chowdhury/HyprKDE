#!/bin/bash

# Get the notification count from swaync-client
notification=$(swaync-client --count | tr -d '%')

# Set icon and tooltip message based on notification count
if [[ "$notification" -gt 1 ]]; then
    icon="󱅫"
    tooltip_text="You have $notification notifications"
elif [[ "$notification" -eq 1 ]]; then
    icon="󱅫"
    tooltip_text="You have 1 notification"
else
    icon=""
    tooltip_text="No new notifications"
fi

# Print JSON output for Waybar
printf '{"text": "%s %s", "tooltip": "%s", "class": "notifications", "percentage": %s}\n' \
    "$icon" "$notification" "$tooltip_text" "$notification"
