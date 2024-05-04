ZIG_BUILD = zig build
SET0_BIN = ./zig-out/bin/seto
VALGRIND = valgrind --leak-check=full \
          			--show-leak-kinds=all \
          			--track-origins=yes \
          			--verbose \
          			$(SET0_BIN)

.PHONY: run release debug valgrind

run: $(SET0_BIN)
	@$(SET0_BIN)

debug: $(SET0_BIN)
	@$(ZIG_BUILD)

release: $(SET0_BIN)
	@$(ZIG_BUILD) -Doptimize=ReleaseSmall

valgrind: $(SET0_BIN)
	@$(ZIG_BUILD)
	@$(VALGRIND)
