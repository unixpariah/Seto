ZIG_BUILD = zig build
SET0_BIN = ./zig-out/bin/seto
VALGRIND = valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes

.PHONY: run release debug

run:
	@$(ZIG_BUILD)
	@$(SET0_BIN)

release:
	@$(ZIG_BUILD) -Doptimize=ReleaseSmall
	@$(SET0_BIN)

valgrind:
	@$(ZIG_BUILD)
	@$(VALGRIND) $(SET0_BIN)
