FENNEL ?= fennel
FENNEL_FLAGS ?= --correlate --no-compiler-sandbox --add-macro-path $(SRC_DIR)

SRC_DIR ?= fnl
RES_DIR ?= lua

FNL_SRC    = $(shell find $(SRC_DIR) -type f -name "*.fnl" -and -not -iname "*macro*")
FNL_MACROS = $(shell find $(SRC_DIR) -type f -name "*macro*.fnl")

LUA_RES = $(patsubst $(SRC_DIR)/%.fnl,$(RES_DIR)/%.lua,$(FNL_SRC))

all: $(LUA_RES)

$(RES_DIR)/%.lua: $(SRC_DIR)/%.fnl
	@mkdir -p $(shell dirname $@)
	@echo "Compiling '$(<)' into '$(@)'"
	@$(FENNEL) \
		--correlate \
		--no-compiler-sandbox \
		--add-macro-path $(FNL_MACROS) \
		--compile $(<) > $(@)

clean:
	rm -rf $(RES_DIR)

love:
	@echo "not war"
