#!/bin/sh

# Make sure to turn off mouse acceleration before running

sudo ydotoold >/dev/null 2>&1 & # Start ydotool daemon

# Wait for ydotoold to start by checking the process list
while ! pgrep -x "ydotoold" > /dev/null; do
    sleep 0.1
done

OUTPUT=$(../zig-out/bin/seto) # Run seto and save the stdout

IFS=',' read -ra coordinates <<< "$OUTPUT" # Split output at ',' character

sudo ydotool mousemove -a ${coordinates[0]} ${coordinates[1]} # Use ydotool to move mouse

sudo pkill ydotoold # Kill ydotool daemon
