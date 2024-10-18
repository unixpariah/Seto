#!/bin/sh

GRID_SIZE=80
tests_passed=0
tests_failed=0
failed_tests=""

run_seto_and_test() {
    local direction=$1
    local move_distance=$2
    local key_press=$3
    local test_name="   - Direction: $direction, Distance: $move_distance"

    ./zig-out/bin/seto -c null -F $direction move $move_distance >/dev/null 2>&1 &
    SETO_PID=$!
    disown $SETO_PID

    sleep 1

    ydotool key 42:1 $key_press:1
    sleep 3
    ydotool key $key_press:0 42:0

    if ps -p $SETO_PID >/dev/null; then
        kill $SETO_PID
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
        failed_tests="$failed_tests\n$test_name"
    fi
}

test_move_left() {
    run_seto_and_test H "-3,0" 35
    run_seto_and_test H "-5,0" 35
    run_seto_and_test H "-$GRID_SIZE,0" 35
    run_seto_and_test H "-$(((GRID_SIZE + GRID_SIZE * 2) / 2)),0" 35
    run_seto_and_test H "-$((GRID_SIZE * 2)),0" 35
}

test_move_right() {
    run_seto_and_test L "3,0" 38
    run_seto_and_test L "5,0" 38
    run_seto_and_test L "$GRID_SIZE,0" 38
    run_seto_and_test L "$(((GRID_SIZE + GRID_SIZE * 2) / 2)),0" 38
    run_seto_and_test L "$((GRID_SIZE * 2)),0" 38
}

test_move_down() {
    run_seto_and_test J "0,3" 36
    run_seto_and_test J "0,5" 36
    run_seto_and_test J "0,$GRID_SIZE" 36
    run_seto_and_test J "0,$(((GRID_SIZE + GRID_SIZE * 2) / 2))" 36
    run_seto_and_test J "0,$((GRID_SIZE * 2))" 36
}

test_move_up() {
    run_seto_and_test K "0,-3" 37
    run_seto_and_test K "0,-5" 37
    run_seto_and_test K "0,-$GRID_SIZE" 37
    run_seto_and_test K "0,-$(((GRID_SIZE + GRID_SIZE * 2) / 2))" 37
    run_seto_and_test K "0,-$((GRID_SIZE * 2))" 37
}

# Run all tests
test_move_left
test_move_right
test_move_down
test_move_up

echo "Move Tests: $tests_passed/$((tests_passed + tests_failed))"

if [ $tests_failed -gt 0 ]; then
    echo -e "Failed Tests: $failed_tests"
fi
