-- [nfnl] fnl/nix-update/utils/mt.fnl
 local _local_1_ = require("nix-update.utils.common") local missing_keys = _local_1_["missing-keys"]


 local _local_2_ = require("nix-update.utils.command") local call_command = _local_2_["call-command"]


 local function create_proxied()
 local raw = {}
 local on_index local function fn_3_(_new, _key, _value) end on_index = fn_3_

 local proxy = {}

 local proxy_mt

 local function fn_4_(_self, key)

 on_index(false, key)
 return rawget(raw, key) end

 local function fn_5_(_self, key, value)

 on_index(true, key, value)
 return rawset(raw, key, value) end

 local function fn_6_(_self, opts)

 local opts0 = (opts or {})
 local handler = opts0.handler
 local clear = opts0.clear



 if handler then
 on_index = handler else end


 if clear then
 raw = {} else end



 if vim.tbl_isempty(opts0) then
 return raw else return nil end end proxy_mt = {__index = fn_4_, __newindex = fn_5_, __call = fn_6_}

 return setmetatable(proxy, proxy_mt) end


 local function format_missing_key(m)
 if ((_G.type(m) == "table") and (nil ~= m["any-of"])) then local keys = m["any-of"]
 return string.format("one of: %s", table.concat(keys, ", ")) elseif ((_G.type(m) == "table") and (nil ~= m.required)) then local key = m.required
 return key else local _ = m
 return vim.inspect(m) end end

 local prefetcher_mt


 local function fn_11_(self, args)

 local function fn_12_()
 if self["required-keys"] then
 local missing = missing_keys(args, self["required-keys"])
 if (#missing > 0) then

 local formatted = vim.iter(missing):map(format_missing_key):totable()



 error(string.format("Missing keys: %s", table.concat(formatted, "; "))) else end else end


 if self["required-cmds"] then
 local missing

 local function hashfn_15_(_241) return (vim.fn.executable(_241) == 0) end missing = vim.iter(self["required-cmds"]):filter(hashfn_15_):totable()

 if (#missing > 0) then
 error(string.format("Missing commands: %s", table.concat(missing, ", "))) else end else end


 local _local_18_ = call_command(self.prefetcher(args)) local code = _local_18_.code local stdout = _local_18_.stdout local stderr = _local_18_.stderr

 if (code ~= 0) then
 error(string.format("Prefetch command exited with code %d: %s", code, table.concat(stderr, "\n"))) else end


 return self.extractor(stdout) end return vim.async.run(fn_12_) end prefetcher_mt = {__call = fn_11_}

 return {["create-proxied"] = create_proxied, ["prefetcher-mt"] = prefetcher_mt}
