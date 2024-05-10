ZIG_BUILD = zig build
SET0_BIN = ./zig-out/bin/seto

.PHONY: release debug

debug: $(SET0_BIN)
	@$(ZIG_BUILD)
	@$(SET0_BIN)

release: $(SET0_BIN)
	@$(ZIG_BUILD) -Doptimize=ReleaseSmall
	@$(SET0_BIN)
