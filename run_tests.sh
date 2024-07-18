#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
	echo "Tests need to be ran as root"
	exit 1
fi

ydotoold >/dev/null 2>&1 &

while ! pgrep -x "ydotoold" >/dev/null; do
	sleep 0.1
done

sleep 1

OUTPUT=$(./tests/single.sh)

if [ "$OUTPUT" != "0,0 1x1" ]; then
	echo "Expected output \"0,0 1x1\", got $OUTPUT"
	exit 1
fi

OUTPUT=$(./tests/region.sh)

if [ "$OUTPUT" != "0,0 1x1" ]; then
	echo "Expected output \"0,0 1x1\", got $OUTPUT"
	exit 1
fi

pkill ydotool
