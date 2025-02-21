#!/bin/bash

# Check if kmix is running
if pgrep -x "kmix" > /dev/null; then
    # If running, kill it
    pkill -x "kmix"
else
    # If not running, start it
    kmix --nosystemtray --keepvisibility &
fi
