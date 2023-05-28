 local _local_1_ = require("nix-update.prefetchers") local gen_prefetcher_cmd = _local_1_["gen-prefetcher-cmd"]
 local get_prefetcher_extractor = _local_1_["get-prefetcher-extractor"]


 local _local_2_ = require("nix-update.util") local map = _local_2_["map"]
 local imap = _local_2_["imap"]
 local flatten = _local_2_["flatten"]
 local find_child = _local_2_["find-child"]
 local call_command = _local_2_["call-command"] local fetches_query_string = "\n(\n  (apply_expression\n    function:\n      [(variable_expression\n         name: (identifier) @_fname)\n       (select_expression\n         attrpath:\n           (attrpath\n             attr: (identifier) @_fname\n             .))]\n    argument:\n      (attrset_expression\n        (binding_set) @_fargs)\n      ;; FIXME: make argument resolution work for a rec_attrset_expression\n      ;;\n      ;; [(attrset_expression\n      ;;    (binding_set) @_fargs)\n      ;;  (rec_attrset_expression\n      ;;    (binding_set) @_fargs)]\n  ) @_fwhole\n  (#any-of? @_fname %s)\n)\n       "






























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
 attr_name = vim.treesitter.get_node_text(attr, bufnr) else attr_name = nil end local string_expr


 do local string_expression

 local function _11_(_241) return (_241:type() == "string_expression") end string_expression = find_child(_11_, binding:iter_children())

 if string_expression then local tbl_17_auto = {}
 local i_18_auto = #tbl_17_auto for node, _0 in string_expression:iter_children() do local val_19_auto
 do local _12_ = node:type() if (_12_ == "interpolation") then


 local expression

 local function _13_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end expression = find_child(_13_, node:iter_children())


 if expression then

 val_19_auto = {["?interp"] = node, name = vim.treesitter.get_node_text(expression, bufnr)} else val_19_auto = nil end elseif (_12_ == "string_fragment") then





 val_19_auto = {node = node, value = vim.treesitter.get_node_text(node, bufnr)} else val_19_auto = nil end end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end string_expr = tbl_17_auto else string_expr = nil end end local var_expr



 do local variable_expression

 local function _18_(_241) return (_241:type() == "variable_expression") end variable_expression = find_child(_18_, binding:iter_children())

 if variable_expression then

 var_expr = {{name = vim.treesitter.get_node_text(variable_expression, bufnr)}} else var_expr = nil end end


 local expr = (string_expr or var_expr)

 do end (bindings)[attr_name] = expr elseif (_8_ == "inherit") then


 local attrs
 local function _20_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(_20_, binding:iter_children())


 for node, node_name in attrs:iter_children() do
 if ((node:type() == "identifier") and (node_name == "attr")) then


 local attr_name = vim.treesitter.get_node_text(node, bufnr)



 do end (bindings)[attr_name] = {{name = attr_name}} else end end else end end


 return bindings end



 local function try_get_binding(bounder, identifier, _3fbufnr)

 local bufnr = (_3fbufnr or vim.api.nvim_get_current_buf())



 if not bounder then
 return nil else end


 if (vim.bo[bufnr].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local bindings = find_all_local_bindings(bounder, bufnr)


 local binding = bindings[identifier]


 local target = bounder:parent():parent()
 while (target and (target:type() ~= "rec_attrset_expression") and (target:type() ~= "let_expression")) do target = target:parent() end





 if target then



 local function _25_(_241) return (_241:type() == "binding_set") end target = find_child(_25_, target:iter_children()) else end


 local final_binding

 if binding then

 local find_up
 local function _27_(fragment)
 local _28_ = fragment if ((_G.type(_28_) == "table") and true and (nil ~= (_28_).node) and (nil ~= (_28_).value)) then local _3finterp = (_28_)["?interp"] local node = (_28_).node local value = (_28_).value


 return {["?interp"] = _3finterp, node = node, value = value} elseif ((_G.type(_28_) == "table") and true and (nil ~= (_28_).name)) then local _3finterp = (_28_)["?interp"] local name = (_28_).name


 local resolved = flatten(try_get_binding(target, name, bufnr))

 for i, fragment0 in ipairs(resolved) do
 if not fragment0["?interp"] then
 fragment0["?interp"] = _3finterp else end end
 return resolved elseif (_28_ == nil) then


 return nil else return nil end end find_up = _27_


 local full_fragments = imap(find_up, binding)
 final_binding = full_fragments else

 final_binding = try_get_binding(target, binding, bufnr) end


 return flatten(final_binding) end


 local function binding_to_value(binding)


 local function _32_(_241) return _241.value end return table.concat(imap(_32_, binding)) end



 local function find_used_fetches(_3fbufnr)

 local bufnr = (_3fbufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local root = get_root(bufnr)


 local found_fetches

 do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _pattern, matcher, _metadata in fetches_query:iter_matches(root, bufnr, 0, -1) do local val_19_auto


 do local tbl_14_auto = {} for id, node in pairs(matcher) do local k_15_auto, v_16_auto = nil, nil

 do local capture_id = fetches_query.captures[id]


 local function _35_() local _34_ = capture_id if (_34_ == "_fname") then


 return vim.treesitter.get_node_text(node, bufnr) elseif (_34_ == "_fargs") then local tbl_14_auto0 = {}


 for name, _ in pairs(find_all_local_bindings(node, bufnr)) do local k_15_auto0, v_16_auto0 = nil, nil

 do local value = try_get_binding(node, name, bufnr)
 k_15_auto0, v_16_auto0 = name, value end if ((k_15_auto0 ~= nil) and (v_16_auto0 ~= nil)) then tbl_14_auto0[k_15_auto0] = v_16_auto0 else end end return tbl_14_auto0 elseif (_34_ == "_fwhole") then



 return node else return nil end end k_15_auto, v_16_auto = capture_id, _35_() end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end val_19_auto = tbl_14_auto end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end found_fetches = tbl_17_auto end


 return found_fetches end

 local function get_fetch_at_cursor(_3fbufnr)

 local bufnr = (_3fbufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches(bufnr)


 local _local_40_ = vim.fn.getcursorcharpos() local _ = _local_40_[1] local cursor_row = _local_40_[2] local cursor_col = _local_40_[3] local _0 = _local_40_[4] local _1 = _local_40_[5]


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
 do local t_43_ = gen_prefetcher_cmd if (nil ~= t_43_) then t_43_ = (t_43_)[fetch_at_cursor._fname] else end prefetcher = t_43_ end


 if (prefetcher == nil) then
 vim.notify(string.format("No prefetcher '%s' found", fetch_at_cursor._fname))



 return else end



 local prefetcher_cmd = prefetcher(map(binding_to_value, fetch_at_cursor._fargs))




 if (prefetcher_cmd == nil) then
 vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch_at_cursor._fname))



 return else end


 local prefetcher_extractor
 do local t_47_ = get_prefetcher_extractor if (nil ~= t_47_) then t_47_ = (t_47_)[fetch_at_cursor._fname] else end prefetcher_extractor = t_47_ end


 if (prefetcher_extractor == nil) then
 vim.notify(string.format("No data extractor for the prefetcher '%s' found", fetch_at_cursor._fname))



 return else end


 local function sed(_50_) local _arg_51_ = _50_ local stdout = _arg_51_["stdout"] local stderr = _arg_51_["stderr"]
 if (#stdout == 0) then
 vim.print(stderr)
 return else end

 local function coords(node)

 local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, bufnr)
 return {["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col} end




 for key, new_value in pairs(prefetcher_extractor(stdout)) do
 local existing do local t_53_ = fetch_at_cursor if (nil ~= t_53_) then t_53_ = (t_53_)._fargs else end if (nil ~= t_53_) then t_53_ = (t_53_)[key] else end existing = t_53_ end
 if existing then local i_fragment = 1 local i_new_value = 1 local short_circuit_3f = false





 while (not short_circuit_3f and (i_new_value <= #new_value)) do

 local fragment = existing[i_fragment]
 local _let_56_ = fragment local fragment__3finterp = _let_56_["?interp"]
 local fragment_node = _let_56_["node"]
 local fragment_value = _let_56_["value"]
 if false then elseif (string.sub(new_value, i_new_value, (i_new_value + #fragment_value + -1)) == fragment_value) then











 i_fragment = (i_fragment + 1)
 i_new_value = (i_new_value + #fragment_value) elseif (i_fragment == #existing) then



 local _local_57_ = coords(fragment_node) local start_row = _local_57_["start-row"] local start_col = _local_57_["start-col"] local end_row = _local_57_["end-row"] local end_col = _local_57_["end-col"]

 vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, {string.sub(new_value, i_new_value)}) short_circuit_3f = true else












 local last_fragment = existing[#existing]
 local _local_58_ = last_fragment local last_fragment__3finterp = _local_58_["?interp"]
 local last_fragment_node = _local_58_["node"]

 local _local_59_ = coords((fragment__3finterp or fragment_node)) local start_row = _local_59_["start-row"] local start_col = _local_59_["start-col"]

 local _local_60_ = coords((last_fragment__3finterp or last_fragment_node)) local end_row = _local_60_["end-row"] local end_col = _local_60_["end-col"]

 vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, {string.sub(new_value, i_new_value)}) short_circuit_3f = true end end else








 local _let_62_ = coords(fetch_at_cursor._fwhole) local end_row = _let_62_["end-row"]
 vim.api.nvim_buf_set_lines(bufnr, end_row, end_row, true, {string.format("%s = \"%s\";", key, new_value)})














 vim.cmd(string.format("normal ma%sggj==`a", end_row)) end end




 return vim.notify("Prefetch complete!") end


 call_command(prefetcher_cmd, sed)


 return vim.notify(string.format("Prefetch initiated, awaiting response...")) end



 return {["fetches-query-string"] = fetches_query_string, ["fetches-names"] = fetches_names, ["fetches-query"] = fetches_query, ["get-root"] = get_root, ["find-all-local-bindings"] = find_all_local_bindings, ["try-get-binding"] = try_get_binding, ["binding-to-value"] = binding_to_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["prefetch-fetch-at-cursor"] = prefetch_fetch_at_cursor}