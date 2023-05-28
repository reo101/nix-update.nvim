 local uv = vim.loop

 local function any(p_3f, tbl)
 for k, v in pairs(tbl) do
 if p_3f({k = k, v = v}) then
 return true else end end return false end


 local function all(p_3f, tbl)
 for k, v in pairs(tbl) do
 if not p_3f({k = k, v = v}) then
 return false else end end return true end


 local function map(f, tbl) local tbl_14_auto = {}
 for k, v in pairs(tbl) do
 local k_15_auto, v_16_auto = f({k = k, v = v}) if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto end

 local function imap(f, seq) local tbl_17_auto = {}
 local i_18_auto = #tbl_17_auto for k, v in ipairs(seq) do
 local val_19_auto = f({k = k, v = v}) if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end return tbl_17_auto end

 local function filter(p_3f, seq) local tbl_17_auto = {}
 local i_18_auto = #tbl_17_auto for k, v in ipairs(seq) do local val_19_auto
 if p_3f({k = k, v = v}) then
 val_19_auto = v else val_19_auto = nil end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end return tbl_17_auto end

 local function flatten(seq, _3fres)
 local res = (_3fres or {})
 if vim.tbl_islist(seq) then
 for _, v in pairs(seq) do
 flatten(v, res) end else

 res[(#res + 1)] = seq end


 return res end

 local function find_child(p_3f, node)
 for child, _3fname in node:iter_children() do
 if p_3f(child, _3fname) then
 return child else end end return nil end

 local function find_children(p_3f, node) local tbl_17_auto = {}
 local i_18_auto = #tbl_17_auto for child, _3fname in node:iter_children() do local val_19_auto
 if p_3f(child, _3fname) then
 val_19_auto = child else val_19_auto = nil end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end return tbl_17_auto end

 local function missing_keys(tbl, keys)
 local function _13_(_11_) local _arg_12_ = _11_ local key = _arg_12_["k"]
 local function _16_(_14_) local _arg_15_ = _14_ local k = _arg_15_["k"]
 return (k == key) end return any(_16_, tbl) end return filter(_13_, keys) end



 local function concat_two(xs, ys)
 for _, y in ipairs(ys) do
 table.insert(xs, y) end
 return xs end


 local function call_command(_17_, callback) local _arg_18_ = _17_ local cmd = _arg_18_["cmd"] local args = _arg_18_["args"]

 local stdout = uv.new_pipe()
 local stderr = uv.new_pipe()


 local options = {args = args, stdio = {nil, stdout, stderr}}



 local handle = nil


 local result = {stdout = {}, stderr = {}}



 local on_exit local function _19_(_status)
 for _, pipe in pairs({stdout, stderr}) do
 uv.read_stop(pipe)
 uv.close(pipe) end
 uv.close(handle)
 local function _20_() return callback(result) end return vim.schedule(_20_) end on_exit = _19_


 local on_read local function _21_(pipe)
 local function _22_(_status, data)
 if data then
 local vals = vim.split(data, "\n")
 for _, val in ipairs(vals) do
 if (val ~= "") then
 table.insert(result[pipe], val) else end end return nil else return nil end end return _22_ end on_read = _21_


 handle = uv.spawn(cmd, options, on_exit)


 uv.read_start(stdout, on_read("stdout"))
 uv.read_start(stderr, on_read("stderr"))

 return nil end

 return {any = any, all = all, map = map, imap = imap, filter = filter, flatten = flatten, ["find-child"] = find_child, ["find-children"] = find_children, ["missing-keys"] = missing_keys, ["concat-two"] = concat_two, ["call-command"] = call_command}