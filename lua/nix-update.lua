-- [nfnl] fnl/nix-update.fnl
local _local_1_ = require("nix-update.fetches")
local calculate_updates = _local_1_["calculate-updates"]
local preview_update = _local_1_["preview-update"]
local apply_update = _local_1_["apply-update"]
local notify_update = _local_1_["notify-update"]
local prefetch_fetch = _local_1_["prefetch-fetch"]
local _local_2_ = require("nix-update._cache")
local cache = _local_2_.cache
local _local_3_ = require("nix-update._config")
local config = _local_3_.config
local function setup(opts)
  local opts0 = (opts or {})
  local opts1
  do
    local tbl_21_ = {}
    for k, v in pairs(opts0) do
      local k_22_, v_23_ = string.gsub(k, "_", "-"), v
      if ((k_22_ ~= nil) and (v_23_ ~= nil)) then
        tbl_21_[k_22_] = v_23_
      else
      end
    end
    opts1 = tbl_21_
  end
  do
    local opts_2_auto = vim.tbl_deep_extend("keep", opts1, {["extra-prefetchers"] = {}})
    for k_5_auto, v_6_auto in pairs(opts_2_auto["extra-prefetchers"]) do
      config["extra-prefetchers"][k_5_auto] = v_6_auto
    end
  end
  local function _5_(new, _key, value)
    if new then
      local bufnr = value.bufnr
      local fetch = value.fetch
      local data = value.data
      local err = value.err
      if ((#(data or {}) == 0) and err) then
        vim.notify("Could not prefetch")
        vim.print({data = data, err = err})
        return nil
      else
      end
      vim.notify("Successful prefetch, applying updates...")
      local updates = calculate_updates({bufnr = bufnr, fetch = fetch, ["new-data"] = data})
      for _, update in ipairs(updates) do
        apply_update(update)
        notify_update(update)
      end
      return nil
    else
      return nil
    end
  end
  return cache({handler = _5_})
end
return {setup = setup, prefetch_fetch = prefetch_fetch}
