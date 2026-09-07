-- [nfnl] fnl/nix-update/utils/command.fnl
 local async = vim.async

 local function split_output(output)
 if (output == "") then
 return {} else
 return vim.split(output, "\n", {plain = true, trimempty = true}) end end


 local function call_command(arg_2_) local cmd = arg_2_.cmd local args = arg_2_.args
 local result

 local function fn_3_(done)
 return vim.system(vim.list_extend({cmd}, args), {text = true}, done) end result = async.await(fn_3_)




 return {stdout = split_output(result.stdout), stderr = split_output(result.stderr)} end


 return {["call-command"] = call_command}
