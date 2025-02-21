#!/bin/bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
RX_CACHE="$CACHE_DIR/network_rx_total"
TX_CACHE="$CACHE_DIR/network_tx_total"
TIME_CACHE="$CACHE_DIR/network_last_time"

update() {
    sum=0
    for arg; do
        read -r i < "$arg"
        sum=$(( sum + i ))
    done
    cache="${CACHE_DIR}/${1##*/}"
    [ -f "$cache" ] && read -r old < "$cache" || old=0
    printf %d\\n "$sum" > "$cache"
    printf %d\\n $(( sum - old ))
}

# Get current time in seconds
current_time=$(date +%s)
[ -f "$TIME_CACHE" ] && read -r last_time < "$TIME_CACHE" || last_time=$current_time
elapsed_time=$(( current_time - last_time ))
echo "$current_time" > "$TIME_CACHE"

# Get network speeds
rx_bytes=$(update /sys/class/net/[ew]*/statistics/rx_bytes)
tx_bytes=$(update /sys/class/net/[ew]*/statistics/tx_bytes)

# Avoid division by zero
if [ "$elapsed_time" -gt 0 ]; then
    rx_speed=$(( rx_bytes / elapsed_time ))
    tx_speed=$(( tx_bytes / elapsed_time ))
else
    rx_speed=0
    tx_speed=0
fi

# Get total session upload/download
[ -f "$RX_CACHE" ] && read -r total_rx < "$RX_CACHE" || total_rx=0
[ -f "$TX_CACHE" ] && read -r total_tx < "$TX_CACHE" || total_tx=0
total_rx=$(( total_rx + rx_bytes ))
total_tx=$(( total_tx + tx_bytes ))
echo "$total_rx" > "$RX_CACHE"
echo "$total_tx" > "$TX_CACHE"

# Get active interfaces
interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(w|e)')

# Identify connection type
if ip link show | grep -q "wlan"; then
    connection_type="Wi-Fi"
elif ip link show | grep -q "eth"; then
    connection_type="Ethernet"
else
    connection_type="Unknown"
fi

# Get private (LAN) IP
private_ip=$(ip -4 addr show scope global | awk '/inet/ {print $2}' | cut -d/ -f1 | head -n 1)

# Get public (WAN) IP
public_ip=$(curl -s --max-time 2 ifconfig.me || echo "N/A")

# Measure ping latency
latency=$(ping -c 1 -W 1 8.8.8.8 | awk -F'/' 'END {print ($5 ? $5 " ms" : "N/A")}' 2>/dev/null)

# Format output using numfmt
rx_speed_fmt=$(numfmt --to=iec --suffix=B $rx_speed 2>/dev/null || echo "N/A")
tx_speed_fmt=$(numfmt --to=iec --suffix=B $tx_speed 2>/dev/null || echo "N/A")
total_rx_fmt=$(numfmt --to=iec --suffix=B $total_rx 2>/dev/null || echo "N/A")
total_tx_fmt=$(numfmt --to=iec --suffix=B $total_tx 2>/dev/null || echo "N/A")


# Construct tooltip text
tooltip="<b>Network Info</b>\n"
tooltip+="Connection: $connection_type\n"
tooltip+="Interfaces: $interfaces\n"
tooltip+="Private IP: $private_ip\n"
tooltip+="Public IP: $public_ip\n"
tooltip+="Ping: $latency\n"
tooltip+="Speed: ↓ $rx_speed_fmt | ↑ $tx_speed_fmt\n"
tooltip+="Session Total: ↓ $total_rx_fmt | ↑ $total_tx_fmt"

# Output JSON for UI
printf '{"text": " %s  %s", "tooltip": "%s", "class": "network"}\n' "$rx_speed_fmt" "$tx_speed_fmt" "$tooltip"
