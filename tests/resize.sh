#!/bin/sh

GRID_SIZE=80
tests_passed=0
tests_failed=0
failed_tests=""

run_seto_and_test() {
	local resize_distance=$1
	local test_name="   - $resize_distance"

	./zig-out/bin/seto -c null -F a resize $resize_distance >/dev/null 2>&1 &
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

test_resize_left() {
	run_seto_and_test "-3,0"
	run_seto_and_test "-5,0"
	run_seto_and_test "-$GRID_SIZE,0"
}

test_resize_right() {
	run_seto_and_test "3,0"
	run_seto_and_test "5,0"
	run_seto_and_test "$GRID_SIZE,0"
}

test_resize_down() {
	run_seto_and_test "0,3"
	run_seto_and_test "0,5"
	run_seto_and_test "0,$GRID_SIZE"
}

test_resize_up() {
	run_seto_and_test "0,-3"
	run_seto_and_test "0,-5"
	run_seto_and_test "0,-$GRID_SIZE"
}

# Run all tests
test_resize_left
test_resize_right
test_resize_down
test_resize_up

echo "Resize Tests: $tests_passed/$((tests_passed + tests_failed))"

if [ $tests_failed -gt 0 ]; then
	echo -e "Failed Tests: $failed_tests"
fi
