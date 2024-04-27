.PHONY: run

run:
	@zig build
	@./zig-out/bin/sip
