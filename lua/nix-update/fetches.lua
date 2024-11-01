 local _local_1_ = require("nix-update.prefetchers") local prefetchers = _local_1_["prefetchers"]


 local _local_2_ = require("nix-update._cache") local cache = _local_2_["cache"]


 local _local_3_ = require("nix-update._config") local config = _local_3_["config"]


 local _local_4_ = require("nix-update.utils.fp") local Result = _local_4_["Result"]


 local _local_5_ = require("nix-update.utils") local keys = _local_5_["keys"]
 local imap = _local_5_["imap"]
 local flatten = _local_5_["flatten"]
 local find_child = _local_5_["find-child"]
 local coords = _local_5_["coords"]
 local call_command = _local_5_["call-command"] local fetches_query_string = "\n(\n  (apply_expression\n    function:\n      [(variable_expression\n         name: (identifier) @_fname)\n       (select_expression\n         attrpath:\n           (attrpath\n             attr: (identifier) @_fname\n             .))]\n    argument:\n      [(attrset_expression\n         (binding_set) @_fargs)\n       (rec_attrset_expression\n         (binding_set) @_fargs)]\n  ) @_fwhole\n  (#any-of? @_fname %s)\n)\n       "


























 local function gen_fetches_names()
 local names = {}
 vim.list_extend(names, keys(prefetchers))
 local _7_ do local t_6_ = config if (nil ~= t_6_) then t_6_ = t_6_["extra-prefetchers"] else end _7_ = t_6_ end vim.list_extend(names, keys(_7_()))
 return table.concat(names, " ") end


 local function gen_fetches_query()
 return vim.treesitter.query.parse("nix", string.format(fetches_query_string, gen_fetches_names())) end





 local function get_root(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local parser = vim.treesitter.get_parser(bufnr0, "nix", {})
 local _let_10_ = parser:parse() local tree = _let_10_[1] return tree:root() end






 local function find_all_local_bindings(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]
 local bounder = opts0["bounder"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if not bounder then
 vim.notify("No bounder")
 return nil else end


 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local bindings = {}
 for binding, _ in bounder:iter_children() do local _13_ = binding:type()
 if (_13_ == "binding") then


 local attr
 local function _14_(_241) return (_241:type() == "attrpath") end attr = find_child(_14_, binding) local attr_name

 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr0) else attr_name = nil end local string_expr


 do local string_expression

 local function _16_(_241) return (_241:type() == "string_expression") end string_expression = find_child(_16_, binding)

 if string_expression then
 if (string_expression:named_child_count() > 0) then


 local tbl_21_auto = {} local i_22_auto = 0 for node, _0 in string_expression:iter_children() do local val_23_auto
 do local _17_ = node:type() if (_17_ == "interpolation") then


 local expression

 local function _18_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end expression = find_child(_18_, node)


 if expression then

 val_23_auto = {["?interp"] = node, name = vim.treesitter.get_node_text(expression, bufnr0)} else val_23_auto = nil end else local and_20_ = (nil ~= _17_) if and_20_ then local t = _17_ and_20_ = ((t == "string_fragment") or (t == "escape_sequence")) end if and_20_ then local t = _17_






 val_23_auto = {node = node, value = vim.treesitter.get_node_text(node, bufnr0)} else val_23_auto = nil end end end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end string_expr = tbl_21_auto else




 local _let_24_ = coords({bufnr = bufnr0, node = string_expression}) local start_row = _let_24_["start-row"] local start_col = _let_24_["start-col"]

 local msg = string.format("Please don't leave empty strings (row %s, col %s)", (1 + start_row), (1 + start_col))




 vim.notify(msg)
 string_expr = error(msg) end else string_expr = nil end end local var_expr
 do local variable_expression

 local function _27_(_241) return (_241:type() == "variable_expression") end variable_expression = find_child(_27_, binding)

 if variable_expression then

 var_expr = {{name = vim.treesitter.get_node_text(variable_expression, bufnr0)}} else var_expr = nil end end


 local expr = (string_expr or var_expr)

 bindings[attr_name] = expr elseif (_13_ == "inherit") then


 local attrs
 local function _29_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(_29_, binding)


 for node, node_name in attrs:iter_children() do
 if ((node:type() == "identifier") and (node_name == "attr")) then


 local attr_name = vim.treesitter.get_node_text(node, bufnr0)



 bindings[attr_name] = {{name = attr_name}} else end end else end end


 return bindings end



 local function try_get_binding_value(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]
 local bounder = opts0["bounder"]
 local identifier = opts0["identifier"]
 local depth = opts0["depth"]
 local depth_limit = opts0["depth-limit"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if not bounder then
 vim.notify("No bounder")
 return nil else end


 if not identifier then
 vim.notify("No identifier")
 return nil else end


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

 local function find_parent_bounder()


 local parent_bounder if (nil ~= bounder) then local tmp_3_auto = bounder:parent() if (nil ~= tmp_3_auto) then parent_bounder = tmp_3_auto:parent() else parent_bounder = nil end else parent_bounder = nil end










 while true do local and_39_ = parent_bounder
 if and_39_ then local or_40_ = ((parent_bounder:type() ~= "rec_attrset_expression") and (parent_bounder:type() ~= "let_expression"))

 if not or_40_ then
 local function _41_(_241) return (_241:type() == "binding_set") end or_40_ = not find_child(_41_, parent_bounder) end and_39_ = or_40_ end if not and_39_ then break end parent_bounder = parent_bounder:parent() end




 if parent_bounder then


 local function _42_(_241) return (_241:type() == "binding_set") end parent_bounder = find_child(_42_, parent_bounder) else end


 return parent_bounder end


 local bindings = find_all_local_bindings({bufnr = bufnr0, bounder = bounder})


 local binding = bindings[identifier]
 local final_binding

 if binding then

 local find_up
 local function _45_(_44_) local fragment = _44_["v"]
 if ((_G.type(fragment) == "table") and true and (nil ~= fragment.node) and (nil ~= fragment.value)) then local _3finterp = fragment["?interp"] local node = fragment.node local value = fragment.value


 return {["?interp"] = _3finterp, node = node, value = value} elseif ((_G.type(fragment) == "table") and true and (nil ~= fragment.name)) then local _3finterp = fragment["?interp"] local name = fragment.name


 local parent_bounder = find_parent_bounder() local next_bounder

 if recurse_3f then
 next_bounder = bounder else
 next_bounder = parent_bounder end
 if next_bounder then

 local resolved = try_get_binding_value({bufnr = bufnr0, bounder = next_bounder, identifier = name, depth = (depth0 + 1), ["depth-limit"] = depth_limit0})






 for _, fragment0 in ipairs(resolved) do
 if not fragment0["?interp"] then
 fragment0["?interp"] = _3finterp else end end
 return resolved else

 return {notfound = name} end elseif ((_G.type(fragment) == "table") and (nil ~= fragment.notfound)) then local notfound = fragment.notfound


 return {notfound = notfound} else return nil end end find_up = _45_


 local full_fragments = imap(find_up, binding)
 final_binding = full_fragments else



 local parent_bounder = find_parent_bounder()
 if parent_bounder then

 final_binding = try_get_binding_value({bufnr = bufnr0, bounder = parent_bounder, identifier = identifier, depth = (depth0 + 1), ["depth-limit"] = depth_limit0}) else






 final_binding = {notfound = identifier} end end


 return flatten(final_binding) end

 local function try_get_binding_bounder(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]
 local node = opts0["node"]
 local name = opts0["name"]



 if not bufnr then
 vim.notify("No bufnr")
 return nil else end


 if not node then
 vim.notify("No node")
 return nil else end


 if not name then
 vim.notify("No name")
 return nil else end


 local bindings

 do local tbl_21_auto = {} local i_22_auto = 0 for binding, _ in node:iter_children() do local val_23_auto
 do local _55_ = binding:type() if (_55_ == "binding") then


 local attr
 local function _56_(_241) return (_241:type() == "attrpath") end attr = find_child(_56_, binding) local attr_name

 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr) else attr_name = nil end


 if (attr_name == name) then
 val_23_auto = binding else val_23_auto = nil end elseif (_55_ == "inherit") then


 local attrs
 local function _59_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(_59_, binding) local attr



 local function _60_(_241, _242) return ((_241:type() == "identifier") and (_242 == "attr") and (vim.treesitter.get_node_text(_241, bufnr) == name)) end attr = find_child(_60_, attrs)






 val_23_auto = attr else val_23_auto = nil end end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end bindings = tbl_21_auto end

 return bindings[1] end


 local function fragments_to_value(binding) local result = ""

 local notfounds = {}

 for _, fragment in ipairs(binding) do

 if ((_G.type(fragment) == "table") and (nil ~= fragment.value)) then local value = fragment.value


 result = (result .. value) elseif ((_G.type(fragment) == "table") and (nil ~= fragment.notfound)) then local notfound = fragment.notfound


 table.insert(notfounds, notfound) else end end

 if (#notfounds > 0) then
 return Result.err(notfounds) else
 return Result.ok(result) end end


 local function find_used_fetches(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local root = get_root({bufnr = bufnr0})


 local found_fetches
 do local fetches_query = gen_fetches_query()
























































 local tbl_21_auto = {} local i_22_auto = 0 for _pattern, matcher, _metadata in fetches_query:iter_matches(root, bufnr0, 0, -1) do local val_23_auto


 do
 local res = {}
 for id, nodes in pairs(matcher) do
 local tbl_16_auto = res for _, node in ipairs(nodes) do local k_17_auto, v_18_auto = nil, nil
 do local capture_id = fetches_query.captures[id]


 local function _67_() if (capture_id == "_fname") then


 return vim.treesitter.get_node_text(node, bufnr0) elseif (capture_id == "_fargs") then local tbl_16_auto0 = {}


 for name, _0 in pairs(find_all_local_bindings({bufnr = bufnr0, bounder = node})) do local k_17_auto0, v_18_auto0 = nil, nil


 do local binding = try_get_binding_bounder({bufnr = bufnr0, node = node, name = name})


 local fragments = try_get_binding_value({bufnr = bufnr0, bounder = node, identifier = name})


 k_17_auto0, v_18_auto0 = name, {binding = binding, fragments = fragments} end if ((k_17_auto0 ~= nil) and (v_18_auto0 ~= nil)) then tbl_16_auto0[k_17_auto0] = v_18_auto0 else end end return tbl_16_auto0 elseif (capture_id == "_fwhole") then




 return node else return nil end end k_17_auto, v_18_auto = capture_id, _67_() end if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end end
 val_23_auto = res end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end found_fetches = tbl_21_auto end


 return found_fetches end

 local function get_fetch_at_cursor(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches({bufnr = bufnr0})


 local _local_70_ = vim.fn.getcursorcharpos() local _ = _local_70_[1] local cursor_row = _local_70_[2] local cursor_col = _local_70_[3] local _0 = _local_70_[4] local _1 = _local_70_[5]


 for _2, fetch in ipairs(found_fetches) do
 if vim.treesitter.is_in_node_range(fetch._fwhole, cursor_row, cursor_col) then



 return fetch else end end return nil end


 local function calculate_updates(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]
 local fetch = opts0["fetch"]
 local new_data = opts0["new-data"]


 local updates = {}
 for key, new_value in pairs(new_data) do
 local existing do local t_72_ = fetch if (nil ~= t_72_) then t_72_ = t_72_._fargs else end if (nil ~= t_72_) then t_72_ = t_72_[key] else end if (nil ~= t_72_) then t_72_ = t_72_.fragments else end existing = t_72_ end
 if existing then local i_fragment = 1 local i_new_value = 1 local short_circuit_3f = false





 while (not short_circuit_3f and (i_new_value <= #new_value)) do

 local fragment = existing[i_fragment]
 local fragment_node = fragment["node"]
 local fragment_value = fragment["value"]
 local fragment__3finterp = fragment["?interp"]
 if false then elseif (string.sub(new_value, i_new_value, (i_new_value + #fragment_value + -1)) == fragment_value) then











 i_fragment = (i_fragment + 1)
 i_new_value = (i_new_value + #fragment_value) elseif (i_fragment == #existing) then



 local _local_76_ = coords({bufnr = bufnr, node = fragment_node}) local start_row = _local_76_["start-row"] local start_col = _local_76_["start-col"] local end_row = _local_76_["end-row"] local end_col = _local_76_["end-col"]

 table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}}) short_circuit_3f = true else














 local last_fragment = existing[#existing]
 local last_fragment__3finterp = last_fragment["?interp"]
 local last_fragment_node = last_fragment["node"]

 local _local_77_ = coords({bufnr = bufnr, node = (fragment__3finterp or fragment_node)}) local start_row = _local_77_["start-row"] local start_col = _local_77_["start-col"]



 local _local_78_ = coords({bufnr = bufnr, node = (last_fragment__3finterp or last_fragment_node)}) local end_row = _local_78_["end-row"] local end_col = _local_78_["end-col"]



 table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}}) short_circuit_3f = true end end else










 local _let_80_ = coords({bufnr = bufnr, node = fetch._fwhole}) local end_row = _let_80_["end-row"] local end_col = _let_80_["end-col"]
 table.insert(updates, {type = "new", data = {bufnr = bufnr, start = end_row, ["end"] = end_row, replacement = {string.format("%s%s = \"%s\";", vim.fn["repeat"](" ", ((end_col - 1) + vim.bo[bufnr].shiftwidth)), key, new_value)}}}) end end
















 return updates end


 local function preview_update(update)

 local namespace = vim.api.nvim_create_namespace("NixUpdate")

 if ((_G.type(update) == "table") and (update.type == "old") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data["start-row"]) and (nil ~= update.data["start-col"]) and (nil ~= update.data["end-row"]) and (nil ~= update.data["end-col"]) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start_row = update.data["start-row"] local start_col = update.data["start-col"] local end_row = update.data["end-row"] local end_col = update.data["end-col"] local replacement = update.data.replacement
















 local _82_ do local tbl_21_auto = {} local i_22_auto = 0 for _, line in ipairs(replacement) do
 local val_23_auto = {line, "DiffAdd"} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _82_ = tbl_21_auto end return vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, start_col, {end_row = end_row, end_col = end_col, hl_mode = "replace", virt_text = _82_, virt_text_pos = "overlay"}) elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start = update.data.start local replacement = update.data.replacement











 local _84_ do local tbl_21_auto = {} local i_22_auto = 0 for _, line in ipairs(replacement) do
 local val_23_auto = {{line, "DiffAdd"}} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _84_ = tbl_21_auto end return vim.api.nvim_buf_set_extmark(bufnr, namespace, start, 0, {virt_lines = _84_, virt_lines_above = true}) else return nil end end



 local function apply_update(update)
 if ((_G.type(update) == "table") and (update.type == "old") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data["start-row"]) and (nil ~= update.data["start-col"]) and (nil ~= update.data["end-row"]) and (nil ~= update.data["end-col"]) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start_row = update.data["start-row"] local start_col = update.data["start-col"] local end_row = update.data["end-row"] local end_col = update.data["end-col"] local replacement = update.data.replacement







 return vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, replacement) elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data["end"]) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start = update.data.start local _end = update.data["end"] local replacement = update.data.replacement











 return vim.api.nvim_buf_set_lines(bufnr, start, _end, true, replacement) else return nil end end








 local function prefetch_fetch(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]
 local fetch = opts0["fetch"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local fetch0 = (fetch or get_fetch_at_cursor({bufnr = bufnr0}))








 if not fetch0 then
 vim.notify("No fetch (neither given nor one at cursor)")
 return nil else end


 local prefetcher

 local _90_ do local t_89_ = config if (nil ~= t_89_) then t_89_ = t_89_["extra-prefetchers"] else end if (nil ~= t_89_) then t_89_ = t_89_[fetch0._fname] else end _90_ = t_89_ end local or_93_ = _90_
 if not or_93_ then local t_94_ = prefetchers if (nil ~= t_94_) then t_94_ = t_94_[fetch0._fname] else end or_93_ = t_94_ end prefetcher = or_93_


 if not prefetcher then
 vim.notify(string.format("No prefetcher '%s' found", fetch0._fname))



 return nil else end


 local argument_values
 do
 local argument_values0 = {}
 local notfounds_pairs = {}


 for farg_name, farg_binding in pairs(fetch0._fargs) do



 local function _97_(result)
 argument_values0[farg_name] = result return nil end

 local function _98_(notfounds)
 return table.insert(notfounds_pairs, {["farg-name"] = farg_name, notfounds = notfounds}) end Result.bimap(fragments_to_value(farg_binding.fragments), _97_, _98_) end



 for _, _99_ in ipairs(notfounds_pairs) do local farg_name = _99_["farg-name"] local notfounds = _99_["notfounds"]
 vim.notify(string.format("Identifiers %s not found while evaluating %s!", vim.inspect(notfounds), farg_name)) end






 if (#notfounds_pairs > 0) then
 return nil else end


 argument_values = argument_values0 end



 local prefetcher_cmd = prefetcher(argument_values)


 if not prefetcher_cmd then
 vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch0._fname))



 return nil else end




 local function _103_(_102_) local stdout = _102_["stdout"] local stderr = _102_["stderr"]
 if (#stdout == 0) then
 cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, err = string.format("Oopsie: %s", vim.inspect(stderr))}








 return nil else end

 cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, data = prefetcher.extractor(stdout)} return nil end call_command(prefetcher_cmd, _103_)







 return vim.notify(string.format("Prefetch initiated, awaiting response...")) end



 return {["fetches-query-string"] = fetches_query_string, ["gen-fetches-names"] = gen_fetches_names, ["gen-fetches-query"] = gen_fetches_query, ["get-root"] = get_root, ["find-all-local-bindings"] = find_all_local_bindings, ["try-get-binding-value"] = try_get_binding_value, ["fragments-to-value"] = fragments_to_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["calculate-updates"] = calculate_updates, ["preview-update"] = preview_update, ["apply-update"] = apply_update, ["prefetch-fetch"] = prefetch_fetch}
