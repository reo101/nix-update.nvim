 local uv = vim.loop

 local function any(p_3f, tbl)
 for k, v in pairs(tbl) do
 if p_3f(k, v) then
 return true else end end return false end


 local function all(p_3f, tbl)
 for k, v in pairs(tbl) do
 if not p_3f(k, v) then
 return false else end end return true end


 local function has_keys(tbl, keys)
 local function _3_(_, key)
 local function _4_(k, _0)
 return (k == key) end return any(_4_, tbl) end return all(_3_, keys) end



 local function concat_two(xs, ys)
 for _, y in ipairs(ys) do
 table.insert(xs, y) end
 return xs end


 local function call_command(_5_, callback) local _arg_6_ = _5_ local cmd = _arg_6_["cmd"] local args = _arg_6_["args"]

 local stdout = uv.new_pipe()


 local options = {args = args, stdio = {nil, stdout, nil}}



 local handle = nil


 local result = {}


 local on_exit local function _7_(_status)
 uv.read_stop(stdout)
 uv.close(stdout)
 uv.close(handle)
 local function _8_() return callback(result) end return vim.schedule(_8_) end on_exit = _7_


 local on_read local function _9_(_status, data)
 if data then
 local vals = vim.split(data, "\n")
 for _, val in ipairs(vals) do
 if (val ~= "") then
 table.insert(result, val) else end end return nil else return nil end end on_read = _9_


 handle = uv.spawn(cmd, options, on_exit)


 uv.read_start(stdout, on_read)

 return nil end

 return {any = any, all = all, ["has-keys"] = has_keys, ["concat-two"] = concat_two, ["call-command"] = call_command}