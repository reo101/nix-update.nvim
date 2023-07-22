 local function any(p_3f, tbl)
 for k, v in pairs(tbl) do
 if p_3f({k = k, v = v}) then
 return true else end end return false end


 local function all(p_3f, tbl)
 for k, v in pairs(tbl) do
 if not p_3f({k = k, v = v}) then
 return false else end end return true end


 local function keys(tbl) local tbl_17_auto = {}
 local i_18_auto = #tbl_17_auto for k, _ in pairs(tbl) do
 local val_19_auto = k if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end return tbl_17_auto end

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

 local function missing_keys(tbl, keys0)
 local function _14_(_12_) local _arg_13_ = _12_ local key = _arg_13_["v"]

 local function _17_(_15_) local _arg_16_ = _15_ local k = _arg_16_["k"]
 return (k == key) end return not any(_17_, tbl) end return filter(_14_, keys0) end



 local function concat_two(xs, ys)
 for _, y in ipairs(ys) do
 table.insert(xs, y) end
 return xs end

 local function coords(opts)

 local opts0 = (opts or {})
 local _local_18_ = opts0 local bufnr = _local_18_["bufnr"]
 local node = _local_18_["node"]



 if not bufnr then
 vim.notify(string.format("No bufnr given for getting coords", bufnr))



 return nil else end


 if not node then
 vim.notify(string.format("No node given for getting coords", bufnr))



 return nil else end


 local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, bufnr)
 return {["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col} end




 return {any = any, all = all, keys = keys, map = map, imap = imap, filter = filter, flatten = flatten, ["find-child"] = find_child, ["find-children"] = find_children, ["missing-keys"] = missing_keys, ["concat-two"] = concat_two, coords = coords}
