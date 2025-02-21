#!/usr/bin/env bash

theme="../themes/menu.rasi"

if pgrep -x "rofi" > /dev/null; then
    pkill "rofi"
else
    ## Run
    rofi \
        -show drun \
        -theme ${theme}
fi
