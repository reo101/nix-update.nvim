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
 local _7_ do local t_6_ = config if (nil ~= t_6_) then t_6_ = (t_6_)["extra-prefetchers"] else end _7_ = t_6_ end vim.list_extend(names, keys(_7_()))
 return table.concat(names, " ") end


 local function gen_fetches_query()
 return vim.treesitter.parse_query("nix", string.format(fetches_query_string, gen_fetches_names())) end





 local function get_root(opts)

 local opts0 = (opts or {})
 local _local_9_ = opts0 local bufnr = _local_9_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local parser = vim.treesitter.get_parser(bufnr0, "nix", {})
 local _let_11_ = parser:parse() local tree = _let_11_[1] return tree:root() end






 local function find_all_local_bindings(opts)

 local opts0 = (opts or {})
 local _local_12_ = opts0 local bufnr = _local_12_["bufnr"]
 local bounder = _local_12_["bounder"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if not bounder then
 vim.notify("No bounder")
 return nil else end


 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local bindings = {}
 for binding, _ in bounder:iter_children() do local _15_ = binding:type()
 if (_15_ == "binding") then


 local attr
 local function _16_(_241) return (_241:type() == "attrpath") end attr = find_child(_16_, binding) local attr_name

 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr0) else attr_name = nil end local string_expr


 do local string_expression

 local function _18_(_241) return (_241:type() == "string_expression") end string_expression = find_child(_18_, binding)

 if string_expression then
 if (string_expression:named_child_count() > 0) then local tbl_17_auto = {}


 local i_18_auto = #tbl_17_auto for node, _0 in string_expression:iter_children() do local val_19_auto
 do local _19_ = node:type() if (_19_ == "interpolation") then


 local expression

 local function _20_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end expression = find_child(_20_, node)


 if expression then

 val_19_auto = {["?interp"] = node, name = vim.treesitter.get_node_text(expression, bufnr0)} else val_19_auto = nil end else local function _22_() local t = _19_ return ((t == "string_fragment") or (t == "escape_sequence")) end if ((nil ~= _19_) and _22_()) then local t = _19_






 val_19_auto = {node = node, value = vim.treesitter.get_node_text(node, bufnr0)} else val_19_auto = nil end end end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end string_expr = tbl_17_auto else




 local _let_25_ = coords({bufnr = bufnr0, node = string_expression}) local start_row = _let_25_["start-row"] local start_col = _let_25_["start-col"]

 local msg = string.format("Please don't leave empty strings (row %s, col %s)", (1 + start_row), (1 + start_col))




 vim.notify(msg)
 string_expr = error(msg) end else string_expr = nil end end local var_expr
 do local variable_expression

 local function _28_(_241) return (_241:type() == "variable_expression") end variable_expression = find_child(_28_, binding)

 if variable_expression then

 var_expr = {{name = vim.treesitter.get_node_text(variable_expression, bufnr0)}} else var_expr = nil end end


 local expr = (string_expr or var_expr)

 do end (bindings)[attr_name] = expr elseif (_15_ == "inherit") then


 local attrs
 local function _30_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(_30_, binding)


 for node, node_name in attrs:iter_children() do
 if ((node:type() == "identifier") and (node_name == "attr")) then


 local attr_name = vim.treesitter.get_node_text(node, bufnr0)



 do end (bindings)[attr_name] = {{name = attr_name}} else end end else end end


 return bindings end



 local function try_get_binding_value(opts)

 local opts0 = (opts or {})
 local _local_33_ = opts0 local bufnr = _local_33_["bufnr"]
 local bounder = _local_33_["bounder"]
 local identifier = _local_33_["identifier"]
 local depth = _local_33_["depth"]
 local depth_limit = _local_33_["depth-limit"]



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


 local parent_bounder do local _39_ = bounder if (nil ~= _39_) then local _40_ = _39_:parent() if (nil ~= _40_) then parent_bounder = _40_:parent() else parent_bounder = _40_ end else parent_bounder = _39_ end end










 while true do



 local function _43_(_241) return (_241:type() == "binding_set") end if not (parent_bounder and (((parent_bounder:type() ~= "rec_attrset_expression") and (parent_bounder:type() ~= "let_expression")) or not find_child(_43_, parent_bounder))) then break end parent_bounder = parent_bounder:parent() end




 if parent_bounder then


 local function _44_(_241) return (_241:type() == "binding_set") end parent_bounder = find_child(_44_, parent_bounder) else end


 return parent_bounder end


 local bindings = find_all_local_bindings({bufnr = bufnr0, bounder = bounder})


 local binding = bindings[identifier]
 local final_binding

 if binding then

 local find_up
 local function _48_(_46_) local _arg_47_ = _46_ local fragment = _arg_47_["v"]
 local _49_ = fragment if ((_G.type(_49_) == "table") and true and (nil ~= (_49_).node) and (nil ~= (_49_).value)) then local _3finterp = (_49_)["?interp"] local node = (_49_).node local value = (_49_).value


 return {["?interp"] = _3finterp, node = node, value = value} elseif ((_G.type(_49_) == "table") and true and (nil ~= (_49_).name)) then local _3finterp = (_49_)["?interp"] local name = (_49_).name


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

 return {notfound = name} end elseif ((_G.type(_49_) == "table") and (nil ~= (_49_).notfound)) then local notfound = (_49_).notfound


 return {notfound = notfound} else return nil end end find_up = _48_


 local full_fragments = imap(find_up, binding)
 final_binding = full_fragments else



 local parent_bounder = find_parent_bounder()
 if parent_bounder then

 final_binding = try_get_binding_value({bufnr = bufnr0, bounder = parent_bounder, identifier = identifier, depth = (depth0 + 1), ["depth-limit"] = depth_limit0}) else






 final_binding = {notfound = identifier} end end


 return flatten(final_binding) end

 local function try_get_binding_bounder(opts)

 local opts0 = (opts or {})
 local _local_56_ = opts0 local bufnr = _local_56_["bufnr"]
 local node = _local_56_["node"]
 local name = _local_56_["name"]



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

 do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for binding, _ in node:iter_children() do local val_19_auto
 do local _60_ = binding:type() if (_60_ == "binding") then


 local attr
 local function _61_(_241) return (_241:type() == "attrpath") end attr = find_child(_61_, binding) local attr_name

 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr) else attr_name = nil end


 if (attr_name == name) then
 val_19_auto = binding else val_19_auto = nil end elseif (_60_ == "inherit") then


 local attrs
 local function _64_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(_64_, binding) local attr



 local function _65_(_241, _242) return ((_241:type() == "identifier") and (_242 == "attr") and (vim.treesitter.get_node_text(_241, bufnr) == name)) end attr = find_child(_65_, attrs)






 val_19_auto = attr else val_19_auto = nil end end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end bindings = tbl_17_auto end

 return bindings[1] end


 local function fragments_to_value(binding) local result = ""

 local notfounds = {}

 for _, fragment in ipairs(binding) do

 local _68_ = fragment if ((_G.type(_68_) == "table") and (nil ~= (_68_).value)) then local value = (_68_).value


 result = (result .. value) elseif ((_G.type(_68_) == "table") and (nil ~= (_68_).notfound)) then local notfound = (_68_).notfound


 table.insert(notfounds, notfound) else end end

 if (#notfounds > 0) then
 return Result.err(notfounds) else
 return Result.ok(result) end end


 local function find_used_fetches(opts)

 local opts0 = (opts or {})
 local _local_71_ = opts0 local bufnr = _local_71_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local root = get_root({bufnr = bufnr0})


 local found_fetches
 do local fetches_query = gen_fetches_query() local tbl_17_auto = {}

 local i_18_auto = #tbl_17_auto for _pattern, matcher, _metadata in fetches_query:iter_matches(root, bufnr0, 0, -1) do local val_19_auto


 do local tbl_14_auto = {} for id, node in pairs(matcher) do local k_15_auto, v_16_auto = nil, nil

 do local capture_id = fetches_query.captures[id]


 local function _74_() local _73_ = capture_id if (_73_ == "_fname") then


 return vim.treesitter.get_node_text(node, bufnr0) elseif (_73_ == "_fargs") then local tbl_14_auto0 = {}


 for name, _ in pairs(find_all_local_bindings({bufnr = bufnr0, bounder = node})) do local k_15_auto0, v_16_auto0 = nil, nil


 do local binding = try_get_binding_bounder({bufnr = bufnr0, node = node, name = name})


 local fragments = try_get_binding_value({bufnr = bufnr0, bounder = node, identifier = name})


 k_15_auto0, v_16_auto0 = name, {binding = binding, fragments = fragments} end if ((k_15_auto0 ~= nil) and (v_16_auto0 ~= nil)) then tbl_14_auto0[k_15_auto0] = v_16_auto0 else end end return tbl_14_auto0 elseif (_73_ == "_fwhole") then




 return node else return nil end end k_15_auto, v_16_auto = capture_id, _74_() end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end val_19_auto = tbl_14_auto end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end found_fetches = tbl_17_auto end


 return found_fetches end

 local function get_fetch_at_cursor(opts)

 local opts0 = (opts or {})
 local _local_79_ = opts0 local bufnr = _local_79_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches({bufnr = bufnr0})


 local _local_80_ = vim.fn.getcursorcharpos() local _ = _local_80_[1] local cursor_row = _local_80_[2] local cursor_col = _local_80_[3] local _0 = _local_80_[4] local _1 = _local_80_[5]


 for _2, fetch in ipairs(found_fetches) do
 if vim.treesitter.is_in_node_range(fetch._fwhole, cursor_row, cursor_col) then



 return fetch else end end return nil end


 local function calculate_updates(opts)

 local opts0 = (opts or {})
 local _local_82_ = opts0 local bufnr = _local_82_["bufnr"]
 local fetch = _local_82_["fetch"]
 local new_data = _local_82_["new-data"]


 local updates = {}
 for key, new_value in pairs(new_data) do
 local existing do local t_83_ = fetch if (nil ~= t_83_) then t_83_ = (t_83_)._fargs else end if (nil ~= t_83_) then t_83_ = (t_83_)[key] else end if (nil ~= t_83_) then t_83_ = (t_83_).fragments else end existing = t_83_ end
 if existing then local i_fragment = 1 local i_new_value = 1 local short_circuit_3f = false





 while (not short_circuit_3f and (i_new_value <= #new_value)) do

 local fragment = existing[i_fragment]
 local _let_87_ = fragment local fragment_node = _let_87_["node"]
 local fragment_value = _let_87_["value"]
 local fragment__3finterp = _let_87_["?interp"]
 if false then elseif (string.sub(new_value, i_new_value, (i_new_value + #fragment_value + -1)) == fragment_value) then











 i_fragment = (i_fragment + 1)
 i_new_value = (i_new_value + #fragment_value) elseif (i_fragment == #existing) then



 local _local_88_ = coords({bufnr = bufnr, node = fragment_node}) local start_row = _local_88_["start-row"] local start_col = _local_88_["start-col"] local end_row = _local_88_["end-row"] local end_col = _local_88_["end-col"]

 table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}}) short_circuit_3f = true else














 local last_fragment = existing[#existing]
 local _local_89_ = last_fragment local last_fragment__3finterp = _local_89_["?interp"]
 local last_fragment_node = _local_89_["node"]

 local _local_90_ = coords({bufnr = bufnr, node = (fragment__3finterp or fragment_node)}) local start_row = _local_90_["start-row"] local start_col = _local_90_["start-col"]



 local _local_91_ = coords({bufnr = bufnr, node = (last_fragment__3finterp or last_fragment_node)}) local end_row = _local_91_["end-row"] local end_col = _local_91_["end-col"]



 table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}}) short_circuit_3f = true end end else










 local _let_93_ = coords({bufnr = bufnr, node = fetch._fwhole}) local end_row = _let_93_["end-row"] local end_col = _let_93_["end-col"]
 table.insert(updates, {type = "new", data = {bufnr = bufnr, start = end_row, ["end"] = end_row, replacement = {string.format("%s%s = \"%s\";", vim.fn["repeat"](" ", ((end_col - 1) + vim.bo[bufnr].shiftwidth)), key, new_value)}}}) end end
















 return updates end


 local function preview_update(update)

 local namespace = vim.api.nvim_create_namespace("NixUpdate")

 local _95_ = update if ((_G.type(_95_) == "table") and ((_95_).type == "old") and ((_G.type((_95_).data) == "table") and (nil ~= ((_95_).data).bufnr) and (nil ~= ((_95_).data)["start-row"]) and (nil ~= ((_95_).data)["start-col"]) and (nil ~= ((_95_).data)["end-row"]) and (nil ~= ((_95_).data)["end-col"]) and (nil ~= ((_95_).data).replacement))) then local bufnr = ((_95_).data).bufnr local start_row = ((_95_).data)["start-row"] local start_col = ((_95_).data)["start-col"] local end_row = ((_95_).data)["end-row"] local end_col = ((_95_).data)["end-col"] local replacement = ((_95_).data).replacement
















 local _96_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _, line in ipairs(replacement) do
 local val_19_auto = {line, "DiffAdd"} if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _96_ = tbl_17_auto end return vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, start_col, {end_row = end_row, end_col = end_col, hl_mode = "replace", virt_text = _96_, virt_text_pos = "overlay"}) elseif ((_G.type(_95_) == "table") and ((_95_).type == "new") and ((_G.type((_95_).data) == "table") and (nil ~= ((_95_).data).bufnr) and (nil ~= ((_95_).data).start) and (nil ~= ((_95_).data).replacement))) then local bufnr = ((_95_).data).bufnr local start = ((_95_).data).start local replacement = ((_95_).data).replacement











 local _98_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _, line in ipairs(replacement) do
 local val_19_auto = {{line, "DiffAdd"}} if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _98_ = tbl_17_auto end return vim.api.nvim_buf_set_extmark(bufnr, namespace, start, 0, {virt_lines = _98_, virt_lines_above = true}) else return nil end end



 local function apply_update(update)
 local _101_ = update if ((_G.type(_101_) == "table") and ((_101_).type == "old") and ((_G.type((_101_).data) == "table") and (nil ~= ((_101_).data).bufnr) and (nil ~= ((_101_).data)["start-row"]) and (nil ~= ((_101_).data)["start-col"]) and (nil ~= ((_101_).data)["end-row"]) and (nil ~= ((_101_).data)["end-col"]) and (nil ~= ((_101_).data).replacement))) then local bufnr = ((_101_).data).bufnr local start_row = ((_101_).data)["start-row"] local start_col = ((_101_).data)["start-col"] local end_row = ((_101_).data)["end-row"] local end_col = ((_101_).data)["end-col"] local replacement = ((_101_).data).replacement







 return vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, replacement) elseif ((_G.type(_101_) == "table") and ((_101_).type == "new") and ((_G.type((_101_).data) == "table") and (nil ~= ((_101_).data).bufnr) and (nil ~= ((_101_).data).start) and (nil ~= ((_101_).data)["end"]) and (nil ~= ((_101_).data).replacement))) then local bufnr = ((_101_).data).bufnr local start = ((_101_).data).start local _end = ((_101_).data)["end"] local replacement = ((_101_).data).replacement











 return vim.api.nvim_buf_set_lines(bufnr, start, _end, true, replacement) else return nil end end








 local function prefetch_fetch(opts)

 local opts0 = (opts or {})
 local _local_103_ = opts0 local bufnr = _local_103_["bufnr"]
 local fetch = _local_103_["fetch"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local fetch0 = (fetch or get_fetch_at_cursor({bufnr = bufnr0}))








 if not fetch0 then
 vim.notify("No fetch (neither given nor one at cursor)")
 return nil else end


 local prefetcher local function _105_()

 local t_106_ = config if (nil ~= t_106_) then t_106_ = (t_106_)["extra-prefetchers"] else end if (nil ~= t_106_) then t_106_ = (t_106_)[fetch0._fname] else end return t_106_ end local function _109_()
 local t_110_ = prefetchers if (nil ~= t_110_) then t_110_ = (t_110_)[fetch0._fname] else end return t_110_ end prefetcher = (_105_() or _109_())


 if not prefetcher then
 vim.notify(string.format("No prefetcher '%s' found", fetch0._fname))



 return nil else end


 local argument_values
 do
 local argument_values0 = {}
 local notfounds_pairs = {}


 for farg_name, farg_binding in pairs(fetch0._fargs) do



 local function _113_(result)
 argument_values0[farg_name] = result return nil end

 local function _114_(notfounds)
 return table.insert(notfounds_pairs, {["farg-name"] = farg_name, notfounds = notfounds}) end Result.bimap(fragments_to_value(farg_binding.fragments), _113_, _114_) end



 for _, _115_ in ipairs(notfounds_pairs) do local _each_116_ = _115_ local farg_name = _each_116_["farg-name"] local notfounds = _each_116_["notfounds"]
 vim.notify(string.format("Identifiers %s not found while evaluating %s!", vim.inspect(notfounds), farg_name)) end






 if (#notfounds_pairs > 0) then
 return nil else end


 argument_values = argument_values0 end



 local prefetcher_cmd = prefetcher(argument_values)


 if not prefetcher_cmd then
 vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch0._fname))



 return nil else end




 local function _121_(_119_) local _arg_120_ = _119_ local stdout = _arg_120_["stdout"] local stderr = _arg_120_["stderr"]
 if (#stdout == 0) then
 cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, err = string.format("Oopsie: %s", vim.inspect(stderr))}








 return nil else end

 cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, data = prefetcher.extractor(stdout)} return nil end call_command(prefetcher_cmd, _121_)







 return vim.notify(string.format("Prefetch initiated, awaiting response...")) end



 return {["fetches-query-string"] = fetches_query_string, ["gen-fetches-names"] = gen_fetches_names, ["gen-fetches-query"] = gen_fetches_query, ["get-root"] = get_root, ["find-all-local-bindings"] = find_all_local_bindings, ["try-get-binding-value"] = try_get_binding_value, ["fragments-to-value"] = fragments_to_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["calculate-updates"] = calculate_updates, ["preview-update"] = preview_update, ["apply-update"] = apply_update, ["prefetch-fetch"] = prefetch_fetch}
