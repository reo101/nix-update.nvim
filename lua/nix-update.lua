 local _local_1_ = require("nix-update.diagnostics") local set_diagnostic = _local_1_["set-diagnostic"]


 local _local_2_ = require("nix-update._cache") local cache = _local_2_["cache"]


 local _local_3_ = require("nix-update._config") local config = _local_3_["config"]




 local function setup(opts)


 local opts0 = (opts or {})
 local opts1
 do local tbl_14_auto = {} for k, v in pairs(opts0) do
 local k_15_auto, v_16_auto = string.gsub(k, "_", "-"), v if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end opts1 = tbl_14_auto end

 local opts2 = vim.tbl_deep_extend("keep", opts1, {["extra-prefetcher-cmds"] = {}, ["extra-prefetcher-extractors"] = {}})




 local _local_5_ = opts2 local extra_prefetcher_cmds = _local_5_["extra-prefetcher-cmds"]
 local extra_prefetcher_extractors = _local_5_["extra-prefetcher-extractors"]



 for k, v in pairs(extra_prefetcher_cmds) do
 config["extra-prefetcher-cmds"][k] = v end
 for k, v in pairs(extra_prefetcher_extractors) do
 config["extra-prefetcher-extractors"][k] = v end


 local function _6_(new, _key, value)
 if new then
 return set_diagnostic(value) else return nil end end return cache({handler = _6_}) end

 return {setup = setup}