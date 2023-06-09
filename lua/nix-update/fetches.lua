 local _local_1_ = require("nix-update.prefetchers") local prefetchers = _local_1_["prefetchers"]


 local _local_2_ = require("nix-update._cache") local cache = _local_2_["cache"]


 local _local_3_ = require("nix-update._config") local config = _local_3_["config"]


 local _local_4_ = require("nix-update.utils") local imap = _local_4_["imap"]
 local flatten = _local_4_["flatten"]
 local find_child = _local_4_["find-child"]
 local coords = _local_4_["coords"]
 local call_command = _local_4_["call-command"] local fetches_query_string = "\n(\n  (apply_expression\n    function:\n      [(variable_expression\n         name: (identifier) @_fname)\n       (select_expression\n         attrpath:\n           (attrpath\n             attr: (identifier) @_fname\n             .))]\n    argument:\n      [(attrset_expression\n         (binding_set) @_fargs)\n       (rec_attrset_expression\n         (binding_set) @_fargs)]\n  ) @_fwhole\n  (#any-of? @_fname %s)\n)\n       "



































 local function gen_fetches_names()


 local _5_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for fetch, _ in pairs(prefetchers) do
 local val_19_auto = string.format("\"%s\"", fetch) if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _5_ = tbl_17_auto end



 local _7_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto local _9_ do local t_8_ = config if (nil ~= t_8_) then t_8_ = (t_8_)["extra-prefetchers"] else end _9_ = t_8_ end for fetch, _ in pairs(_9_()) do
 local val_19_auto = string.format("\"%s\"", fetch) if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _7_ = tbl_17_auto end return (table.concat(_5_, " ") .. " " .. table.concat(_7_, " ")) end



 local function gen_fetches_query()
 return vim.treesitter.parse_query("nix", string.format(fetches_query_string, gen_fetches_names())) end





 local function get_root(opts)

 local opts0 = (opts or {})
 local _local_12_ = opts0 local bufnr = _local_12_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local parser = vim.treesitter.get_parser(bufnr0, "nix", {})
 local _let_14_ = parser:parse() local tree = _let_14_[1] return tree:root() end






 local function find_all_local_bindings(opts)

 local opts0 = (opts or {})
 local _local_15_ = opts0 local bufnr = _local_15_["bufnr"]
 local bounder = _local_15_["bounder"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if not bounder then
 vim.notify("No bounder")
 return nil else end


 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local bindings = {}
 for binding, _ in bounder:iter_children() do local _18_ = binding:type()
 if (_18_ == "binding") then


 local attr
 local function _19_(_241) return (_241:type() == "attrpath") end attr = find_child(_19_, binding) local attr_name

 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr0) else attr_name = nil end local string_expr


 do local string_expression

 local function _21_(_241) return (_241:type() == "string_expression") end string_expression = find_child(_21_, binding)

 if string_expression then local tbl_17_auto = {}
 local i_18_auto = #tbl_17_auto for node, _0 in string_expression:iter_children() do local val_19_auto
 do local _22_ = node:type() if (_22_ == "interpolation") then


 local expression

 local function _23_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end expression = find_child(_23_, node)


 if expression then

 val_19_auto = {["?interp"] = node, name = vim.treesitter.get_node_text(expression, bufnr0)} else val_19_auto = nil end elseif (_22_ == "string_fragment") then





 val_19_auto = {node = node, value = vim.treesitter.get_node_text(node, bufnr0)} else val_19_auto = nil end end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end string_expr = tbl_17_auto else string_expr = nil end end local var_expr



 do local variable_expression

 local function _28_(_241) return (_241:type() == "variable_expression") end variable_expression = find_child(_28_, binding)

 if variable_expression then

 var_expr = {{name = vim.treesitter.get_node_text(variable_expression, bufnr0)}} else var_expr = nil end end


 local expr = (string_expr or var_expr)

 do end (bindings)[attr_name] = expr elseif (_18_ == "inherit") then


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

 local function find_parent_bounder() local parent_bounder = bounder:parent():parent()







 while (parent_bounder and (parent_bounder:type() ~= "rec_attrset_expression") and (parent_bounder:type() ~= "let_expression")) do parent_bounder = parent_bounder:parent() end







 if parent_bounder then


 local function _39_(_241) return (_241:type() == "binding_set") end parent_bounder = find_child(_39_, parent_bounder) else end


 return parent_bounder end


 local bindings = find_all_local_bindings({bufnr = bufnr0, bounder = bounder})


 local binding = bindings[identifier]
 local final_binding

 if binding then

 local find_up
 local function _43_(_41_) local _arg_42_ = _41_ local fragment = _arg_42_["v"]
 local _44_ = fragment if ((_G.type(_44_) == "table") and true and (nil ~= (_44_).node) and (nil ~= (_44_).value)) then local _3finterp = (_44_)["?interp"] local node = (_44_).node local value = (_44_).value


 return {["?interp"] = _3finterp, node = node, value = value} elseif ((_G.type(_44_) == "table") and true and (nil ~= (_44_).name)) then local _3finterp = (_44_)["?interp"] local name = (_44_).name


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

 return {notfound = name} end elseif ((_G.type(_44_) == "table") and (nil ~= (_44_).notfound)) then local notfound = (_44_).notfound


 return {notfound = notfound} else return nil end end find_up = _43_


 local full_fragments = imap(find_up, binding)
 final_binding = full_fragments else



 local parent_bounder = find_parent_bounder()
 if parent_bounder then

 final_binding = try_get_binding_value({bufnr = bufnr0, bounder = parent_bounder, identifier = identifier, depth = (depth0 + 1), ["depth-limit"] = depth_limit0}) else






 final_binding = {notfound = identifier} end end


 return flatten(final_binding) end

 local function try_get_binding_bounder(opts)

 local opts0 = (opts or {})
 local _local_51_ = opts0 local bufnr = _local_51_["bufnr"]
 local node = _local_51_["node"]
 local name = _local_51_["name"]



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
 do local _55_ = binding:type() if (_55_ == "binding") then


 local attr
 local function _56_(_241) return (_241:type() == "attrpath") end attr = find_child(_56_, binding) local attr_name

 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr) else attr_name = nil end


 if (attr_name == name) then
 val_19_auto = binding else val_19_auto = nil end elseif (_55_ == "inherit") then


 local attrs
 local function _59_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(_59_, binding) local attr



 local function _60_(_241, _242) return ((_241:type() == "identifier") and (_242 == "attr") and (vim.treesitter.get_node_text(_241, bufnr) == name)) end attr = find_child(_60_, attrs)






 val_19_auto = attr else val_19_auto = nil end end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end bindings = tbl_17_auto end

 return bindings[1] end


 local function fragments_to_value(binding) local result = ""

 local notfounds = {}

 for _, fragment in ipairs(binding) do

 local _63_ = fragment if ((_G.type(_63_) == "table") and (nil ~= (_63_).value)) then local value = (_63_).value


 result = (result .. value) elseif ((_G.type(_63_) == "table") and (nil ~= (_63_).notfound)) then local notfound = (_63_).notfound


 table.insert(notfounds, notfound) else end end

 if (#notfounds > 0) then
 return {bad = notfounds} else
 return {good = result} end end


 local function find_used_fetches(opts)

 local opts0 = (opts or {})
 local _local_66_ = opts0 local bufnr = _local_66_["bufnr"]



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


 local function _69_() local _68_ = capture_id if (_68_ == "_fname") then


 return vim.treesitter.get_node_text(node, bufnr0) elseif (_68_ == "_fargs") then local tbl_14_auto0 = {}


 for name, _ in pairs(find_all_local_bindings({bufnr = bufnr0, bounder = node})) do local k_15_auto0, v_16_auto0 = nil, nil


 do local binding = try_get_binding_bounder({bufnr = bufnr0, node = node, name = name})


 local fragments = try_get_binding_value({bufnr = bufnr0, bounder = node, identifier = name})


 k_15_auto0, v_16_auto0 = name, {binding = binding, fragments = fragments} end if ((k_15_auto0 ~= nil) and (v_16_auto0 ~= nil)) then tbl_14_auto0[k_15_auto0] = v_16_auto0 else end end return tbl_14_auto0 elseif (_68_ == "_fwhole") then




 return node else return nil end end k_15_auto, v_16_auto = capture_id, _69_() end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end val_19_auto = tbl_14_auto end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end found_fetches = tbl_17_auto end


 return found_fetches end

 local function get_fetch_at_cursor(opts)

 local opts0 = (opts or {})
 local _local_74_ = opts0 local bufnr = _local_74_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches({bufnr = bufnr0})


 local _local_75_ = vim.fn.getcursorcharpos() local _ = _local_75_[1] local cursor_row = _local_75_[2] local cursor_col = _local_75_[3] local _0 = _local_75_[4] local _1 = _local_75_[5]


 for _2, fetch in ipairs(found_fetches) do
 if vim.treesitter.is_in_node_range(fetch._fwhole, cursor_row, cursor_col) then



 return fetch else end end return nil end


 local function calculate_updates(opts)

 local opts0 = (opts or {})
 local _local_77_ = opts0 local bufnr = _local_77_["bufnr"]
 local fetch = _local_77_["fetch"]
 local new_data = _local_77_["new-data"]


 local updates = {}
 for key, new_value in pairs(new_data) do
 local existing do local t_78_ = fetch if (nil ~= t_78_) then t_78_ = (t_78_)._fargs else end if (nil ~= t_78_) then t_78_ = (t_78_)[key] else end if (nil ~= t_78_) then t_78_ = (t_78_).fragments else end existing = t_78_ end
 if existing then local i_fragment = 1 local i_new_value = 1 local short_circuit_3f = false





 while (not short_circuit_3f and (i_new_value <= #new_value)) do

 local fragment = existing[i_fragment]
 local _let_82_ = fragment local fragment_node = _let_82_["node"]
 local fragment_value = _let_82_["value"]
 local fragment__3finterp = _let_82_["?interp"]
 if false then elseif (string.sub(new_value, i_new_value, (i_new_value + #fragment_value + -1)) == fragment_value) then











 i_fragment = (i_fragment + 1)
 i_new_value = (i_new_value + #fragment_value) elseif (i_fragment == #existing) then



 local _local_83_ = coords({bufnr = bufnr, node = fragment_node}) local start_row = _local_83_["start-row"] local start_col = _local_83_["start-col"] local end_row = _local_83_["end-row"] local end_col = _local_83_["end-col"]

 table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}}) short_circuit_3f = true else














 local last_fragment = existing[#existing]
 local _local_84_ = last_fragment local last_fragment__3finterp = _local_84_["?interp"]
 local last_fragment_node = _local_84_["node"]

 local _local_85_ = coords({bufnr = bufnr, node = (fragment__3finterp or fragment_node)}) local start_row = _local_85_["start-row"] local start_col = _local_85_["start-col"]



 local _local_86_ = coords({bufnr = bufnr, node = (last_fragment__3finterp or last_fragment_node)}) local end_row = _local_86_["end-row"] local end_col = _local_86_["end-col"]



 table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}}) short_circuit_3f = true end end else










 local _let_88_ = coords({bufnr = bufnr, node = fetch._fwhole}) local end_row = _let_88_["end-row"] local end_col = _let_88_["end-col"]
 table.insert(updates, {type = "new", data = {bufnr = bufnr, start = end_row, ["end"] = end_row, replacement = {string.format("%s%s = \"%s\";", vim.fn["repeat"](" ", ((end_col - 1) + vim.bo[bufnr].shiftwidth)), key, new_value)}}}) end end
















 return updates end


 local function preview_update(update)

 local namespace = vim.api.nvim_create_namespace("NixUpdate")

 local _90_ = update if ((_G.type(_90_) == "table") and ((_90_).type == "old") and ((_G.type((_90_).data) == "table") and (nil ~= ((_90_).data).bufnr) and (nil ~= ((_90_).data)["start-row"]) and (nil ~= ((_90_).data)["start-col"]) and (nil ~= ((_90_).data)["end-row"]) and (nil ~= ((_90_).data)["end-col"]) and (nil ~= ((_90_).data).replacement))) then local bufnr = ((_90_).data).bufnr local start_row = ((_90_).data)["start-row"] local start_col = ((_90_).data)["start-col"] local end_row = ((_90_).data)["end-row"] local end_col = ((_90_).data)["end-col"] local replacement = ((_90_).data).replacement
















 local _91_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _, line in ipairs(replacement) do
 local val_19_auto = {line, "DiffAdd"} if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _91_ = tbl_17_auto end return vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, start_col, {end_row = end_row, end_col = end_col, hl_mode = "replace", virt_text = _91_, virt_text_pos = "overlay"}) elseif ((_G.type(_90_) == "table") and ((_90_).type == "new") and ((_G.type((_90_).data) == "table") and (nil ~= ((_90_).data).bufnr) and (nil ~= ((_90_).data).start) and (nil ~= ((_90_).data).replacement))) then local bufnr = ((_90_).data).bufnr local start = ((_90_).data).start local replacement = ((_90_).data).replacement











 local _93_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _, line in ipairs(replacement) do
 local val_19_auto = {{line, "DiffAdd"}} if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _93_ = tbl_17_auto end return vim.api.nvim_buf_set_extmark(bufnr, namespace, start, 0, {virt_lines = _93_, virt_lines_above = true}) else return nil end end



 local function apply_update(update)
 local _96_ = update if ((_G.type(_96_) == "table") and ((_96_).type == "old") and ((_G.type((_96_).data) == "table") and (nil ~= ((_96_).data).bufnr) and (nil ~= ((_96_).data)["start-row"]) and (nil ~= ((_96_).data)["start-col"]) and (nil ~= ((_96_).data)["end-row"]) and (nil ~= ((_96_).data)["end-col"]) and (nil ~= ((_96_).data).replacement))) then local bufnr = ((_96_).data).bufnr local start_row = ((_96_).data)["start-row"] local start_col = ((_96_).data)["start-col"] local end_row = ((_96_).data)["end-row"] local end_col = ((_96_).data)["end-col"] local replacement = ((_96_).data).replacement







 return vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, replacement) elseif ((_G.type(_96_) == "table") and ((_96_).type == "new") and ((_G.type((_96_).data) == "table") and (nil ~= ((_96_).data).bufnr) and (nil ~= ((_96_).data).start) and (nil ~= ((_96_).data)["end"]) and (nil ~= ((_96_).data).replacement))) then local bufnr = ((_96_).data).bufnr local start = ((_96_).data).start local _end = ((_96_).data)["end"] local replacement = ((_96_).data).replacement











 return vim.api.nvim_buf_set_lines(bufnr, start, _end, true, replacement) else return nil end end








 local function prefetch_fetch(opts)

 local opts0 = (opts or {})
 local _local_98_ = opts0 local bufnr = _local_98_["bufnr"]
 local fetch = _local_98_["fetch"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local fetch0 = (fetch or get_fetch_at_cursor({bufnr = bufnr0}))








 if not fetch0 then
 vim.notify("No fetch (neither given nor one at cursor)")
 return nil else end


 local prefetcher local function _100_()

 local t_101_ = config if (nil ~= t_101_) then t_101_ = (t_101_)["extra-prefetchers"] else end if (nil ~= t_101_) then t_101_ = (t_101_)[fetch0._fname] else end return t_101_ end local function _104_()
 local t_105_ = prefetchers if (nil ~= t_105_) then t_105_ = (t_105_)[fetch0._fname] else end return t_105_ end prefetcher = (_100_() or _104_())


 if not prefetcher then
 vim.notify(string.format("No prefetcher '%s' found", fetch0._fname))



 return nil else end


 local argument_values
 do
 local argument_values0 = {}
 local notfounds_pairs = {}


 for farg_name, farg_binding in pairs(fetch0._fargs) do

 local _108_ = fragments_to_value(farg_binding.fragments) if ((_G.type(_108_) == "table") and (nil ~= (_108_).good)) then local result = (_108_).good


 argument_values0[farg_name] = result elseif ((_G.type(_108_) == "table") and (nil ~= (_108_).bad)) then local notfounds = (_108_).bad


 table.insert(notfounds_pairs, {["farg-name"] = farg_name, notfounds = notfounds}) else end end



 for _, _110_ in ipairs(notfounds_pairs) do local _each_111_ = _110_ local farg_name = _each_111_["farg-name"] local notfounds = _each_111_["notfounds"]
 vim.notify(string.format("Identifiers %s not found while evaluating %s!", vim.inspect(notfounds), farg_name)) end






 if (#notfounds_pairs > 0) then
 return nil else end


 argument_values = argument_values0 end



 local prefetcher_cmd = prefetcher(argument_values)


 if not prefetcher_cmd then
 vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch0._fname))



 return nil else end




 local function _116_(_114_) local _arg_115_ = _114_ local stdout = _arg_115_["stdout"] local stderr = _arg_115_["stderr"]
 if (#stdout == 0) then
 cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, err = string.format("Oopsie: %s", vim.inspect(stderr))}








 return nil else end

 cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, data = prefetcher.extractor(stdout)} return nil end call_command(prefetcher_cmd, _116_)







 return vim.notify(string.format("Prefetch initiated, awaiting response...")) end



 return {["fetches-query-string"] = fetches_query_string, ["gen-fetches-names"] = gen_fetches_names, ["gen-fetches-query"] = gen_fetches_query, ["get-root"] = get_root, ["find-all-local-bindings"] = find_all_local_bindings, ["try-get-binding-value"] = try_get_binding_value, ["fragments-to-value"] = fragments_to_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["calculate-updates"] = calculate_updates, ["preview-update"] = preview_update, ["apply-update"] = apply_update, ["prefetch-fetch"] = prefetch_fetch}