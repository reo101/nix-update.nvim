 local function any(p_3f, tbl)
 for k, v in pairs(tbl) do
 if p_3f({k = k, v = v}) then
 return true else end end return false end


 local function all(p_3f, tbl)
 for k, v in pairs(tbl) do
 if not p_3f({k = k, v = v}) then
 return false else end end return true end


 local function keys(tbl)
 local tbl_21_auto = {} local i_22_auto = 0 for k, _ in pairs(tbl) do
 local val_23_auto = k if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 local function map(f, tbl) local tbl_16_auto = {}
 for k, v in pairs(tbl) do
 local k_17_auto, v_18_auto = f({k = k, v = v}) if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end return tbl_16_auto end

 local function imap(f, seq)
 local tbl_21_auto = {} local i_22_auto = 0 for k, v in ipairs(seq) do
 local val_23_auto = f({k = k, v = v}) if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 local function filter(p_3f, seq)
 local tbl_21_auto = {} local i_22_auto = 0 for k, v in ipairs(seq) do local val_23_auto
 if p_3f({k = k, v = v}) then
 val_23_auto = v else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

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

 local function find_children(p_3f, node)
 local tbl_21_auto = {} local i_22_auto = 0 for child, _3fname in node:iter_children() do local val_23_auto
 if p_3f(child, _3fname) then
 val_23_auto = child else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 local function missing_keys(tbl, keys0)
 local function _13_(_12_) local key = _12_["v"]

 local function _15_(_14_) local k = _14_["k"]
 return (k == key) end return not any(_15_, tbl) end return filter(_13_, keys0) end



 local function concat_two(xs, ys)
 for _, y in ipairs(ys) do
 table.insert(xs, y) end
 return xs end

 local function coords(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]
 local node = opts0["node"]



 if not bufnr then
 vim.notify(string.format("No bufnr given for getting coords", bufnr))



 return nil else end


 if not node then
 vim.notify(string.format("No node given for getting coords", bufnr))



 return nil else end


 local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, bufnr)
 return {["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col} end




 return {any = any, all = all, keys = keys, map = map, imap = imap, filter = filter, flatten = flatten, ["find-child"] = find_child, ["find-children"] = find_children, ["missing-keys"] = missing_keys, ["concat-two"] = concat_two, coords = coords}
