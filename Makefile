.PHONY: run

all:
	@zig build

run: all
	@./zig-out/bin/seto

leak: all
	valgrind --leak-check=full ./zig-out/bin/seto
