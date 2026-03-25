-- [nfnl] fnl/nix-update/health.fnl
local _local_1_ = require("nix-update._config")
local config = _local_1_.config
local _local_2_ = require("nix-update.prefetchers")
local prefetchers = _local_2_.prefetchers
local health = (vim.health or require("health"))
local function report_start(msg)
  return (health.start or health.report_start)(msg)
end
local function report_ok(msg)
  return (health.ok or health.report_ok)(msg)
end
local function report_warn(msg)
  return (health.warn or health.report_warn)(msg)
end
local function report_error(msg)
  return (health.error or health.report_error)(msg)
end
local valid_update_actions = {apply = true, flash = true, notify = true, preview = true}
local function collect_required_commands()
  local required_cmds = {}
  for _, prefetcher in pairs(prefetchers) do
    for _0, cmd in ipairs((prefetcher["required-cmds"] or {})) do
      required_cmds[cmd] = true
    end
  end
  for _, prefetcher in pairs((config["extra-prefetchers"] or {})) do
    for _0, cmd in ipairs((prefetcher["required-cmds"] or {})) do
      required_cmds[cmd] = true
    end
  end
  return vim.tbl_keys(required_cmds)
end
local function check_config()
  local invalid_actions
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, action in ipairs((config["update-actions"] or {})) do
      local val_28_
      local _4_
      do
        local t_3_ = valid_update_actions
        if (nil ~= t_3_) then
          t_3_ = t_3_[action]
        else
        end
        _4_ = t_3_
      end
      if not _4_ then
        val_28_ = action
      else
        val_28_ = nil
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    invalid_actions = tbl_26_
  end
  if (#invalid_actions > 0) then
    return report_error(string.format("Invalid `update-actions`: %s", table.concat(invalid_actions, ", ")))
  else
    return report_ok(string.format("Configured update actions: %s", table.concat(config["update-actions"], ", ")))
  end
end
local function check_dependencies()
  local missing_cmds
  local function _9_(_, cmd)
    return (vim.fn.executable(cmd) == 0)
  end
  missing_cmds = vim.iter(ipairs(collect_required_commands())):filter(_9_):totable()
  if (#missing_cmds > 0) then
    return report_warn(string.format("Missing commands: %s", table.concat(missing_cmds, ", ")))
  else
    return report_ok("All configured prefetcher commands are available")
  end
end
local function check()
  report_start("nix-update")
  check_config()
  return check_dependencies()
end
return {check = check}
