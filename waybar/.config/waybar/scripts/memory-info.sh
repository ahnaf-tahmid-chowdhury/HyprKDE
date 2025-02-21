#!/bin/bash

# Get total and available memory from /proc/meminfo
total_mem=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
available_mem=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)

# Convert from kB to MB
total_mem_mb=$((total_mem / 1024))
available_mem_mb=$((available_mem / 1024))

# Calculate used memory
used_mem_mb=$((total_mem_mb - available_mem_mb))

# Calculate usage percentage
usage_percent=$((100 * used_mem_mb / total_mem_mb))

# Get Swap memory details
total_swap=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
free_swap=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)

# Convert swap values to MB
total_swap_mb=$((total_swap / 1024))
free_swap_mb=$((free_swap / 1024))
used_swap_mb=$((total_swap_mb - free_swap_mb))

# Create a memory usage bar
bar_length=10
used_blocks=$((usage_percent * bar_length / 100))
remaining_blocks=$((bar_length - used_blocks))
for ((i=0; i<used_blocks; i++)); do usage_bar+="█"; done
for ((i=0; i<remaining_blocks; i++)); do usage_bar+="░"; done

# Format numbers with thousands separators
format_number() {
    printf "%'.0f" "$1"
}

# Construct tooltip text with better formatting
tooltip_text="<b>RAM Info</b>\n"
tooltip_text+="Usage: ${usage_percent}% $usage_bar\n"
tooltip_text+="Total: $(format_number "$total_mem_mb") MB\n"
tooltip_text+="Used:  $(format_number "$used_mem_mb") MB\n"
tooltip_text+="Available: $(format_number "$available_mem_mb") MB\n\n"

tooltip_text+="<b>Swap Info</b>\n"
tooltip_text+="Total: $(format_number "$total_swap_mb") MB\n"
tooltip_text+="Used:  $(format_number "$used_swap_mb") MB\n"
tooltip_text+="Free:  $(format_number "$free_swap_mb") MB"

# Output JSON
printf '{"text": " %s%%", "tooltip": "%s", "class": "ram", "percentage": %s}\n' \
    "$usage_percent" "$tooltip_text" "$usage_percent"
