ZIG_BUILD = zig build
SET0_BIN = ./zig-out/bin/seto

.PHONY: release debug

debug:
	@$(ZIG_BUILD)
	@$(SET0_BIN)

release:
	@$(ZIG_BUILD) -Doptimize=ReleaseFast
	@$(SET0_BIN)
