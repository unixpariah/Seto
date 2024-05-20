#!/bin/sh

# Before I add a way to mark multiple points this is the way to take screenshots using grim

FIRST=$(../zig-out/bin/seto) # Run seto and save the stdout
IFS=',' read -ra first_coordinates <<< "$FIRST" # Split output at ',' character

SECOND=$(../zig-out/bin/seto) # Run seto for the second time and save the stdout
IFS=',' read -ra second_coordinates <<< "$SECOND" # Split output at ',' character

# Convert coordinates to integers and perform subtraction
x_diff=$((first_coordinates[0] - second_coordinates[0]))
y_diff=$((first_coordinates[1] - second_coordinates[1]))

if [[ "$y_diff" -eq 0 || "$x_diff" -eq 0 ]] ; then
    echo "Can't have 0 width or height"
    exit 1
fi

# Take absolutes of coordinates
if [ "$x_diff" -lt 0 ]; then
    x_diff=$(( -x_diff ))
fi

if [ "$y_diff" -lt 0 ]; then
    y_diff=$(( -y_diff ))
fi

# Determine top left coordinates
if [ "${first_coordinates[0]}" -le "${second_coordinates[0]}" ] && [ "${first_coordinates[1]}" -le "${second_coordinates[1]}" ]; then
    top_left_x=${first_coordinates[0]}
    top_left_y=${first_coordinates[1]}
else
    top_left_x=${second_coordinates[0]}
    top_left_y=${second_coordinates[1]}
fi

# Format coordinates
end="${top_left_x},${top_left_y} ${x_diff}x${y_diff}"

#sleep 1 # Make sure that seto isnt still on the screen TODO: fix

grim -g "$end" - | wl-copy -t image/png
