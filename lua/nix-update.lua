-- [nfnl] fnl/nix-update.fnl
local _local_1_ = require("nix-update._cache")
local cache = _local_1_.cache
local _local_2_ = require("nix-update._config")
local config = _local_2_.config
local apply_options = _local_2_["apply-options"]
local initialized_3f = false
local global_options_applied_3f = false
local function normalize_options(opts)
  local tbl_21_ = {}
  for k, v in pairs((opts or {})) do
    local k_22_, v_23_
    if (type(k) == "string") then
      k_22_, v_23_ = string.gsub(k, "_", "-"), v
    else
      k_22_, v_23_ = k, v
    end
    if ((k_22_ ~= nil) and (v_23_ ~= nil)) then
      tbl_21_[k_22_] = v_23_
    else
    end
  end
  return tbl_21_
end
local function get_global_options()
  local raw_options = vim.g.nix_update
  if (type(raw_options) == "function") then
    local ok, options_or_error = pcall(raw_options)
    if ok then
      return options_or_error
    else
      vim.notify(string.format("nix-update: failed to evaluate `vim.g.nix_update`: %s", options_or_error), vim.log.levels.ERROR)
      return nil
    end
  else
    return raw_options
  end
end
local function apply_current_options()
  local global_options = get_global_options()
  local normalized_global_options
  if (type(global_options) == "table") then
    normalized_global_options = normalize_options(global_options)
  else
    normalized_global_options = {}
  end
  local ok, err = apply_options(normalized_global_options)
  if not ok then
    vim.notify(string.format("nix-update: invalid configuration: %s", err), vim.log.levels.ERROR)
  else
  end
  return ok
end
local function ensure_global_options()
  if not global_options_applied_3f then
    apply_current_options()
    global_options_applied_3f = true
    return nil
  else
    return nil
  end
end
local function initialize()
  ensure_global_options()
  if initialized_3f then
    return true
  else
  end
  local _local_11_ = require("nix-update.fetches")
  local calculate_updates = _local_11_["calculate-updates"]
  local preview_update = _local_11_["preview-update"]
  local apply_update = _local_11_["apply-update"]
  local notify_update = _local_11_["notify-update"]
  local flash_update = _local_11_["flash-update"]
  local action_handlers = {preview = preview_update, apply = apply_update, notify = notify_update, flash = flash_update}
  local function on_cache_write(value)
    local bufnr = value.bufnr
    local fetch = value.fetch
    local data = value.data
    local err = value.err
    if ((#(data or {}) == 0) and err) then
      vim.notify(string.format("Could not prefetch: %s", vim.inspect(err)), vim.log.levels.ERROR)
      return nil
    else
    end
    local updates = calculate_updates({bufnr = bufnr, fetch = fetch, ["new-data"] = data})
    for _, update in ipairs(updates) do
      for _0, action in ipairs(config["update-actions"]) do
        local handler
        do
          local t_13_ = action_handlers
          if (nil ~= t_13_) then
            t_13_ = t_13_[action]
          else
          end
          handler = t_13_
        end
        if handler then
          handler(update)
        else
        end
      end
    end
    return nil
  end
  local function _16_(new, _key, value)
    if new then
      return on_cache_write(value)
    else
      return nil
    end
  end
  cache({handler = _16_})
  initialized_3f = true
  return true
end
local function setup(opts)
  local normalized_current = normalize_options((get_global_options() or {}))
  local normalized_overrides = normalize_options(opts)
  local merged = vim.tbl_deep_extend("force", normalized_current, normalized_overrides)
  vim.g["nix_update"] = merged
  global_options_applied_3f = false
  ensure_global_options()
  return config
end
local function prefetch_fetch(opts)
  initialize()
  local _let_18_ = require("nix-update.fetches")
  local prefetch_fetch0 = _let_18_["prefetch-fetch"]
  return prefetch_fetch0(opts)
end
local function prefetch_buffer(opts)
  initialize()
  local _let_19_ = require("nix-update.diagnostics")
  local prefetch_buffer0 = _let_19_["prefetch-buffer"]
  return prefetch_buffer0(opts)
end
return {setup = setup, init = initialize, prefetch_fetch = prefetch_fetch, prefetch_buffer = prefetch_buffer, config = config}
