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
 local function _13_(_11_) local _arg_12_ = _11_ local key = _arg_12_["v"]

 local function _16_(_14_) local _arg_15_ = _14_ local k = _arg_15_["k"]
 return (k == key) end return not any(_16_, tbl) end return filter(_13_, keys) end



 local function concat_two(xs, ys)
 for _, y in ipairs(ys) do
 table.insert(xs, y) end
 return xs end

 local function coords(opts)

 local opts0 = (opts or {})
 local _local_17_ = opts0 local bufnr = _local_17_["bufnr"]
 local node = _local_17_["node"]



 if not bufnr then
 vim.notify(string.format("No bufnr given for getting coords", bufnr))



 return else end


 if not node then
 vim.notify(string.format("No node given for getting coords", bufnr))



 return else end


 local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, bufnr)
 return {["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col} end




 local prefetcher_cmd_mt


 local function _20_(self, args)

 if self["required-keys"] then
 local missing = missing_keys(args, self["required-keys"])
 if (#missing > 0) then
 vim.notify(string.format("Missing keys: %s", vim.inspect(missing)))




 return nil else end else end


 if self["required-cmds"] then
 local missing local function _23_(_241) return (vim.fn.executable(_241.v) == 0) end missing = filter(_23_, self["required-cmds"])
 if (#missing > 0) then
 vim.notify(string.format("Missing commands: %s", vim.inspect(missing)))




 return nil else end else end


 return self.prefetcher(args) end prefetcher_cmd_mt = {__call = _20_}


 local function call_command(_26_, callback) local _arg_27_ = _26_ local cmd = _arg_27_["cmd"] local args = _arg_27_["args"]

 local stdout = uv.new_pipe()
 local stderr = uv.new_pipe()


 local options = {args = args, stdio = {nil, stdout, stderr}}



 local handle = nil


 local result = {stdout = {}, stderr = {}}



 local on_exit local function _28_(_status)
 for _, pipe in ipairs({stdout, stderr}) do
 uv.read_stop(pipe)
 uv.close(pipe) end
 uv.close(handle)
 local function _29_() return callback(result) end return vim.schedule(_29_) end on_exit = _28_


 local on_read local function _30_(pipe)
 local function _31_(_status, data)
 if data then
 local vals = vim.split(data, "\n")
 for _, val in ipairs(vals) do
 if (val ~= "") then
 table.insert(result[pipe], val) else end end return nil else return nil end end return _31_ end on_read = _30_


 handle = uv.spawn(cmd, options, on_exit)


 uv.read_start(stdout, on_read("stdout"))
 uv.read_start(stderr, on_read("stderr"))

 return nil end

 return {any = any, all = all, map = map, imap = imap, filter = filter, flatten = flatten, ["find-child"] = find_child, ["find-children"] = find_children, ["missing-keys"] = missing_keys, ["concat-two"] = concat_two, coords = coords, ["prefetcher-cmd-mt"] = prefetcher_cmd_mt, ["call-command"] = call_command}