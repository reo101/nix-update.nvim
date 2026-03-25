-- [nfnl] fnl/nix-update/_config.fnl
local _local_1_ = require("nix-update.utils")
local create_proxied = _local_1_["create-proxied"]
local prefetcher_mt = _local_1_["prefetcher-mt"]
local default_update_actions = {"apply", "notify"}
local valid_update_actions = {apply = true, flash = true, notify = true, preview = true}
local valid_option_keys = {["extra-prefetchers"] = true, ["extra-prefetcher-cmds"] = true, ["update-actions"] = true}
local config = {}
config["extra-prefetchers"] = create_proxied()
local function _2_(new, _key, value)
  if new then
    return setmetatable(value, prefetcher_mt)
  else
    return nil
  end
end
config["extra-prefetchers"]({handler = _2_})
config["update-actions"] = vim.deepcopy(default_update_actions)
local function validate_extra_prefetchers(extra_prefetchers)
  if not ((extra_prefetchers == nil) or (type(extra_prefetchers) == "table")) then
    return false, "`extra-prefetchers` must be a table"
  else
    if (type(extra_prefetchers) ~= "table") then
      return true, nil
    else
      local err = nil
      for name, prefetcher in pairs(extra_prefetchers) do
        if (not err and (type(prefetcher) ~= "table")) then
          err = string.format("`extra-prefetchers.%s` must be a table", name)
        else
        end
        if (not err and (type(prefetcher) == "table") and (type(prefetcher.prefetcher) ~= "function")) then
          err = string.format("`extra-prefetchers.%s.prefetcher` must be a function", name)
        else
        end
        if (not err and (type(prefetcher) == "table") and prefetcher.extractor and (type(prefetcher.extractor) ~= "function")) then
          err = string.format("`extra-prefetchers.%s.extractor` must be a function when set", name)
        else
        end
      end
      if err then
        return false, err
      else
        return true, nil
      end
    end
  end
end
local function validate_update_actions(update_actions)
  if not ((update_actions == nil) or (type(update_actions) == "table")) then
    return false, "`update-actions` must be a list"
  else
    if (type(update_actions) ~= "table") then
      return true, nil
    else
      local err = nil
      for i, action in ipairs(update_actions) do
        local and_10_ = not err
        if and_10_ then
          local _12_
          do
            local t_11_ = valid_update_actions
            if (nil ~= t_11_) then
              t_11_ = t_11_[action]
            else
            end
            _12_ = t_11_
          end
          and_10_ = not _12_
        end
        if and_10_ then
          err = string.format("`update-actions[%d]` must be one of: apply, flash, notify, preview", i)
        else
        end
      end
      if err then
        return false, err
      else
        return true, nil
      end
    end
  end
end
local function validate_options(opts)
  local err = nil
  for key, _ in pairs(opts) do
    local and_18_ = not err
    if and_18_ then
      local _20_
      do
        local t_19_ = valid_option_keys
        if (nil ~= t_19_) then
          t_19_ = t_19_[key]
        else
        end
        _20_ = t_19_
      end
      and_18_ = not _20_
    end
    if and_18_ then
      err = string.format("Unknown setup option `%s`", key)
    else
    end
  end
  if err then
    return false, err
  else
    local extra_prefetchers = (opts["extra-prefetchers"] or opts["extra-prefetcher-cmds"])
    local ok_prefetchers, err_prefetchers = validate_extra_prefetchers(extra_prefetchers)
    if not ok_prefetchers then
      return false, err_prefetchers
    else
      local ok_actions, err_actions = validate_update_actions(opts["update-actions"])
      if not ok_actions then
        return false, err_actions
      else
        return true, nil
      end
    end
  end
end
local function apply_options(opts)
  local opts0 = (opts or {})
  local ok, err = validate_options(opts0)
  if not ok then
    return false, err
  else
    local extra_prefetchers = (opts0["extra-prefetchers"] or opts0["extra-prefetcher-cmds"])
    config["extra-prefetchers"]({clear = true})
    config["update-actions"] = vim.deepcopy(default_update_actions)
    if (type(extra_prefetchers) == "table") then
      for name, prefetcher in pairs(extra_prefetchers) do
        config["extra-prefetchers"][name] = prefetcher
      end
    else
    end
    if (type(opts0["update-actions"]) == "table") then
      config["update-actions"] = vim.deepcopy(opts0["update-actions"])
    else
    end
    return true, nil
  end
end
return {config = config, ["apply-options"] = apply_options}
