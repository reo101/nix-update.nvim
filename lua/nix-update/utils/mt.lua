-- [nfnl] fnl/nix-update/utils/mt.fnl
 local _local_1_ = require("nix-update.utils.common") local missing_keys = _local_1_["missing-keys"]


 local function create_proxied()
 local raw = {}
 local on_index local function fn_2_(_new, _key, _value) end on_index = fn_2_

 local proxy = {}

 local proxy_mt

 local function fn_3_(_self, key)

 on_index(false, key)
 return rawget(raw, key) end

 local function fn_4_(_self, key, value)

 on_index(true, key, value)
 return rawset(raw, key, value) end

 local function fn_5_(_self, opts)

 local opts0 = (opts or {})
 local handler = opts0.handler
 local clear = opts0.clear



 if handler then
 on_index = handler else end


 if clear then
 raw = {} else end



 if vim.tbl_isempty(opts0) then
 return raw else return nil end end proxy_mt = {__index = fn_3_, __newindex = fn_4_, __call = fn_5_}

 return setmetatable(proxy, proxy_mt) end


 local function format_missing_key(m)
 if ((_G.type(m) == "table") and (nil ~= m["any-of"])) then local keys = m["any-of"]
 return string.format("one of: %s", table.concat(keys, ", ")) elseif ((_G.type(m) == "table") and (nil ~= m.required)) then local key = m.required
 return key else local _ = m
 return vim.inspect(m) end end

 local prefetcher_mt


 local function fn_10_(self, args)

 if self["required-keys"] then
 local missing = missing_keys(args, self["required-keys"])
 if (#missing > 0) then
 local formatted



 local function fn_11_(_, m) return format_missing_key(m) end formatted = vim.iter(ipairs(missing)):map(fn_11_):totable()

 vim.notify(string.format("Missing keys: %s", table.concat(formatted, "; ")))



 return nil else end else end


 if self["required-cmds"] then
 local missing


 local function fn_14_(_, cmd) return (vim.fn.executable(cmd) == 0) end missing = vim.iter(ipairs(self["required-cmds"])):filter(fn_14_):totable()

 if (#missing > 0) then
 vim.notify(string.format("Missing commands: %s", table.concat(missing, ", ")))



 return nil else end else end


 return self.prefetcher(args) end prefetcher_mt = {__call = fn_10_}

 return {["create-proxied"] = create_proxied, ["prefetcher-mt"] = prefetcher_mt}
