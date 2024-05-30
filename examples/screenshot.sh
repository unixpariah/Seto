#!/bin/sh

grim -g "$(../zig-out/bin/seto -r)" - | wl-copy -t image/png
