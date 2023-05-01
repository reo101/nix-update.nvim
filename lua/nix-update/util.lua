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
 for child, _3fname in it do
 if p_3f(child, _3fname) then
 return child else end end return nil end

 local function find_children(p_3f, it) local tbl_17_auto = {}
 local i_18_auto = #tbl_17_auto for child, _3fname in it do local val_19_auto
 if p_3f(child, _3fname) then
 val_19_auto = child else val_19_auto = nil end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end return tbl_17_auto end

 local function has_keys(tbl, keys)
 local function _9_(_, key)
 local function _10_(k, _0)
 return (k == key) end return any(_10_, tbl) end return all(_9_, keys) end



 local function concat_two(xs, ys)
 for _, y in ipairs(ys) do
 table.insert(xs, y) end
 return xs end


 local function call_command(_11_, callback) local _arg_12_ = _11_ local cmd = _arg_12_["cmd"] local args = _arg_12_["args"]

 local stdout = uv.new_pipe()


 local options = {args = args, stdio = {nil, stdout, nil}}



 local handle = nil


 local result = {}


 local on_exit local function _13_(_status)
 uv.read_stop(stdout)
 uv.close(stdout)
 uv.close(handle)
 local function _14_() return callback(result) end return vim.schedule(_14_) end on_exit = _13_


 local on_read local function _15_(_status, data)
 if data then
 local vals = vim.split(data, "\n")
 for _, val in ipairs(vals) do
 if (val ~= "") then
 table.insert(result, val) else end end return nil else return nil end end on_read = _15_


 handle = uv.spawn(cmd, options, on_exit)


 uv.read_start(stdout, on_read)

 return nil end

 return {any = any, all = all, map = map, filter = filter, ["find-child"] = find_child, ["find-children"] = find_children, ["has-keys"] = has_keys, ["concat-two"] = concat_two, ["call-command"] = call_command}