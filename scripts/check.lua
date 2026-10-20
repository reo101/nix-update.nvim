-- [nfnl] scripts/check.fnl
 local function fail(msg)
 return error(("[check] " .. msg)) end

 local function assert_truthy(value, msg)
 if not value then
 return fail(msg) else return nil end end

 assert_truthy((vim.async and vim.async.run and vim.async.await), "vim.async is required for checks")


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



 local _local_12_ = require("nix-update.utils") local call_command = _local_12_["call-command"]
 local command_task

 local function hashfn_13_() local _let_14_ = call_command({cmd = "printf", args = {"async-ok\\n"}}) local stdout = _let_14_.stdout


 assert_truthy((table.concat(stdout) == "async-ok"), "vim.async command prefetch did not finish")

 return assert_truthy(not vim.in_fast_event(), "command completion resumed in a fast event") end command_task = vim.async.run(hashfn_13_) command_task:wait(1000)



 local _local_15_ = require("nix-update.utils") local prefetcher_mt = _local_15_["prefetcher-mt"]
 do local original_notify = vim.notify
 local notifications = {} local called_3f = false

 local prefetcher


 local function fn_16_(_) called_3f = true return nil end prefetcher = setmetatable({["required-cmds"] = {"nix-update-nonexistent-prefetch-command"}, prefetcher = fn_16_}, prefetcher_mt)

 local function hashfn_17_(_241) return table.insert(notifications, _241) end vim.notify = hashfn_17_
 local ok, result = pcall(prefetcher, {})
 vim.notify = original_notify
 assert_truthy(ok, "missing command validation raised an error")
 assert_truthy((result == nil), "missing command validation did not abort")
 assert_truthy(not called_3f, "prefetcher ran without its required command")
 assert_truthy((notifications[1] == "Missing commands: nix-update-nonexistent-prefetch-command"), "missing command diagnostic is incorrect") end



 do local expected = {cmd = vim.v.progpath, args = {}} local prefetcher


 local function fn_18_(_) return expected end prefetcher = setmetatable({["required-cmds"] = {vim.v.progpath}, prefetcher = fn_18_}, prefetcher_mt)

 assert_truthy((prefetcher({}) == expected), "available command validation blocked the prefetcher") end


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
 local arg do local t_19_ = found[1] if (nil ~= t_19_) then t_19_ = t_19_._fargs else end if (nil ~= t_19_) then t_19_ = t_19_[key] else end arg = t_19_ end
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
















 local function fn_22_(_) return {cmd = "printf", args = {"command-hash"}} end
 local function fn_23_(stdout) return {hash = stdout[1]} end nix_update.setup({update_actions = {"apply"}, extra_prefetchers = {commandFetch = {["required-cmds"] = {"printf"}, prefetcher = fn_22_, extractor = fn_23_}}})
 do local bufnr = vim.api.nvim_create_buf(false, true)
 local fetches = require("nix-update.fetches")
 vim.bo[bufnr].filetype = "nix"
 vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {"commandFetch { hash = \"old\"; }"})


 local fetch = fetches["find-used-fetches"]({bufnr = bufnr})[1]
 local task = fetches["prefetch-fetch"]({bufnr = bufnr, fetch = fetch}) task:wait(1000)

 assert_truthy((vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1] == "commandFetch { hash = \"command-hash\"; }"), "command prefetch did not update the buffer") end




 local function assert_lua_prefetch(label, runner, expected)
 nix_update.setup({update_actions = {"apply"}, extra_prefetchers = {luaFetch = runner}})



 local bufnr = vim.api.nvim_create_buf(false, true)
 vim.bo[bufnr].filetype = "nix"
 vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {"luaFetch { url = \"https://example.com\"; hash = \"old\"; }"})



 local fetches = require("nix-update.fetches")
 local fetch = fetches["find-used-fetches"]({bufnr = bufnr})[1]
 assert_truthy(fetch, (label .. ": fetch was not found"))

 local task = fetches["prefetch-fetch"]({bufnr = bufnr, fetch = fetch}) task:wait(1000)


 local cache = require("nix-update._cache")
 local do_tgt_25_ do local t_24_ = cache.cache if (nil ~= t_24_) then t_24_ = t_24_[fetch._fwhole] else end if (nil ~= t_24_) then t_24_ = t_24_.data else end if (nil ~= t_24_) then t_24_ = t_24_.hash else end do_tgt_25_ = t_24_ end assert_truthy((do_tgt_25_ == expected), (label .. ": wrong hash"))


 return assert_truthy((vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1] == string.format("luaFetch { url = \"https://example.com\"; hash = \"%s\"; }", expected)), (label .. ": buffer was not updated")) end






 local function fn_29_(args)
 assert_truthy((args.url == "https://example.com"), "synchronous Lua prefetcher: wrong args")

 return {hash = "sync-hash"} end assert_lua_prefetch("synchronous Lua prefetcher", fn_29_, "sync-hash")




 local function fn_30_(args, done)
 assert_truthy((args.url == "https://example.com"), "asynchronous Lua prefetcher: wrong args")

 local function hashfn_31_() return done({hash = "async-hash"}) end return vim.schedule(hashfn_31_) end assert_lua_prefetch("asynchronous Lua prefetcher", fn_30_, "async-hash")




 local function fn_32_(_args, done)
 local timer = vim.uv.new_timer()

 local function fn_33_() timer:close()

 return done({hash = "timer-hash"}) end timer:start(0, 0, fn_33_)
 return nil end assert_lua_prefetch("fast-event Lua prefetcher", fn_32_, "timer-hash") else end


 local health = require("nix-update.health")
 return health.check()
