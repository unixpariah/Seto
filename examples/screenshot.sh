#!/bin/sh

# Before I add a way to mark multiple points this is the way to take screenshots using grim

RESULT=$(../zig-out/bin/seto -r) # Run seto and save the stdout

grim -g "$RESULT" - | wl-copy -t image/png
