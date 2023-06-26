 local _local_1_ = require("nix-update.util") local prefetcher_cmd_mt = _local_1_["prefetcher-cmd-mt"]


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

 local config = {}

 config["extra-prefetcher-cmds"] = create_proxied()

 local function _10_(new, _key, value)
 if new then
 return setmetatable(value, prefetcher_cmd_mt) else return nil end end config["extra-prefetcher-cmds"]({handler = _10_})

 do end (config)["extra-prefetcher-extractors"] = create_proxied()

 return {config = config}