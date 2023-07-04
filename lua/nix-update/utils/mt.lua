 local _local_1_ = require("nix-update.utils.common") local missing_keys = _local_1_["missing-keys"]
 local filter = _local_1_["filter"]


 local function create_proxied()
 local raw = {}
 local on_index local function _2_(_new, _key, _value) end on_index = _2_

 local proxy = {}

 local proxy_mt

 local function _3_(_self, key)

 on_index(false, key)
 return rawget(raw, key) end

 local function _4_(_self, key, value)

 on_index(true, key, value)
 return rawset(raw, key, value) end

 local function _5_(_self, opts)

 local opts0 = (opts or {})
 local _local_6_ = opts0 local handler = _local_6_["handler"]
 local clear = _local_6_["clear"]



 if handler then
 on_index = handler else end


 if clear then
 raw = {} else end



 if vim.tbl_isempty(opts0) then
 return raw else return nil end end proxy_mt = {__index = _3_, __newindex = _4_, __call = _5_}

 return setmetatable(proxy, proxy_mt) end

 local prefetcher_mt


 local function _10_(self, args)

 if self["required-keys"] then
 local missing = missing_keys(args, self["required-keys"])
 if (#missing > 0) then
 vim.notify(string.format("Missing keys: %s", vim.inspect(missing)))




 return nil else end else end


 if self["required-cmds"] then
 local missing local function _13_(_241) return (vim.fn.executable(_241.v) == 0) end missing = filter(_13_, self["required-cmds"])
 if (#missing > 0) then
 vim.notify(string.format("Missing commands: %s", vim.inspect(missing)))




 return nil else end else end


 return self.prefetcher(args) end prefetcher_mt = {__call = _10_}

 return {["create-proxied"] = create_proxied, ["prefetcher-mt"] = prefetcher_mt}