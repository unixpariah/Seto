#!/bin/sh

GRID_SIZE=80
tests_passed=0
tests_failed=0
failed_tests=""

run_seto_and_test() {
	local move_distance=$1
	local test_name="   - $move_distance"

	./zig-out/bin/seto -c null -F a move $move_distance >/dev/null 2>&1 &
	SETO_PID=$!
	disown $SETO_PID

	sleep 1

	ydotool key 30:1
	sleep 3
	ydotool key 30:0

	if ps -p $SETO_PID >/dev/null; then
		kill $SETO_PID
		tests_passed=$((tests_passed + 1))
	else
		tests_failed=$((tests_failed + 1))
		failed_tests="$failed_tests\n$test_name"
	fi
}

test_move_left() {
	run_seto_and_test "-3,0"
	run_seto_and_test "-5,0"
	run_seto_and_test "-$GRID_SIZE,0"
	run_seto_and_test "-$(((GRID_SIZE + GRID_SIZE * 2) / 2)),0"
	run_seto_and_test "-$((GRID_SIZE * 2)),0"
}

test_move_right() {
	run_seto_and_test "3,0"
	run_seto_and_test "5,0"
	run_seto_and_test "$GRID_SIZE,0"
	run_seto_and_test "$(((GRID_SIZE + GRID_SIZE * 2) / 2)),0"
	run_seto_and_test "$((GRID_SIZE * 2)),0"
}

test_move_down() {
	run_seto_and_test "0,3"
	run_seto_and_test "0,5"
	run_seto_and_test "0,$GRID_SIZE"
	run_seto_and_test "0,$(((GRID_SIZE + GRID_SIZE * 2) / 2))"
	run_seto_and_test "0,$((GRID_SIZE * 2))"
}

test_move_up() {
	run_seto_and_test "0,-3"
	run_seto_and_test "0,-5"
	run_seto_and_test "0,-$GRID_SIZE"
	run_seto_and_test "0,-$(((GRID_SIZE + GRID_SIZE * 2) / 2))"
	run_seto_and_test "0,-$((GRID_SIZE * 2))"
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
