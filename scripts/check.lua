-- [nfnl] scripts/check.fnl
 local function fail(msg)
 return error(("[check] " .. msg)) end

 local function assert_truthy(value, msg)
 if not value then
 return fail(msg) else return nil end end

 assert_truthy((vim.pack and vim.pack.add), "vim.pack.add is required for checks")


 vim.pack.add({"https://github.com/nvim-lua/plenary.nvim"})

 vim.g.nix_update = {update_actions = {"preview", "notify"}}


 local nix_update = require("nix-update")
 local fp = require("nix-update.utils.fp")
 nix_update.init()

 assert_truthy((fp.Option.unwrap(fp.Option.pure("value")) == "value"), "Option.pure did not construct Some")


 assert_truthy((fp.Result.unwrap(fp.Result.pure("value")) == "value"), "Result.pure did not construct Ok")






 local function fn_2_(value) return (value == 1) end assert_truthy((fp.Result.unwrap(fp.Result.validate(fp.Result.ok(1), fn_2_, "wrong value")) == 1), "Result.validate did not preserve Ok")







 local function fn_3_(_) return false end assert_truthy(fp.Result["err?"](fp.Result.validate(fp.Result.ok(1), fn_3_, "wrong value")), "Result.validate did not construct Err")



 local do_tgt_5_ do local t_4_ = nix_update.config if (nil ~= t_4_) then t_4_ = t_4_["update-actions"] else end if (nil ~= t_4_) then t_4_ = t_4_[1] else end do_tgt_5_ = t_4_ end assert_truthy((do_tgt_5_ == "preview"), "vim.g.nix_update did not apply")



 nix_update.setup({update_actions = {"apply", "notify"}})
 local do_tgt_9_ do local t_8_ = nix_update.config if (nil ~= t_8_) then t_8_ = t_8_["update-actions"] else end if (nil ~= t_8_) then t_8_ = t_8_[1] else end do_tgt_9_ = t_8_ end assert_truthy((do_tgt_9_ == "apply"), "setup overrides did not apply")



 local commands = require("nix-update.commands")
 commands.register()
 assert_truthy((vim.fn.exists(":NixUpdate") == 2), ":NixUpdate command is missing")

 assert_truthy((vim.fn.exists(":NixPrefetch") == 2), ":NixPrefetch command is missing")

 assert_truthy((vim.fn.maparg("<Plug>(NixUpdatePrefetch)", "n") ~= ""), "prefetch <Plug> map is missing")

 assert_truthy((vim.fn.maparg("<Plug>(NixUpdatePrefetchBuffer)", "n") ~= ""), "prefetch-buffer <Plug> map is missing")


 local nix_parser = vim.env.NIX_UPDATE_NIX_PARSER

 if nix_parser then
 assert_truthy(vim.uv.fs_stat(nix_parser), "Nix parser is missing")
 vim.treesitter.language.add("nix", {path = nix_parser})

 local function assert_fetch_values(label, source, expected)
 local bufnr = vim.api.nvim_create_buf(false, true)
 vim.bo[bufnr].filetype = "nix"
 vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(source, "\n", {plain = true}))






 local fetches = require("nix-update.fetches")
 local found = fetches["find-used-fetches"]({bufnr = bufnr})
 assert_truthy((found and found[1]), (label .. ": fetch was not found"))


 for key, value in pairs(expected) do
 local arg do local t_12_ = found[1] if (nil ~= t_12_) then t_12_ = t_12_._fargs else end if (nil ~= t_12_) then t_12_ = t_12_[key] else end arg = t_12_ end
 assert_truthy(arg, (label .. ": missing " .. key))
 local parts = {}
 for _, fragment in ipairs(arg.fragments) do
 assert_truthy(fragment.value, (label .. ": unresolved " .. key))

 table.insert(parts, fragment.value) end
 assert_truthy((table.concat(parts) == value), (label .. ": wrong " .. key)) end return nil end


 assert_fetch_values("numeric literal", table.concat({"let version = -1.2; in fetchFromGitHub {", "  owner = \"reo101\"; repo = \"nix-update.nvim\"; rev = \"v${version}\"; hash = \"old\";", "}"}, "\n"), {rev = "v-1.2"})







 assert_fetch_values("finalAttrs stays in function binder", table.concat({"let pname = \"outer\"; version = \"outer\"; in stdenv.mkDerivation (finalAttrs: {", "  pname = \"nix-update.nvim\"; version = \"0.1.2\";", "  src = fetchFromGitHub {", "    owner = \"reo101\"; repo = finalAttrs.pname; rev = finalAttrs.version; hash = \"old\";", "  };", "})"}, "\n"), {repo = "nix-update.nvim", rev = "0.1.2"})











 assert_fetch_values("dream2nix config", table.concat({"{ config, ... }: {", "  name = \"nix-update.nvim\"; version = \"0.1.2\";", "  mkDerivation = {", "    src = config.deps.fetchFromGitHub {", "      owner = \"reo101\"; repo = config.name; rev = config.version; hash = \"old\";", "    };", "  };", "}"}, "\n"), {repo = "nix-update.nvim", rev = "0.1.2"})













 assert_fetch_values("inherited rec attrs", table.concat({"let pname = \"lighthouse\"; version = \"1.0\"; in stdenv.mkDerivation rec {", "  inherit pname version;", "  src = fetchFromGitHub {", "    owner = \"gaasedelen\"; repo = pname; rev = \"v${version}\"; hash = \"old\";", "  };", "}"}, "\n"), {repo = "lighthouse", rev = "v1.0"})











 local function assert_lua_prefetch(label, runner, expected)
 nix_update.setup({update_actions = {}, extra_prefetchers = {luaFetch = runner}})



 local bufnr = vim.api.nvim_create_buf(false, true)
 vim.bo[bufnr].filetype = "nix"
 vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {"luaFetch { url = \"https://example.com\"; hash = \"old\"; }"})



 local fetches = require("nix-update.fetches")
 local fetch = fetches["find-used-fetches"]({bufnr = bufnr})[1]
 assert_truthy(fetch, (label .. ": fetch was not found"))

 fetches["prefetch-fetch"]({bufnr = bufnr, fetch = fetch})

 local cache = require("nix-update._cache")


 local function fn_15_()
 return (cache.cache[fetch._fwhole] ~= nil) end assert_truthy(vim.wait(1000, fn_15_), (label .. ": prefetch did not finish"))

 return assert_truthy((cache.cache[fetch._fwhole].data.hash == expected), (label .. ": wrong hash")) end





 local function fn_16_(args)
 assert_truthy((args.url == "https://example.com"), "synchronous Lua prefetcher: wrong args")

 return {hash = "sync-hash"} end assert_lua_prefetch("synchronous Lua prefetcher", fn_16_, "sync-hash")




 local function fn_17_(args, done)
 assert_truthy((args.url == "https://example.com"), "asynchronous Lua prefetcher: wrong args")

 local function fn_18_()
 return done({hash = "async-hash"}) end return vim.schedule(fn_18_) end assert_lua_prefetch("asynchronous Lua prefetcher", fn_17_, "async-hash") else end


 local health = require("nix-update.health")
 return health.check()
