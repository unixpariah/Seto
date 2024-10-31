#!/bin/sh

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
	sleep 2
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
	for i in $(seq 1 5); do
		run_seto_and_test "-$i,0"
	done
}

test_resize_right() {
	for i in $(seq 1 5); do
		run_seto_and_test "$i,0"
	done
}

test_resize_down() {
	for i in $(seq 1 5); do
		run_seto_and_test "0,$i"
	done
}

test_resize_up() {
	for i in $(seq 1 5); do
		run_seto_and_test "0,-$i"
	done
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
