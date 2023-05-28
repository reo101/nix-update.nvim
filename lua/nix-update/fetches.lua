 local _local_1_ = require("nix-update.prefetchers") local gen_prefetcher_cmd = _local_1_["gen-prefetcher-cmd"]
 local get_prefetcher_extractor = _local_1_["get-prefetcher-extractor"]


 local _local_2_ = require("nix-update.util") local imap = _local_2_["imap"]
 local flatten = _local_2_["flatten"]
 local find_child = _local_2_["find-child"]
 local call_command = _local_2_["call-command"] local fetches_query_string = "\n(\n  (apply_expression\n    function:\n      [(variable_expression\n         name: (identifier) @_fname)\n       (select_expression\n         attrpath:\n           (attrpath\n             attr: (identifier) @_fname\n             .))]\n    argument:\n      [(attrset_expression\n         (binding_set) @_fargs)\n       (rec_attrset_expression\n         (binding_set) @_fargs)]\n  ) @_fwhole\n  (#any-of? @_fname %s)\n)\n       "



































 local fetches_names

 local _3_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for fetch, _ in pairs(gen_prefetcher_cmd) do
 local val_19_auto = string.format("\"%s\"", fetch) if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _3_ = tbl_17_auto end fetches_names = table.concat(_3_, " ")




 local fetches_query = vim.treesitter.parse_query("nix", string.format(fetches_query_string, fetches_names))





 local function get_root(opts)

 local opts0 = (opts or {})
 local _local_5_ = opts0 local bufnr = _local_5_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local parser = vim.treesitter.get_parser(bufnr0, "nix", {})
 local _let_7_ = parser:parse() local tree = _let_7_[1] return tree:root() end






 local function find_all_local_bindings(bounder, opts)

 local opts0 = (opts or {})
 local _local_8_ = opts0 local bufnr = _local_8_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local bindings = {}
 for binding, _ in bounder:iter_children() do local _10_ = binding:type()
 if (_10_ == "binding") then


 local attr
 local function _11_(_241) return (_241:type() == "attrpath") end attr = find_child(_11_, binding) local attr_name

 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr0) else attr_name = nil end local string_expr


 do local string_expression

 local function _13_(_241) return (_241:type() == "string_expression") end string_expression = find_child(_13_, binding)

 if string_expression then local tbl_17_auto = {}
 local i_18_auto = #tbl_17_auto for node, _0 in string_expression:iter_children() do local val_19_auto
 do local _14_ = node:type() if (_14_ == "interpolation") then


 local expression

 local function _15_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end expression = find_child(_15_, node)


 if expression then

 val_19_auto = {["?interp"] = node, name = vim.treesitter.get_node_text(expression, bufnr0)} else val_19_auto = nil end elseif (_14_ == "string_fragment") then





 val_19_auto = {node = node, value = vim.treesitter.get_node_text(node, bufnr0)} else val_19_auto = nil end end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end string_expr = tbl_17_auto else string_expr = nil end end local var_expr



 do local variable_expression

 local function _20_(_241) return (_241:type() == "variable_expression") end variable_expression = find_child(_20_, binding)

 if variable_expression then

 var_expr = {{name = vim.treesitter.get_node_text(variable_expression, bufnr0)}} else var_expr = nil end end


 local expr = (string_expr or var_expr)

 do end (bindings)[attr_name] = expr elseif (_10_ == "inherit") then


 local attrs
 local function _22_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(_22_, binding)


 for node, node_name in attrs:iter_children() do
 if ((node:type() == "identifier") and (node_name == "attr")) then


 local attr_name = vim.treesitter.get_node_text(node, bufnr0)



 do end (bindings)[attr_name] = {{name = attr_name}} else end end else end end


 return bindings end



 local function try_get_binding(bounder, identifier, opts)

 local opts0 = (opts or {})
 local _local_25_ = opts0 local bufnr = _local_25_["bufnr"]
 local depth = _local_25_["depth"]
 local depth_limit = _local_25_["depth-limit"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local depth0 = (depth or 0)
 local depth_limit0 = (depth_limit or 16)
 if (depth0 > depth_limit0) then
 vim.notify(string.format("Hit the depth-limit of %s!", depth_limit0))



 return nil else end







 local recurse_3f = (bounder:parent():type() ~= "attrset_expression")





 if not bounder then
 return nil else end


 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local function find_parent_bounder() local parent_bounder = bounder:parent():parent()






 while (parent_bounder and (parent_bounder:type() ~= "rec_attrset_expression") and (parent_bounder:type() ~= "let_expression")) do parent_bounder = parent_bounder:parent() end





 if parent_bounder then


 local function _29_(_241) return (_241:type() == "binding_set") end parent_bounder = find_child(_29_, parent_bounder) else end


 return parent_bounder end


 local bindings = find_all_local_bindings(bounder, {bufnr = bufnr0})


 local binding = bindings[identifier]
 local final_binding

 if binding then

 local find_up
 local function _33_(_31_) local _arg_32_ = _31_ local fragment = _arg_32_["v"]
 local _34_ = fragment if ((_G.type(_34_) == "table") and true and (nil ~= (_34_).node) and (nil ~= (_34_).value)) then local _3finterp = (_34_)["?interp"] local node = (_34_).node local value = (_34_).value


 return {["?interp"] = _3finterp, node = node, value = value} elseif ((_G.type(_34_) == "table") and true and (nil ~= (_34_).name)) then local _3finterp = (_34_)["?interp"] local name = (_34_).name


 local parent_bounder = find_parent_bounder() local next_bounder

 if recurse_3f then
 next_bounder = bounder else
 next_bounder = parent_bounder end
 if next_bounder then

 local resolved = try_get_binding(next_bounder, name, {bufnr = bufnr0, depth = (depth0 + 1), ["depth-limit"] = depth_limit0})






 for _, fragment0 in ipairs(resolved) do
 if not fragment0["?interp"] then
 fragment0["?interp"] = _3finterp else end end
 return resolved else

 return {notfound = name} end elseif ((_G.type(_34_) == "table") and (nil ~= (_34_).notfound)) then local notfound = (_34_).notfound


 return {notfound = notfound} else return nil end end find_up = _33_


 local full_fragments = imap(find_up, binding)
 final_binding = full_fragments else



 local parent_bounder = find_parent_bounder()
 if parent_bounder then

 final_binding = try_get_binding(parent_bounder, identifier, {bufnr = bufnr0, depth = (depth0 + 1), ["depth-limit"] = depth_limit0}) else






 final_binding = {notfound = identifier} end end


 return flatten(final_binding) end


 local function binding_to_value(binding) local result = ""

 local notfounds = {}

 for _, fragment in ipairs(binding) do

 local _41_ = fragment if ((_G.type(_41_) == "table") and (nil ~= (_41_).value)) then local value = (_41_).value


 result = (result .. value) elseif ((_G.type(_41_) == "table") and (nil ~= (_41_).notfound)) then local notfound = (_41_).notfound


 table.insert(notfounds, notfound) else end end

 if (#notfounds > 0) then
 return {bad = notfounds} else
 return {good = result} end end


 local function find_used_fetches(opts)

 local opts0 = (opts or {})
 local _local_44_ = opts0 local bufnr = _local_44_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local root = get_root({bufnr = bufnr0})


 local found_fetches

 do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _pattern, matcher, _metadata in fetches_query:iter_matches(root, bufnr0, 0, -1) do local val_19_auto


 do local tbl_14_auto = {} for id, node in pairs(matcher) do local k_15_auto, v_16_auto = nil, nil

 do local capture_id = fetches_query.captures[id]


 local function _47_() local _46_ = capture_id if (_46_ == "_fname") then


 return vim.treesitter.get_node_text(node, bufnr0) elseif (_46_ == "_fargs") then local tbl_14_auto0 = {}


 for name, _ in pairs(find_all_local_bindings(node, {bufnr = bufnr0})) do local k_15_auto0, v_16_auto0 = nil, nil

 do local value = try_get_binding(node, name, {bufnr = bufnr0})
 k_15_auto0, v_16_auto0 = name, value end if ((k_15_auto0 ~= nil) and (v_16_auto0 ~= nil)) then tbl_14_auto0[k_15_auto0] = v_16_auto0 else end end return tbl_14_auto0 elseif (_46_ == "_fwhole") then



 return node else return nil end end k_15_auto, v_16_auto = capture_id, _47_() end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end val_19_auto = tbl_14_auto end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end found_fetches = tbl_17_auto end


 return found_fetches end

 local function get_fetch_at_cursor(opts)

 local opts0 = (opts or {})
 local _local_52_ = opts0 local bufnr = _local_52_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches({bufnr = bufnr0})


 local _local_53_ = vim.fn.getcursorcharpos() local _ = _local_53_[1] local cursor_row = _local_53_[2] local cursor_col = _local_53_[3] local _0 = _local_53_[4] local _1 = _local_53_[5]


 for _2, fetch in ipairs(found_fetches) do
 if vim.treesitter.is_in_node_range(fetch._fwhole, cursor_row, cursor_col) then



 return fetch else end end return nil end

 local function prefetch_fetch_at_cursor(opts)

 local opts0 = (opts or {})
 local _local_55_ = opts0 local bufnr = _local_55_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local fetch_at_cursor = get_fetch_at_cursor({bufnr = bufnr0})


 if not fetch_at_cursor then
 vim.notify("No fetch found at cursor")
 return else end


 local prefetcher
 do local t_57_ = gen_prefetcher_cmd if (nil ~= t_57_) then t_57_ = (t_57_)[fetch_at_cursor._fname] else end prefetcher = t_57_ end


 if not prefetcher then
 vim.notify(string.format("No prefetcher '%s' found", fetch_at_cursor._fname))



 return nil else end


 local argument_values
 do
 local argument_values0 = {}
 local notfounds_pairs = {}


 for farg_name, farg_binding in pairs(fetch_at_cursor._fargs) do

 local _60_ = binding_to_value(farg_binding) if ((_G.type(_60_) == "table") and (nil ~= (_60_).good)) then local result = (_60_).good


 argument_values0[farg_name] = result elseif ((_G.type(_60_) == "table") and (nil ~= (_60_).bad)) then local notfounds = (_60_).bad


 table.insert(notfounds_pairs, {["farg-name"] = farg_name, notfounds = notfounds}) else end end



 for _, _62_ in ipairs(notfounds_pairs) do local _each_63_ = _62_ local farg_name = _each_63_["farg-name"] local notfounds = _each_63_["notfounds"]
 vim.notify(string.format("Identifiers %s not found while evaluating %s!", vim.inspect(notfounds), farg_name)) end






 if (#notfounds_pairs > 0) then
 return nil else end


 argument_values = argument_values0 end



 local prefetcher_cmd = prefetcher(argument_values)


 if not prefetcher_cmd then
 vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch_at_cursor._fname))



 return else end


 local prefetcher_extractor
 do local t_66_ = get_prefetcher_extractor if (nil ~= t_66_) then t_66_ = (t_66_)[fetch_at_cursor._fname] else end prefetcher_extractor = t_66_ end


 if not prefetcher_extractor then
 vim.notify(string.format("No data extractor for the prefetcher '%s' found", fetch_at_cursor._fname))



 return else end


 local function sed(_69_) local _arg_70_ = _69_ local stdout = _arg_70_["stdout"] local stderr = _arg_70_["stderr"]
 if (#stdout == 0) then
 vim.print(stderr)
 return else end

 local function coords(node)

 local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, bufnr0)
 return {["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col} end




 for key, new_value in pairs(prefetcher_extractor(stdout)) do
 local existing do local t_72_ = fetch_at_cursor if (nil ~= t_72_) then t_72_ = (t_72_)._fargs else end if (nil ~= t_72_) then t_72_ = (t_72_)[key] else end existing = t_72_ end
 if existing then local i_fragment = 1 local i_new_value = 1 local short_circuit_3f = false





 while (not short_circuit_3f and (i_new_value <= #new_value)) do

 local fragment = existing[i_fragment]
 local _let_75_ = fragment local fragment__3finterp = _let_75_["?interp"]
 local fragment_node = _let_75_["node"]
 local fragment_value = _let_75_["value"]
 if false then elseif (string.sub(new_value, i_new_value, (i_new_value + #fragment_value + -1)) == fragment_value) then











 i_fragment = (i_fragment + 1)
 i_new_value = (i_new_value + #fragment_value) elseif (i_fragment == #existing) then



 local _local_76_ = coords(fragment_node) local start_row = _local_76_["start-row"] local start_col = _local_76_["start-col"] local end_row = _local_76_["end-row"] local end_col = _local_76_["end-col"]

 vim.api.nvim_buf_set_text(bufnr0, start_row, start_col, end_row, end_col, {string.sub(new_value, i_new_value)}) short_circuit_3f = true else












 local last_fragment = existing[#existing]
 local _local_77_ = last_fragment local last_fragment__3finterp = _local_77_["?interp"]
 local last_fragment_node = _local_77_["node"]

 local _local_78_ = coords((fragment__3finterp or fragment_node)) local start_row = _local_78_["start-row"] local start_col = _local_78_["start-col"]

 local _local_79_ = coords((last_fragment__3finterp or last_fragment_node)) local end_row = _local_79_["end-row"] local end_col = _local_79_["end-col"]

 vim.api.nvim_buf_set_text(bufnr0, start_row, start_col, end_row, end_col, {string.sub(new_value, i_new_value)}) short_circuit_3f = true end end else








 local _let_81_ = coords(fetch_at_cursor._fwhole) local end_row = _let_81_["end-row"]
 vim.api.nvim_buf_set_lines(bufnr0, end_row, end_row, true, {string.format("%s = \"%s\";", key, new_value)})














 vim.cmd(string.format("normal ma%sggj==`a", end_row)) end end




 return vim.notify("Prefetch complete!") end


 call_command(prefetcher_cmd, sed)


 return vim.notify(string.format("Prefetch initiated, awaiting response...")) end



 return {["fetches-query-string"] = fetches_query_string, ["fetches-names"] = fetches_names, ["fetches-query"] = fetches_query, ["get-root"] = get_root, ["find-all-local-bindings"] = find_all_local_bindings, ["try-get-binding"] = try_get_binding, ["binding-to-value"] = binding_to_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["prefetch-fetch-at-cursor"] = prefetch_fetch_at_cursor}