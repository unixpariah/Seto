#!/bin/sh

./zig-out/bin/seto -r -c ./tests -f $'x: %x, x: %x, y: %y, width: %w, height: %h' &
SETO_PID=$!

sleep 0.1

ydotool type
