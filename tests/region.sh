#!/bin/sh

./zig-out/bin/seto -r -c null &
SETO_PID=$!

sleep 1

ydotool type aaa

if ! kill -0 $SETO_PID 2>/dev/null; then
    exit 1
fi

ydotool type aaa

if kill -0 $SETO_PID 2>/dev/null; then
    exit 1
fi
