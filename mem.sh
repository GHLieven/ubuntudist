#!/bin/bash

echo "RAM" $(free -m | awk 'FNR == 2 {print $3}')
echo "BAT" $(upower -i /org/freedesktop/UPower/devices/battery_BAT | grep -E --color=never -E percentage | xargs | cut -d' ' -f2|sed s/%//)
