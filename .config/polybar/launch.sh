#!/bin/bash

killall -q polybar

while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

polybar main --config=~/.config/polybar/config.ini &
polybar second --config=~/.config/polybar/config.ini &

echo "Polybar launched..."
