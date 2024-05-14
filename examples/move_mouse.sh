#!/bin/sh

# Make sure to turn off mouse acceleration before running

ydotoold >/dev/null 2>&1 & # Start ydotool daemon

sleep 0.1 # Sleep to make sure that ydotool daemon has started

OUTPUT=$(../zig-out/bin/seto) # Run seto and save the stdout

IFS=',' read -ra coordinates <<< "$OUTPUT" # Split output at ',' character

ydotool mousemove -a ${coordinates[0]} ${coordinates[1]} # Use ydotool to move mouse

pkill ydotoold # Kill ydotool daemon
