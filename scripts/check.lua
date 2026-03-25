local function fail(msg)
  error("[check] " .. msg)
end

local function assert_truthy(v, msg)
  if not v then
    fail(msg)
  end
end

assert_truthy(vim.pack and vim.pack.add, "vim.pack.add is required for checks")

vim.pack.add({
  "https://github.com/Olical/nfnl",
  "https://github.com/nvim-lua/plenary.nvim",
})

local ok_nfnl, nfnl_api = pcall(require, "nfnl.api")
assert_truthy(ok_nfnl, "nfnl.api is required for checks")
nfnl_api["compile-all-files"](".")

vim.g.nix_update = {
  update_actions = { "preview", "notify" },
}

local nix_update = require("nix-update")
nix_update.init()

assert_truthy(nix_update.config["update-actions"][1] == "preview", "vim.g.nix_update did not apply")

nix_update.setup({ update_actions = { "apply", "notify" } })
assert_truthy(nix_update.config["update-actions"][1] == "apply", "setup overrides did not apply")

require("nix-update.commands").register()
assert_truthy(vim.fn.exists(":NixUpdate") == 2, ":NixUpdate command is missing")
assert_truthy(vim.fn.exists(":NixPrefetch") == 2, ":NixPrefetch command is missing")
assert_truthy(vim.fn.maparg("<Plug>(NixUpdatePrefetch)", "n") ~= "", "prefetch <Plug> map is missing")
assert_truthy(vim.fn.maparg("<Plug>(NixUpdatePrefetchBuffer)", "n") ~= "", "prefetch-buffer <Plug> map is missing")

require("nix-update.health").check()
