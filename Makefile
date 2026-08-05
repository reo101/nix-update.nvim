FENNEL ?= fennel
FENNEL_FLAGS ?= --correlate --add-macro-path '$(SRC_DIR)/?.fnlm'

SRC_DIR ?= fnl
RES_DIR ?= lua

FNL_SRC = $(shell find $(SRC_DIR) -type f -name "*.fnl" -and -not -iname "*macro*")

LUA_RES = $(patsubst $(SRC_DIR)/%.fnl,$(RES_DIR)/%.lua,$(FNL_SRC))

all: $(LUA_RES)

check:
	nvim --headless -u NONE -c 'set rtp+=.' -c 'lua dofile("scripts/check.lua")' -c 'qall!'

check-ci:
	nix develop .#ci -c $(MAKE) check

fennel: all

$(RES_DIR)/%.lua: $(SRC_DIR)/%.fnl
	@mkdir -p $(shell dirname $@)
	@echo "Compiling '$(<)' into '$(@)'"
	@{ printf '%s\n' '-- [nfnl] $<'; $(FENNEL) $(FENNEL_FLAGS) --compile $<; } >$@.tmp && mv $@.tmp $@

clean:
	rm -rf $(RES_DIR)

love:
	@echo "not war"
