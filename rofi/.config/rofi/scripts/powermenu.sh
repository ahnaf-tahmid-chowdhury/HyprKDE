#!/usr/bin/env bash

# Theme for Rofi
theme="../themes/powermenu.rasi"

# Icons
declare -A icons=(
    [shutdown]='󰤆'
    [reboot]=''
    [lock]=''
    [suspend]='󰒲'
    [logout]='󰍃'
    [yes]='  Yes'
    [no]='  No'
    [user]=''
    [clock]=''
    [uptime]=''
)

# Get battery info (if available)
get_battery_info() {
    local battery_path="/sys/class/power_supply/BAT0/capacity"
    [[ -f "$battery_path" ]] && echo "|   $(cat "$battery_path")%"
}

# Rofi Command
rofi_cmd() {
    local uptime=$(uptime -p | sed 's/up //g')
    local host=$(uname -n)
    local user=$(whoami)
    local datetime=$(date +"%A, %B %d - %I:%M %p")
    local battery_info=$(get_battery_info)

    rofi -dmenu \
        -mesg "${icons[user]} $user@$host | ${icons[uptime]} $uptime $battery_info" \
        -theme "$theme"
}

# Confirmation Prompt
confirm_cmd() {
    rofi -theme-str 'listview {columns: 2; lines: 1;}' \
         -theme-str 'element-text {horizontal-align: 0.5; font:"feather 20";}' \
         -dmenu \
         -mesg 'Are you sure?' \
         -theme "$theme"
}

# Confirmation Check
confirm_exit() {
    echo -e "${icons[yes]}\n${icons[no]}" | confirm_cmd
}

# Show Menu
run_rofi() {
    echo -e "${icons[lock]}\n${icons[suspend]}\n${icons[logout]}\n${icons[reboot]}\n${icons[shutdown]}" | rofi_cmd
}

# Execute Commands
run_cmd() {
    local selected=$(confirm_exit)
    [[ "$selected" != "${icons[yes]}" ]] && exit 0

    case $1 in
        --shutdown) systemctl poweroff ;;
        --reboot) systemctl reboot ;;
        --suspend) 
            mpc -q pause &>/dev/null
            amixer set Master mute &>/dev/null
            systemctl suspend 
            ;;
        --logout) 
            case "$DESKTOP_SESSION" in
                hyprland) hyprctl dispatch exit ;;
                plasma) qdbus org.kde.ksmserver /KSMServer logout 0 0 0 ;;
                *) pkill -KILL -u "$USER" ;;
            esac
            ;;
    esac
}

# Process Selection
case $(run_rofi) in
    ${icons[shutdown]}) run_cmd --shutdown ;;
    ${icons[reboot]}) run_cmd --reboot ;;
    ${icons[lock]}) hyprlock ;;
    ${icons[suspend]}) run_cmd --suspend ;;
    ${icons[logout]}) run_cmd --logout ;;
esac
