#!/bin/bash

# Check if nvidia-smi is available
if ! command -v nvidia-smi &>/dev/null; then
    printf '{"text": "GPU: N/A", "tooltip": "NVIDIA driver not found", "class": "gpu", "percentage": 0}\n'
    exit 1
fi

# Get GPU details (querying multiple GPUs)
gpu_info=$(nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,fan.speed --format=csv,noheader,nounits 2>/dev/null)

# Check if nvidia-smi returned data
if [[ -z "$gpu_info" ]]; then
    printf '{"text": "GPU: N/A", "tooltip": "No GPU detected", "class": "gpu", "percentage": 0}\n'
    exit 1
fi

# Initialize tooltip
tooltip_text="<b>GPU Info</b>"

# Process each GPU
gpu_index=0
total_gpu_util=0  # Store the sum of GPU utilizations

while IFS=',' read -r gpu_model gpu_util gpu_temp gpu_mem_used gpu_mem_total gpu_power gpu_fan; do
    # Handle missing values by setting defaults
    gpu_util=${gpu_util:-0}
    gpu_temp=${gpu_temp:-N/A}
    gpu_mem_used=${gpu_mem_used:-0}
    gpu_mem_total=${gpu_mem_total:-N/A}
    gpu_power=${gpu_power:-N/A}
    gpu_fan=${gpu_fan:-N/A}

    # Update total GPU utilization (for multiple GPUs)
    total_gpu_util=$((total_gpu_util + gpu_util))

    # Create a simple load bar
    bar_length=10
    used_blocks=$((gpu_util * bar_length / 100))
    remaining_blocks=$((bar_length - used_blocks))
    for ((i=0; i<used_blocks; i++)); do gpu_bar+="█"; done
    for ((i=0; i<remaining_blocks; i++)); do gpu_bar+="░"; done

    # Append GPU info to tooltip
    tooltip_text+="\n<b>GPU $gpu_index:</b> $gpu_model\n"
    tooltip_text+="Usage:$gpu_util% $gpu_bar\n"
    tooltip_text+="Temp:${gpu_temp}°C | Fan:${gpu_fan}%\n"
    tooltip_text+="Power:${gpu_power} W\n"
    tooltip_text+="Memory:${gpu_mem_used} /${gpu_mem_total} MiB ($((gpu_mem_used*100/gpu_mem_total))%)\n"

    gpu_index=$((gpu_index + 1))
done <<< "$gpu_info"

# Calculate the average GPU utilization
if (( gpu_index > 0 )); then
    total_gpu_util=$((total_gpu_util / gpu_index))
else
    total_gpu_util=0
fi
# Output JSON with properly formatted percentage
printf '{"text": "󰘚 %s%%", "tooltip": "%s", "class": "gpu", "percentage": %s}\n' \
    "$total_gpu_util" "$tooltip_text" "$total_gpu_util"
