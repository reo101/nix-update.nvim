 local _local_1_ = require("nix-update.prefetchers") local gen_prefetcher_cmd = _local_1_["gen-prefetcher-cmd"]
 local get_prefetcher_extractor = _local_1_["get-prefetcher-extractor"]


 local _local_2_ = require("nix-update.util") local find_child = _local_2_["find-child"]
 local find_children = _local_2_["find-children"]
 local call_command = _local_2_["call-command"] local fetches_query_string = "\n(\n  (apply_expression\n    function:\n      [(variable_expression\n         name: (identifier) @_fname)\n       (select_expression\n         attrpath:\n           (attrpath\n             attr: (identifier) @_fname\n             .))]\n    argument:\n      (attrset_expression\n        (binding_set) @_fargs)\n  ) @_fwhole\n  (#any-of? @_fname %s)\n)\n       "
























 local fetches_names

 local _3_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for fetch, _ in pairs(gen_prefetcher_cmd) do
 local val_19_auto = string.format("\"%s\"", fetch) if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _3_ = tbl_17_auto end fetches_names = table.concat(_3_, " ")




 local fetches_query = vim.treesitter.parse_query("nix", string.format(fetches_query_string, fetches_names))





 local function get_root(_3fbufnr)

 local bufnr = (_3fbufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local parser = vim.treesitter.get_parser(bufnr, "nix", {})
 local _let_6_ = parser:parse() local tree = _let_6_[1] return tree:root() end





 local function find_all_local_bindings(bounder, _3fbufnr)

 local bufnr = (_3fbufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local bindings = {}
 for binding, _ in bounder:iter_children() do local _8_ = binding:type()
 if (_8_ == "binding") then


 local attr
 local function _9_(_241) return (_241:type() == "attrpath") end attr = find_child(_9_, binding:iter_children()) local attr_name

 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr) else attr_name = nil end local string_val


 do local string_expression

 local function _11_(_241) return (_241:type() == "string_expression") end string_expression = find_child(_11_, binding:iter_children())




 if string_expression then
 local string_fragment

 local function _12_(_241) return (_241:type() == "string_fragment") end string_fragment = find_child(_12_, string_expression:iter_children())

 if string_fragment then
 string_val = {node = string_fragment, value = vim.treesitter.get_node_text(string_fragment, bufnr)} else string_val = nil end else string_val = nil end end local var_val



 do local variable_expression

 local function _15_(_241) return (_241:type() == "variable_expression") end variable_expression = find_child(_15_, binding:iter_children())

 if variable_expression then
 var_val = vim.treesitter.get_node_text(variable_expression, bufnr) else var_val = nil end end


 local val = (string_val or var_val)
 do end (bindings)[attr_name] = val elseif (_8_ == "inherit") then


 local attrs
 local function _17_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(_17_, binding:iter_children())


 for node, node_name in attrs:iter_children() do
 if ((node:type() == "identifier") and (node_name == "attr")) then


 local attr_name = vim.treesitter.get_node_text(node, bufnr)



 do end (bindings)[attr_name] = attr_name else end end else end end


 return bindings end


 local function try_get_value(bounder, name, _3fbufnr)

 local bufnr = (_3fbufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local bindings = find_all_local_bindings(bounder, bufnr)


 local binding = bindings[name]
 local _21_ = type(binding) if (_21_ == "table") then


 return binding elseif (nil ~= _21_) then local other = _21_





 local target = bounder:parent():parent()
 while (target and (target:type() ~= "rec_attrset_expression") and (target:type() ~= "let_expression")) do target = target:parent() end





 if target then



 local function _22_(_241) return (_241:type() == "binding_set") end target = find_child(_22_, target:iter_children())



 local _23_ = other if (_23_ == "string") then


 return try_get_value(target, binding, bufnr) elseif (_23_ == "nil") then


 return try_get_value(target, name, bufnr) else return nil end else return nil end else return nil end end


 local function find_used_fetches(_3fbufnr)

 local bufnr = (_3fbufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local root = get_root(bufnr)


 local found_fetches

 do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _pattern, matcher, _metadata in fetches_query:iter_matches(root, bufnr, 0, -1) do local val_19_auto


 do local tbl_14_auto = {} for id, node in pairs(matcher) do local k_15_auto, v_16_auto = nil, nil



 local function _29_() local _28_ = fetches_query.captures[id] if (_28_ == "_fname") then


 return vim.treesitter.get_node_text(node, bufnr) elseif (_28_ == "_fargs") then local tbl_14_auto0 = {}


 for name, value in pairs(find_all_local_bindings(node, bufnr)) do local k_15_auto0, v_16_auto0 = nil, nil
 do local _30_ = type(value) if (_30_ == "table") then


 k_15_auto0, v_16_auto0 = name, value elseif (_30_ == "string") then


 local value0 = try_get_value(node, name, bufnr)
 if value0 then
 k_15_auto0, v_16_auto0 = name, value0 else k_15_auto0, v_16_auto0 = nil end else k_15_auto0, v_16_auto0 = nil end end if ((k_15_auto0 ~= nil) and (v_16_auto0 ~= nil)) then tbl_14_auto0[k_15_auto0] = v_16_auto0 else end end return tbl_14_auto0 elseif (_28_ == "_fwhole") then



 return node else return nil end end k_15_auto, v_16_auto = fetches_query.captures[id], _29_() if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end val_19_auto = tbl_14_auto end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end found_fetches = tbl_17_auto end


 return found_fetches end

 local function get_fetch_at_cursor(_3fbufnr)

 local bufnr = (_3fbufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches(bufnr)


 local _local_37_ = vim.fn.getcursorcharpos() local _ = _local_37_[1] local cursor_row = _local_37_[2] local cursor_col = _local_37_[3] local _0 = _local_37_[4] local _1 = _local_37_[5]


 for _2, fetch in ipairs(found_fetches) do
 if vim.treesitter.is_in_node_range(fetch._fwhole, cursor_row, cursor_col) then



 return fetch else end end return nil end

 local function prefetch_fetch_at_cursor(_3fbufnr)

 local bufnr = (_3fbufnr or vim.api.nvim_get_current_buf())



 local fetch_at_cursor = get_fetch_at_cursor(bufnr)


 if (fetch_at_cursor == nil) then
 vim.notify("No fetch found at cursor")
 return else end


 local prefetcher
 do local t_40_ = gen_prefetcher_cmd if (nil ~= t_40_) then t_40_ = (t_40_)[fetch_at_cursor._fname] else end prefetcher = t_40_ end


 if (prefetcher == nil) then
 vim.notify(string.format("No prefetcher '%s' found", fetch_at_cursor._fname))



 return else end



 local prefetcher_cmd = prefetcher(fetch_at_cursor._fargs)


 if (prefetcher_cmd == nil) then
 vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch_at_cursor._fname))



 return else end


 local prefetcher_extractor
 do local t_44_ = get_prefetcher_extractor if (nil ~= t_44_) then t_44_ = (t_44_)[fetch_at_cursor._fname] else end prefetcher_extractor = t_44_ end


 if (prefetcher_extractor == nil) then
 vim.notify(string.format("No data extractor for the prefetcher '%s' found", fetch_at_cursor._fname))



 return else end


 local function sed(res)
 for key, value in pairs(prefetcher_extractor(res)) do
 local node do local t_47_ = fetch_at_cursor if (nil ~= t_47_) then t_47_ = (t_47_)._fargs else end if (nil ~= t_47_) then t_47_ = (t_47_)[key] else end if (nil ~= t_47_) then t_47_ = (t_47_).node else end node = t_47_ end

 if node then

 local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, bufnr)
 vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, {value}) else








 local _start_row, _start_col, end_row, _end_col = vim.treesitter.get_node_range(fetch_at_cursor._fwhole, bufnr)
 vim.api.nvim_buf_set_lines(bufnr, end_row, end_row, true, {string.format("%s = \"%s\";", key, value)})














 vim.cmd(string.format("normal ma%sggj==`a", end_row)) end end



 return vim.notify("Prefetch complete!") end


 call_command(prefetcher_cmd, sed)


 return vim.notify(string.format("Prefetch initiated, awaiting response...")) end



 return {["fetches-query-string"] = fetches_query_string, ["fetches-names"] = fetches_names, ["fetches-query"] = fetches_query, ["get-root"] = get_root, ["find-all-local-bindings"] = find_all_local_bindings, ["try-get-value"] = try_get_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["prefetch-fetch-at-cursor"] = prefetch_fetch_at_cursor}