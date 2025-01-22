#!/bin/sh

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

./tests/move.sh
./tests/resize.sh
