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

local nix_parser = vim.env.NIX_UPDATE_NIX_PARSER
if nix_parser then
  assert_truthy(vim.uv.fs_stat(nix_parser), "Nix parser is missing")
  vim.treesitter.language.add("nix", { path = nix_parser })

  local function assert_fetch_values(label, source, expected)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].filetype = "nix"
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(source, "\n", { plain = true }))

    local fetches = require("nix-update.fetches")
    local found = fetches["find-used-fetches"]({ bufnr = bufnr })
    assert_truthy(found and found[1], label .. ": fetch was not found")

    for key, value in pairs(expected) do
      local arg = found[1]._fargs[key]
      assert_truthy(arg, label .. ": missing " .. key)
      local parts = {}
      for _, fragment in ipairs(arg.fragments) do
        assert_truthy(fragment.value, label .. ": unresolved " .. key)
        parts[#parts + 1] = fragment.value
      end
      assert_truthy(table.concat(parts) == value, label .. ": wrong " .. key)
    end
  end

  assert_fetch_values("numeric literal", [[
let version = -1.2; in fetchFromGitHub {
  owner = "reo101"; repo = "nix-update.nvim"; rev = "v${version}"; hash = "old";
}
]], { rev = "v-1.2" })

  assert_fetch_values("finalAttrs", [[
stdenv.mkDerivation (finalAttrs: {
  pname = "nix-update.nvim"; version = "0.1.2";
  src = fetchFromGitHub {
    owner = "reo101"; repo = finalAttrs.pname; rev = finalAttrs.version; hash = "old";
  };
})
]], { repo = "nix-update.nvim", rev = "0.1.2" })

  assert_fetch_values("dream2nix config", [[
{ config, ... }: {
  name = "nix-update.nvim"; version = "0.1.2";
  mkDerivation = {
    src = config.deps.fetchFromGitHub {
      owner = "reo101"; repo = config.name; rev = config.version; hash = "old";
    };
  };
}
]], { repo = "nix-update.nvim", rev = "0.1.2" })

  assert_fetch_values("inherited rec attrs", [[
let pname = "lighthouse"; version = "1.0"; in stdenv.mkDerivation rec {
  inherit pname version;
  src = fetchFromGitHub {
    owner = "gaasedelen"; repo = pname; rev = "v${version}"; hash = "old";
  };
}
]], { repo = "lighthouse", rev = "v1.0" })
end

require("nix-update.health").check()
