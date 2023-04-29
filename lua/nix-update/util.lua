 local uv = vim.loop

 local function any(p_3f, tbl)
 for k, v in pairs(tbl) do
 if p_3f(k, v) then
 return true else end end return false end


 local function all(p_3f, tbl)
 for k, v in pairs(tbl) do
 if not p_3f(k, v) then
 return false else end end return true end


 local function map(f, tbl) local tbl_14_auto = {}
 for k, v in pairs(tbl) do
 local k_15_auto, v_16_auto = k, f(v) if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto end

 local function filter(p_3f, tbl) local tbl_14_auto = {}
 for k, v in pairs(tbl) do local k_15_auto, v_16_auto = nil, nil
 if p_3f(k, v) then
 k_15_auto, v_16_auto = k, v else k_15_auto, v_16_auto = nil end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto end

 local function find_child(p_3f, it)
 for v, _ in it do
 if p_3f(v) then
 return v else end end return nil end

 local function has_keys(tbl, keys)
 local function _7_(_, key)
 local function _8_(k, _0)
 return (k == key) end return any(_8_, tbl) end return all(_7_, keys) end



 local function concat_two(xs, ys)
 for _, y in ipairs(ys) do
 table.insert(xs, y) end
 return xs end


 local function call_command(_9_, callback) local _arg_10_ = _9_ local cmd = _arg_10_["cmd"] local args = _arg_10_["args"]

 local stdout = uv.new_pipe()


 local options = {args = args, stdio = {nil, stdout, nil}}



 local handle = nil


 local result = {}


 local on_exit local function _11_(_status)
 uv.read_stop(stdout)
 uv.close(stdout)
 uv.close(handle)
 local function _12_() return callback(result) end return vim.schedule(_12_) end on_exit = _11_


 local on_read local function _13_(_status, data)
 if data then
 local vals = vim.split(data, "\n")
 for _, val in ipairs(vals) do
 if (val ~= "") then
 table.insert(result, val) else end end return nil else return nil end end on_read = _13_


 handle = uv.spawn(cmd, options, on_exit)


 uv.read_start(stdout, on_read)

 return nil end

 return {any = any, all = all, map = map, filter = filter, ["find-child"] = find_child, ["has-keys"] = has_keys, ["concat-two"] = concat_two, ["call-command"] = call_command}