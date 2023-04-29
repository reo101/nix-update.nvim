 local _local_1_ = require("nix-update.prefetchers") local gen_prefetcher_cmd = _local_1_["gen-prefetcher-cmd"]
 local get_prefetcher_extractor = _local_1_["get-prefetcher-extractor"]


 local _local_2_ = require("nix-update.util") local find_child = _local_2_["find-child"]
 local call_command = _local_2_["call-command"] local fetches_query_string = "\n(\n  (apply_expression\n    function:\n      [(variable_expression\n         name: (identifier) @_fname)\n       (select_expression\n         attrpath:\n           (attrpath\n             attr: (identifier) @_fname\n             .))]\n    argument:\n      (attrset_expression\n        (binding_set) @_fargs)\n  ) @_fwhole\n  (#any-of? @_fname %s)\n)\n       "
























 local fetches_names

 local _3_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for fetch, _ in pairs(gen_prefetcher_cmd) do
 local val_19_auto = string.format("\"%s\"", fetch) if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _3_ = tbl_17_auto end fetches_names = table.concat(_3_, " ")




 local fetches_query = vim.treesitter.parse_query("nix", string.format(fetches_query_string, fetches_names))





 local function get_root(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local parser = vim.treesitter.get_parser(bufnr0, "nix", {})
 local _let_6_ = parser:parse() local tree = _let_6_[1] return tree:root() end



 local function try_get_value(bufnr, bounder, name)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local bindings

 do local tbl_14_auto = {} for binding, _ in bounder:iter_children() do local k_15_auto, v_16_auto = nil, nil
 do local _8_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for binding_elem, _0 in binding:iter_children() do local val_19_auto
 do local _9_ = binding_elem:type() if (_9_ == "attrpath") then


 val_19_auto = vim.treesitter.get_node_text(binding_elem, bufnr0) elseif (_9_ == "string_expression") then local tbl_17_auto0 = {}




 local i_18_auto0 = #tbl_17_auto0 for binding_part, _1 in binding_elem:iter_children() do local val_19_auto0
 if binding_part:named() then
 val_19_auto0 = {node = binding_part, value = vim.treesitter.get_node_text(binding_part, bufnr0)} else val_19_auto0 = nil end if (nil ~= val_19_auto0) then i_18_auto0 = (i_18_auto0 + 1) do end (tbl_17_auto0)[i_18_auto0] = val_19_auto0 else end end val_19_auto = tbl_17_auto0 elseif (_9_ == "variable_expression") then








 val_19_auto = {vim.treesitter.get_node_text(binding_elem, bufnr0)} else val_19_auto = nil end end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _8_ = tbl_17_auto end if ((_G.type(_8_) == "table") and (nil ~= (_8_)[1]) and ((_G.type((_8_)[2]) == "table") and (nil ~= ((_8_)[2])[1]))) then local attr = (_8_)[1] local val = ((_8_)[2])[1]


 k_15_auto, v_16_auto = attr, val else k_15_auto, v_16_auto = nil end end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end bindings = tbl_14_auto end

 local binding = bindings[name]
 local _16_ = type(binding) if (_16_ == "table") then


 return binding elseif (nil ~= _16_) then local other = _16_





 local target = bounder:parent():parent()
 while ((target ~= nil) and (target:type() ~= "rec_attrset_expression") and (target:type() ~= "let_expression")) do target = target:parent() end







 if (target ~= nil) then



 local function _17_(_241) return (_241:type() == "binding_set") end target = find_child(_17_, target:iter_children())


 local _18_ = other if (_18_ == "string") then


 return try_get_value(bufnr0, target, binding) elseif (_18_ == "nil") then


 return try_get_value(bufnr0, target, name) else return nil end else return nil end else return nil end end


 local function find_used_fetches(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local root = get_root(bufnr0)


 local found_fetches

 do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _pattern, matcher, _metadata in fetches_query:iter_matches(root, bufnr0, 0, -1) do local val_19_auto


 do local tbl_14_auto = {} for id, node in pairs(matcher) do local k_15_auto, v_16_auto = nil, nil



 local function _24_() local _23_ = fetches_query.captures[id] if (_23_ == "_fname") then


 return vim.treesitter.get_node_text(node, bufnr0) elseif (_23_ == "_fargs") then local tbl_14_auto0 = {}









 for binding, _ in node:iter_children() do local k_15_auto0, v_16_auto0 = nil, nil
 do local _25_ do local tbl_17_auto0 = {} local i_18_auto0 = #tbl_17_auto0 for binding_elem, _0 in binding:iter_children() do local val_19_auto0
 do local _26_ = binding_elem:type() if (_26_ == "attrpath") then


 val_19_auto0 = vim.treesitter.get_node_text(binding_elem, bufnr0) else val_19_auto0 = nil end end if (nil ~= val_19_auto0) then i_18_auto0 = (i_18_auto0 + 1) do end (tbl_17_auto0)[i_18_auto0] = val_19_auto0 else end end _25_ = tbl_17_auto0 end if ((_G.type(_25_) == "table") and (nil ~= (_25_)[1])) then local attr = (_25_)[1]
 k_15_auto0, v_16_auto0 = attr, try_get_value(bufnr0, node, attr) else k_15_auto0, v_16_auto0 = nil end end if ((k_15_auto0 ~= nil) and (v_16_auto0 ~= nil)) then tbl_14_auto0[k_15_auto0] = v_16_auto0 else end end return tbl_14_auto0 elseif (_23_ == "_fwhole") then



 return node else return nil end end k_15_auto, v_16_auto = fetches_query.captures[id], _24_() if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end val_19_auto = tbl_14_auto end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end found_fetches = tbl_17_auto end

 return found_fetches end

 local function get_fetch_at_cursor(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches(bufnr0)


 local _local_34_ = vim.fn.getcursorcharpos() local _ = _local_34_[1] local cursor_row = _local_34_[2] local cursor_col = _local_34_[3] local _0 = _local_34_[4] local _1 = _local_34_[5]


 for _2, fetch in ipairs(found_fetches) do
 if vim.treesitter.is_in_node_range(fetch._fwhole, cursor_row, cursor_col) then



 return fetch else end end return nil end

 local function prefetch_fetch_at_cursor(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local fetch_at_cursor = get_fetch_at_cursor(bufnr0)


 if (fetch_at_cursor == nil) then
 vim.notify("No fetch found at cursor")
 return else end


 local prefetcher
 do local t_37_ = gen_prefetcher_cmd if (nil ~= t_37_) then t_37_ = (t_37_)[fetch_at_cursor._fname] else end prefetcher = t_37_ end


 if (prefetcher == nil) then
 vim.notify(string.format("No prefetcher '%s' found", fetch_at_cursor._fname))



 return else end



 local prefetcher_cmd = prefetcher(fetch_at_cursor._fargs)


 if (prefetcher_cmd == nil) then
 vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch_at_cursor._fname))



 return else end


 local prefetcher_extractor
 do local t_41_ = get_prefetcher_extractor if (nil ~= t_41_) then t_41_ = (t_41_)[fetch_at_cursor._fname] else end prefetcher_extractor = t_41_ end


 if (prefetcher_extractor == nil) then
 vim.notify(string.format("No data extractor for the prefetcher '%s' found", fetch_at_cursor._fname))



 return else end


 local function sed(res)
 for key, value in pairs(prefetcher_extractor(res)) do
 local node do local t_44_ = fetch_at_cursor if (nil ~= t_44_) then t_44_ = (t_44_)._fargs else end if (nil ~= t_44_) then t_44_ = (t_44_)[key] else end if (nil ~= t_44_) then t_44_ = (t_44_).node else end node = t_44_ end
 if node then

 local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, bufnr0)
 vim.api.nvim_buf_set_text(bufnr0, start_row, start_col, end_row, end_col, {value}) else







 local _start_row, _start_col, end_row, _end_col = vim.treesitter.get_node_range(fetch_at_cursor._fwhole, bufnr0)
 vim.api.nvim_buf_set_lines(bufnr0, end_row, end_row, true, {string.format("sha256 = \"%s\";", value)})







 vim.cmd(string.format("normal ma%sggj==`a", end_row)) end end



 return vim.notify("Prefetch complete!") end


 call_command(prefetcher_cmd, sed)


 return vim.notify(string.format("Prefetch initiated, awaiting response...")) end



 return {["fetches-query-string"] = fetches_query_string, ["fetches-names"] = fetches_names, ["fetches-query"] = fetches_query, ["get-root"] = get_root, ["try-get-value"] = try_get_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["prefetch-fetch-at-cursor"] = prefetch_fetch_at_cursor}