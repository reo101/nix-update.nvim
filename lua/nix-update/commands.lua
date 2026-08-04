-- [nfnl] fnl/nix-update/commands.fnl
 local registered_3f = false

 local subcommand_tbl

 local function fn_1_(_args, _opts)
 local nix_update = require("nix-update")
 return nix_update.prefetch_fetch({}) end

 local function fn_2_(_args, _opts)
 local nix_update = require("nix-update")
 return nix_update.prefetch_buffer({}) end

 local function fn_3_(_args, _opts)
 return vim.cmd("checkhealth nix-update") end

 local function fn_4_(_args, _opts)
 return vim.cmd("help nix-update") end subcommand_tbl = {prefetch = {impl = fn_1_}, buffer = {impl = fn_2_}, health = {impl = fn_3_}, help = {impl = fn_4_}}

 local function complete_subcommands(arg_lead)




 local function fn_5_(_, key)
 return (string.find(key, arg_lead, 1, true) ~= nil) end return vim.iter(ipairs(vim.tbl_keys(subcommand_tbl))):filter(fn_5_):totable() end


 local function complete(arg_lead, cmdline, _)
 local matches = {string.match(cmdline, "^['<,'>]*NixUpdate[!]*%s(%S+)%s(.*)$")}
 local subcmd_key = matches[1]
 local subcmd_arg_lead = matches[2]
 local subcommand do local t_6_ = subcommand_tbl if (nil ~= t_6_) then t_6_ = t_6_[subcmd_key] else end subcommand = t_6_ end
 local complete_fn do local t_8_ = subcommand if (nil ~= t_8_) then t_8_ = t_8_.complete else end complete_fn = t_8_ end

 if (subcmd_key and subcmd_arg_lead and complete_fn) then


 return complete_fn(subcmd_arg_lead) else
 if string.match(cmdline, "^['<,'>]*NixUpdate[!]*%s+%w*$") then
 return complete_subcommands(arg_lead) else
 return {} end end end

 local function run_command(opts)
 local fargs = (opts.fargs or {})
 local subcommand_key = (fargs[1] or "prefetch")
 local args if (#fargs > 1) then
 args = vim.list_slice(fargs, 2, #fargs) else
 args = {} end
 local subcommand do local t_13_ = subcommand_tbl if (nil ~= t_13_) then t_13_ = t_13_[subcommand_key] else end subcommand = t_13_ end

 if not subcommand then
 vim.notify(string.format("nix-update: unknown subcommand `%s`", subcommand_key), vim.log.levels.ERROR)


 return nil else end

 return subcommand.impl(args, opts) end

 local function register()
 if registered_3f then
 return nil else end

 vim.api.nvim_create_user_command("NixUpdate", run_command, {nargs = "*", desc = "nix-update commands (prefetch, buffer, health, help)", complete = complete})






 local function fn_17_(_)
 local nix_update = require("nix-update")
 return nix_update.prefetch_buffer({}) end vim.api.nvim_create_user_command("NixPrefetch", fn_17_, {desc = "Prefetch all fetches in the current buffer"})



 local function fn_18_()
 local nix_update = require("nix-update")
 return nix_update.prefetch_fetch({}) end vim.keymap.set("n", "<Plug>(NixUpdatePrefetch)", fn_18_, {silent = true, desc = "Prefetch and update fetch at cursor"})




 local function fn_19_()
 local nix_update = require("nix-update")
 return nix_update.prefetch_buffer({}) end vim.keymap.set("n", "<Plug>(NixUpdatePrefetchBuffer)", fn_19_, {silent = true, desc = "Prefetch and update all fetches in buffer"}) registered_3f = true



 return nil end

 return {register = register}
