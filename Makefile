.PHONY: run

all:
	@zig build

run: all
	@./zig-out/bin/seto
