-- [nfnl] fnl/nix-update.fnl
local _local_1_ = require("nix-update.fetches")
local calculate_updates = _local_1_["calculate-updates"]
local preview_update = _local_1_["preview-update"]
local apply_update = _local_1_["apply-update"]
local notify_update = _local_1_["notify-update"]
local flash_update = _local_1_["flash-update"]
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
  local _6_
  do
    local t_5_ = opts1
    if (nil ~= t_5_) then
      t_5_ = t_5_["update-actions"]
    else
    end
    _6_ = t_5_
  end
  if _6_ then
    config["update-actions"] = opts1["update-actions"]
  else
  end
  local action_handlers = {preview = preview_update, apply = apply_update, notify = notify_update, flash = flash_update}
  local function _9_(new, _key, value)
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
        for _0, action in ipairs(config["update-actions"]) do
          local handler
          do
            local t_11_ = action_handlers
            if (nil ~= t_11_) then
              t_11_ = t_11_[action]
            else
            end
            handler = t_11_
          end
          if handler then
            handler(update)
          else
          end
        end
      end
      return nil
    else
      return nil
    end
  end
  return cache({handler = _9_})
end
return {setup = setup, prefetch_fetch = prefetch_fetch}
