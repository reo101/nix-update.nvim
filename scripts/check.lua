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



 local _local_15_ = require("nix-update.utils") local prefetcher_mt = _local_15_["prefetcher-mt"] local called_3f = false

 do local prefetcher

 local function fn_16_(_) called_3f = true return nil end prefetcher = setmetatable({["required-cmds"] = {"nix-update-nonexistent-prefetch-command"}, prefetcher = fn_16_}, prefetcher_mt)

 local task = prefetcher({})
 assert_truthy((type(task) == "table"), "command prefetcher did not return a task") local ok, err = task:pwait(1000)

 assert_truthy(not ok, "missing command task did not fail")
 assert_truthy(not called_3f, "prefetcher ran without its required command")
 assert_truthy(string.find(err, "Missing commands: nix-update-nonexistent-prefetch-command", 1, true), "missing command diagnostic is incorrect") end



 do local prefetcher

 local function fn_17_(_) return {cmd = "printf", args = {"command-hash"}} end
 local function fn_18_(stdout) return {hash = stdout[1]} end prefetcher = setmetatable({["required-cmds"] = {"printf"}, prefetcher = fn_17_, extractor = fn_18_}, prefetcher_mt)

 local task = prefetcher({})
 assert_truthy((task:wait(1000).hash == "command-hash"), "command task did not extract its result") end


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











 local function start_prefetch(prefetcher)
 vim.g.nix_update = nil
 nix_update.setup({update_actions = {"apply"}, extra_prefetchers = {taskFetch = prefetcher}})


 local bufnr = vim.api.nvim_create_buf(false, true)
 vim.bo[bufnr].filetype = "nix"
 vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {"taskFetch { url = \"https://example.com\"; hash = \"old\"; }"})


 local fetches = require("nix-update.fetches")
 local fetch = fetches["find-used-fetches"]({bufnr = bufnr})[1]
 assert_truthy(fetch, "task prefetch: fetch was not found")
 return {bufnr = bufnr, fetch = fetch, task = fetches["prefetch-fetch"]({bufnr = bufnr, fetch = fetch})} end


 local function assert_task_prefetch(label, prefetcher, expected)
 local _let_22_ = start_prefetch(prefetcher) local bufnr = _let_22_.bufnr local fetch = _let_22_.fetch local task = _let_22_.task
 local _let_23_ = require("nix-update._cache") local cache = _let_23_.cache task:wait(1000)

 local do_tgt_25_ do local t_24_ = cache if (nil ~= t_24_) then t_24_ = t_24_[fetch._fwhole] else end if (nil ~= t_24_) then t_24_ = t_24_.data else end if (nil ~= t_24_) then t_24_ = t_24_.hash else end do_tgt_25_ = t_24_ end assert_truthy((do_tgt_25_ == expected), (label .. ": wrong hash"))

 return assert_truthy((vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1] == string.format("taskFetch { url = \"https://example.com\"; hash = \"%s\"; }", expected)), (label .. ": buffer was not updated")) end







 local function fn_29_(_) return {cmd = "printf", args = {"command-hash"}} end
 local function fn_30_(stdout) return {hash = stdout[1]} end assert_task_prefetch("command table", {["required-cmds"] = {"printf"}, prefetcher = fn_29_, extractor = fn_30_}, "command-hash")




 local function fn_31_(args)

 local function fn_32_()
 assert_truthy((args.url == "https://example.com"), "task received wrong args")
 return {hash = "task-hash"} end return vim.async.run(fn_32_) end assert_task_prefetch("immediate task", fn_31_, "task-hash")




 local function fn_33_(_)

 local function fn_34_()
 vim.async.sleep(1)
 local _local_35_ = call_command({cmd = "printf", args = {"awaited-hash"}}) local stdout = _local_35_.stdout
 return {hash = stdout[1]} end return vim.async.run(fn_34_) end assert_task_prefetch("awaiting task", fn_33_, "awaited-hash")




 local function fn_36_(_)

 local function fn_37_()

 local function fn_38_(done)
 local timer = vim.uv.new_timer()

 local function fn_39_() timer:close()

 return done() end timer:start(0, 0, fn_39_)
 return nil end vim.async.await(fn_38_)
 assert_truthy(vim.in_fast_event(), "timer did not resume in a fast event")
 return {hash = "timer-hash"} end return vim.async.run(fn_37_) end assert_task_prefetch("fast-event task", fn_36_, "timer-hash")


 local function assert_prefetch_error(label, prefetcher, expected)
 local _let_40_ = start_prefetch(prefetcher) local bufnr = _let_40_.bufnr local fetch = _let_40_.fetch local task = _let_40_.task
 local _let_41_ = require("nix-update._cache") local cache = _let_41_.cache task:wait(1000)

 local err do local t_42_ = cache if (nil ~= t_42_) then t_42_ = t_42_[fetch._fwhole] else end if (nil ~= t_42_) then t_42_ = t_42_.err else end err = t_42_ end
 assert_truthy((err and string.find(err, expected, 1, true)), (label .. ": wrong error"))

 return assert_truthy((vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1] == "taskFetch { url = \"https://example.com\"; hash = \"old\"; }"), (label .. ": modified the buffer on failure")) end






 local function fn_45_(_) local function hashfn_46_() return error("task failure") end return vim.async.run(hashfn_46_) end assert_prefetch_error("failed task", fn_45_, "task failure")



 local function fn_47_(_) return error("factory failure") end assert_prefetch_error("factory failure", fn_47_, "factory failure")



 local function fn_48_(_) return {hash = "not-a-task"} end assert_prefetch_error("synchronous field return", fn_48_, "Invalid arguments, expected Task")



 local function fn_49_(_, done) return done({hash = "not-a-task"}) end assert_prefetch_error("callback prefetcher", fn_49_, "nil value")



 local function fn_50_(_) local function hashfn_51_() return nil end return vim.async.run(hashfn_51_) end assert_prefetch_error("invalid task result", fn_50_, "Prefetch task must return a table of fields")



 local function fn_52_(_) local function hashfn_53_() return {hash = 1} end return vim.async.run(hashfn_53_) end assert_prefetch_error("invalid field value", fn_52_, "Prefetch task fields must have string keys and values")




 local function fn_54_(_) return error("must not run") end
 local function fn_55_(_) return {} end assert_prefetch_error("missing fetch key", {["required-keys"] = {"owner"}, prefetcher = fn_54_, extractor = fn_55_}, "Missing keys: owner")



 local function fn_56_(_) return {cmd = "sh", args = {"-c", "printf failure >&2; printf output; exit 7"}} end
 local function fn_57_(_) return error("must not extract failed output") end assert_prefetch_error("command failure", {prefetcher = fn_56_, extractor = fn_57_}, "exited with code 7: failure")



 local function fn_58_(_) return {cmd = "printf", args = {"output"}} end
 local function fn_59_(_) return error("extractor failure") end assert_prefetch_error("extractor failure", {prefetcher = fn_58_, extractor = fn_59_}, "extractor failure")


 local prefetch_task = nil local finished_3f = false



 local function fn_60_(_)


 local function fn_61_()
 vim.async.sleep(10000) finished_3f = true

 return {hash = "cancelled-hash"} end prefetch_task = vim.async.run(fn_61_)
 return prefetch_task end local _let_62_ = start_prefetch(fn_60_) local fetch = _let_62_.fetch local task = _let_62_.task
 local _let_63_ = require("nix-update._cache") local cache = _let_63_.cache task:close()

 do local ok, err = task:pwait(1000)
 assert_truthy((not ok and (err == "closed")), "request did not cancel") end
 assert_truthy(prefetch_task:completed(), "cancelled child task did not finish")
 assert_truthy(not finished_3f, "cancelled child task continued")
 assert_truthy((cache[fetch._fwhole] == nil), "cancelled request wrote to the cache") else end


 local health = require("nix-update.health")
 return health.check()
