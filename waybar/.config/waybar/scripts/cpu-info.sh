#!/bin/bash

# Get CPU model
cpu_model=$(awk -F': ' '/^model name/ {print $2; exit}' /proc/cpuinfo)

# Read total CPU usage before sleep
read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
total_before=$((user + nice + system + idle + iowait + irq + softirq + steal))
active_before=$((user + nice + system + irq + softirq + steal))

# Store per-core data
declare -A prev_total prev_active

while read -r cpu_id user nice system idle iowait irq softirq steal _; do
    [[ $cpu_id == cpu* ]] || break
    prev_total[$cpu_id]=$((user + nice + system + idle + iowait + irq + softirq + steal))
    prev_active[$cpu_id]=$((user + nice + system + irq + softirq + steal))
done < /proc/stat

# Sleep for measurement interval
sleep 0.5

# Read total CPU usage after sleep
read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
total_after=$((user + nice + system + idle + iowait + irq + softirq + steal))
active_after=$((user + nice + system + irq + softirq + steal))

# Compute total CPU usage safely
total_delta=$((total_after - total_before))
active_delta=$((active_after - active_before))
total_usage=$(( total_delta > 0 ? (100 * active_delta / total_delta) : 0 ))

# Compute per-core usage
core_usages=""
core_count=0
core_usage_sum=0
while read -r cpu_id user nice system idle iowait irq softirq steal _; do
    [[ $cpu_id == cpu* ]] || break

    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    active=$((user + nice + system + irq + softirq + steal))

    if [[ -n "${prev_total[$cpu_id]}" && -n "${prev_active[$cpu_id]}" ]]; then
        total_diff=$((total - prev_total[$cpu_id]))
        active_diff=$((active - prev_active[$cpu_id]))
        usage=$(( total_diff > 0 ? (100 * active_diff / total_diff) : 0 ))
    else
        usage=0
    fi

    [[ $cpu_id != "cpu" ]] && core_usages+="\nCore ${cpu_id#cpu}: $usage%"

    ((core_usage_sum += usage))
    ((core_count++))
done < /proc/stat

# Get CPU temperature (robust method)
temps=()
for hwmon in /sys/class/hwmon/hwmon*; do
    if [[ -f "$hwmon/name" ]] && grep -qi "coretemp" "$hwmon/name"; then
        for temp_file in "$hwmon"/temp*_input; do
            temp=$(<"$temp_file")
            [[ $temp =~ ^[0-9]+$ ]] && temps+=("$((temp / 1000))")
        done
    fi
done

# Calculate average temperature
if [[ ${#temps[@]} -gt 0 ]]; then
    sum=0
    for temp in "${temps[@]}"; do
        ((sum += temp))
    done
    avg_temp=$((sum / ${#temps[@]}))
else
    avg_temp="N/A"
fi

# Create a CPU usage bar
bar_length=10
used_blocks=$((total_usage * bar_length / 100))
remaining_blocks=$((bar_length - used_blocks))
for ((i=0; i<used_blocks; i++)); do usage_bar+="█"; done
for ((i=0; i<remaining_blocks; i++)); do usage_bar+="░"; done

# Format numbers with thousands separators
format_number() {
    printf "%'.0f" "$1"
}

# Construct tooltip text with better formatting
tooltip_text="<b>CPU Info</b>\n"
tooltip_text+="Model: $cpu_model\n"
tooltip_text+="Usage: $total_usage% $usage_bar\n"
tooltip_text+="Temp: $avg_temp°C\n\n"

tooltip_text+="<b>Per-Core Usage</b>$core_usages"

# Output JSON for UI
printf '{"text": "󰍛 %s%%", "tooltip": "%s", "class": "cpu", "percentage": %s}\n' \
    "$total_usage" "$tooltip_text" "$total_usage"
