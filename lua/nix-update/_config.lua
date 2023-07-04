 local _local_1_ = require("nix-update.utils") local create_proxied = _local_1_["create-proxied"]
 local prefetcher_mt = _local_1_["prefetcher-mt"]


 local config = {}

 config["extra-prefetchers"] = create_proxied()

 local function _2_(new, _key, value)
 if new then
 return setmetatable(value, prefetcher_mt) else return nil end end config["extra-prefetchers"]({handler = _2_})

 return {config = config}