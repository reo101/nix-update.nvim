 local _local_1_ = require("nix-update.prefetchers") local prefetchers = _local_1_["prefetchers"]


 local _local_2_ = require("nix-update._cache") local cache = _local_2_["cache"]


 local _local_3_ = require("nix-update._config") local config = _local_3_["config"]


 local _local_4_ = require("nix-update.utils.fp") local Result = _local_4_["Result"]


 local _local_5_ = require("nix-update.utils") local keys = _local_5_["keys"]
 local imap = _local_5_["imap"]
 local flatten = _local_5_["flatten"]
 local find_child = _local_5_["find-child"]
 local find_children = _local_5_["find-children"]
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

 local function _14_(_241, _242) return ((_241:type() == "attrpath") and (_242 == "attrpath")) end attr = find_child(binding, _14_) local attr_name

 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr0) else attr_name = nil end local bool_expr



 do local bool_expr0


 local function _16_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end bool_expr0 = find_child(binding, _16_)

 if bool_expr0 then
 local bool_expr_value = vim.treesitter.get_node_text(bool_expr0, bufnr0)
 if vim.list_contains({"true", "false"}, bool_expr_value) then
 bool_expr = {{node = bool_expr0, value = bool_expr_value}} else bool_expr = nil end else bool_expr = nil end end local string_expr

 do local string_expression


 local function _19_(_241, _242) return ((_241:type() == "string_expression") and (_242 == "expression")) end string_expression = find_child(binding, _19_)

 if string_expression then
 if (string_expression:named_child_count() > 0) then


 local tbl_21_ = {} local i_22_ = 0 for node, _0 in string_expression:iter_children() do local val_23_
 do local _20_ = node:type() if (_20_ == "interpolation") then



 local _21_ do local variable_expression
 if (nil ~= node) then

 local function _22_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end variable_expression = find_child(node, _22_) else variable_expression = nil end

 if variable_expression then

 _21_ = {["?interp"] = node, name = vim.treesitter.get_node_text(variable_expression, bufnr0)} else _21_ = nil end end local or_25_ = _21_




 if not or_25_ then local select_expression
 if (nil ~= node) then

 local function _27_(_241, _242) return ((_241:type() == "select_expression") and (_242 == "expression")) end select_expression = find_child(node, _27_) else select_expression = nil end local attrset_name


 if (nil ~= select_expression) then local tmp_3_

 local function _29_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end tmp_3_ = find_child(select_expression, _29_) if (nil ~= tmp_3_) then attrset_name = vim.treesitter.get_node_text(tmp_3_, bufnr0) else attrset_name = nil end else attrset_name = nil end local attr_name0



 if (nil ~= select_expression) then local tmp_3_

 local function _32_(_241, _242) return ((_241:type() == "attrpath") and (_242 == "attrpath")) end tmp_3_ = find_child(select_expression, _32_) if (nil ~= tmp_3_) then attr_name0 = vim.treesitter.get_node_text(tmp_3_, bufnr0) else attr_name0 = nil end else attr_name0 = nil end


 if (attrset_name and attr_name0) then

 or_25_ = {["?interp"] = node, name = attr_name0, ["?from"] = attrset_name} else or_25_ = nil end end val_23_ = or_25_ else local and_36_ = (nil ~= _20_) if and_36_ then local t = _20_ and_36_ = ((t == "string_fragment") or (t == "escape_sequence")) end if and_36_ then local t = _20_





 val_23_ = {node = node, value = vim.treesitter.get_node_text(node, bufnr0)} else val_23_ = nil end end end if (nil ~= val_23_) then i_22_ = (i_22_ + 1) tbl_21_[i_22_] = val_23_ else end end string_expr = tbl_21_ else




 local _let_40_ = coords({bufnr = bufnr0, node = string_expression}) local start_row = _let_40_["start-row"] local start_col = _let_40_["start-col"]

 local msg = string.format("Please don't leave empty strings (row %s, col %s)", (1 + start_row), (1 + start_col))




 vim.notify(msg)
 string_expr = error(msg) end else string_expr = nil end end local var_expr
 do local variable_expression
 if (nil ~= binding) then

 local function _43_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end variable_expression = find_child(binding, _43_) else variable_expression = nil end

 if variable_expression then

 var_expr = {{name = vim.treesitter.get_node_text(variable_expression, bufnr0)}} else var_expr = nil end end local attr_expr


 do local select_expression
 if (nil ~= binding) then

 local function _46_(_241, _242) return ((_241:type() == "select_expression") and (_242 == "expression")) end select_expression = find_child(binding, _46_) else select_expression = nil end local attrset_name


 if (nil ~= select_expression) then local tmp_3_

 local function _48_(_241, _242) return ((_241:type() == "variable_expression") and (_242 == "expression")) end tmp_3_ = find_child(select_expression, _48_) if (nil ~= tmp_3_) then attrset_name = vim.treesitter.get_node_text(tmp_3_, bufnr0) else attrset_name = nil end else attrset_name = nil end local attr_name0



 if (nil ~= select_expression) then local tmp_3_

 local function _51_(_241, _242) return ((_241:type() == "attrpath") and (_242 == "attrpath")) end tmp_3_ = find_child(select_expression, _51_) if (nil ~= tmp_3_) then attr_name0 = vim.treesitter.get_node_text(tmp_3_, bufnr0) else attr_name0 = nil end else attr_name0 = nil end


 if (attrset_name and attr_name0) then

 attr_expr = {{name = attr_name0, ["?from"] = attrset_name}} else attr_expr = nil end end

 local expr = (string_expr or bool_expr or var_expr or attr_expr)



 bindings[attr_name] = expr elseif (_13_ == "inherit") then


 local attrs

 local function _55_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(binding, _55_)

 for node, node_name in attrs:iter_children() do
 if ((node:type() == "identifier") and (node_name == "attr")) then


 local attr_name = vim.treesitter.get_node_text(node, bufnr0)



 bindings[attr_name] = {{name = attr_name}} else end end else end end


 return bindings end



 local function try_get_binding_value(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]
 local bounder = opts0["bounder"]
 local from = opts0["from"]
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












 local recurse_3f do local _61_ = bounder:parent():type() if (_61_ == "attrset_expression") then recurse_3f = false elseif ((_61_ == "let_expression") or (_61_ == "rec_attrset_expression")) then recurse_3f = true else recurse_3f = nil end end







 if not bounder then
 return nil else end


 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local function find_parent_bounder()


 local parent_bounder if (nil ~= bounder) then local tmp_3_ = bounder:parent() if (nil ~= tmp_3_) then parent_bounder = tmp_3_:parent() else parent_bounder = nil end else parent_bounder = nil end











 while true do local and_67_ = parent_bounder
 if and_67_ then local and_68_ = (parent_bounder:type() ~= "rec_attrset_expression") and (parent_bounder:type() ~= "let_expression")

 if and_68_ then local and_69_ = (parent_bounder:type() == "attrset_expression")
 if and_69_ then local tmp_3_ = parent_bounder:parent() if (nil ~= tmp_3_) then local tmp_3_0 = tmp_3_:type() if (nil ~= tmp_3_0) then and_69_ = (tmp_3_0 == "function_expression") else and_69_ = nil end else and_69_ = nil end end and_68_ = not and_69_ end local or_74_ = and_68_


 if not or_74_ then

 local function _75_(_241) return (_241:type() == "binding_set") end or_74_ = not find_child(parent_bounder, _75_) end and_67_ = or_74_ end if not and_67_ then break end parent_bounder = parent_bounder:parent() end



 local from0 = nil
 local only_for = nil


 local _76_ if (nil ~= parent_bounder) then local tmp_3_ = parent_bounder:type() if (nil ~= tmp_3_) then _76_ = (tmp_3_ == "attrset_expression") else _76_ = nil end else _76_ = nil end local and_80_ = _76_


 if and_80_ then if (nil ~= parent_bounder) then local tmp_3_ = parent_bounder:parent() if (nil ~= tmp_3_) then local tmp_3_0 = tmp_3_:type() if (nil ~= tmp_3_0) then and_80_ = (tmp_3_0 == "function_expression") else and_80_ = nil end else and_80_ = nil end else and_80_ = nil end end if and_80_ then local parent = parent_bounder:parent()







 local universal_parameter


 local function _86_(_241, _242) return ((_241:type() == "identifier") and (_242 == "universal")) end universal_parameter = find_child(parent, _86_)



 local formals


 local function _87_(_241, _242) return ((_241:type() == "formals") and (_242 == "formals")) end


 local function _88_(_241, _242) local and_89_ = (_241:type() == "formal") and (_242 == "formal")

 if and_89_ then local function _90_(_2410, _2420) return (_2420 == "default") end and_89_ = (find_child(_241, _90_) == nil) end return and_89_ end


 local function _91_(_241) local function _92_(_2410, _2420) return (_2420 == "name") end return find_child(_241, _92_) end
 local function _93_(_241) return vim.treesitter.get_node_text(_241, bufnr0) end formals = vim.iter(find_children(find_child(parent, _87_), _88_)):map(_91_):map(_93_):totable()

 if (universal_parameter ~= nil) then

 from0 = vim.treesitter.get_node_text(universal_parameter, bufnr0) else


 only_for = formals end else end


 if parent_bounder then



 local function _96_(_241) return (_241:type() == "binding_set") end parent_bounder = find_child(parent_bounder, _96_) else end






 return {from = from0, ["only-for"] = only_for, ["parent-bounder"] = parent_bounder} end




 local bindings = find_all_local_bindings({bufnr = bufnr0, bounder = bounder})


 local binding = bindings[identifier]
 local final_binding

 if binding then

 local find_up
 local function _99_(_98_) local fragment = _98_["v"]
 if ((_G.type(fragment) == "table") and true and (nil ~= fragment.node) and (nil ~= fragment.value)) then local _3finterp = fragment["?interp"] local node = fragment.node local value = fragment.value


 return {["?interp"] = _3finterp, node = node, value = value} elseif ((_G.type(fragment) == "table") and true and (nil ~= fragment.name) and true) then local _3finterp = fragment["?interp"] local name = fragment.name local _3ffrom = fragment["?from"]


 local _let_100_ = find_parent_bounder() local next_from = _let_100_["from"]
 local only_for = _let_100_["only-for"]
 local parent_bounder = _let_100_["parent-bounder"] local next_bounder


 if (recurse_3f or (_3ffrom and (from == _3ffrom))) then



 next_bounder = bounder elseif (only_for and not vim.tbl_contains(only_for, name)) then







 if (nil ~= parent_bounder) then local tmp_3_ = parent_bounder:parent() if (nil ~= tmp_3_) then next_bounder = tmp_3_:parent() else next_bounder = nil end else next_bounder = nil end else





 next_bounder = parent_bounder end
 if next_bounder then

 local resolved = try_get_binding_value({bufnr = bufnr0, bounder = next_bounder, from = next_from, identifier = name, depth = (depth0 + 1), ["depth-limit"] = depth_limit0})







 for _, fragment0 in ipairs(resolved) do
 if not fragment0["?interp"] then
 fragment0["?interp"] = _3finterp else end end
 return resolved else

 return {notfound = name} end elseif ((_G.type(fragment) == "table") and (nil ~= fragment.notfound)) then local notfound = fragment.notfound


 return {notfound = notfound} else return nil end end find_up = _99_


 local full_fragments = imap(find_up, binding)
 final_binding = full_fragments else



 local _let_107_ = find_parent_bounder() local parent_bounder = _let_107_["parent-bounder"] local from0 = _let_107_["from"]
 if parent_bounder then

 final_binding = try_get_binding_value({bufnr = bufnr0, bounder = parent_bounder, from = from0, identifier = identifier, depth = (depth0 + 1), ["depth-limit"] = depth_limit0}) else







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

 do local tbl_21_ = {} local i_22_ = 0 for binding, _ in node:iter_children() do local val_23_
 do local _113_ = binding:type() if (_113_ == "binding") then


 local attr

 local function _114_(_241) return (_241:type() == "attrpath") end attr = find_child(binding, _114_) local attr_name
 if attr then
 attr_name = vim.treesitter.get_node_text(attr, bufnr) else attr_name = nil end


 if (attr_name == name) then
 val_23_ = binding else val_23_ = nil end elseif (_113_ == "inherit") then


 local attrs

 local function _117_(_241, _242) return ((_241:type() == "inherited_attrs") and (_242 == "attrs")) end attrs = find_child(binding, _117_) local attr



 local function _118_(_241, _242) return ((_241:type() == "identifier") and (_242 == "attr") and (vim.treesitter.get_node_text(_241, bufnr) == name)) end attr = find_child(attrs, _118_)





 val_23_ = attr else val_23_ = nil end end if (nil ~= val_23_) then i_22_ = (i_22_ + 1) tbl_21_[i_22_] = val_23_ else end end bindings = tbl_21_ end

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

 local tbl_21_ = {} local i_22_ = 0 for _pattern, matcher, _metadata in fetches_query:iter_matches(root, bufnr0, 0, -1, {all = true}) do local val_23_








 do
 local res = {}
 for id, nodes in pairs(matcher) do
 local tbl_16_ = res for _, node in ipairs(nodes) do local k_17_, v_18_ = nil, nil
 do local capture_id = fetches_query.captures[id]


 local function _125_() if (capture_id == "_fname") then


 return vim.treesitter.get_node_text(node, bufnr0) elseif (capture_id == "_fargs") then local tbl_16_0 = {}


 for name, _0 in pairs(find_all_local_bindings({bufnr = bufnr0, bounder = node})) do local k_17_0, v_18_0 = nil, nil



 do local binding = try_get_binding_bounder({bufnr = bufnr0, node = node, name = name})



 local fragments = try_get_binding_value({bufnr = bufnr0, bounder = node, identifier = name})



 k_17_0, v_18_0 = name, {binding = binding, fragments = fragments} end if ((k_17_0 ~= nil) and (v_18_0 ~= nil)) then tbl_16_0[k_17_0] = v_18_0 else end end return tbl_16_0 elseif (capture_id == "_fwhole") then




 return node else return nil end end k_17_, v_18_ = capture_id, _125_() end if ((k_17_ ~= nil) and (v_18_ ~= nil)) then tbl_16_[k_17_] = v_18_ else end end end
 val_23_ = res end if (nil ~= val_23_) then i_22_ = (i_22_ + 1) tbl_21_[i_22_] = val_23_ else end end found_fetches = tbl_21_ end


 return found_fetches end

 local function get_fetch_at_cursor(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches({bufnr = bufnr0})


 local _local_128_ = vim.fn.getcursorcharpos() local _ = _local_128_[1] local cursor_row = _local_128_[2] local cursor_col = _local_128_[3] local _0 = _local_128_[4] local _1 = _local_128_[5]


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
 local existing do local t_130_ = fetch if (nil ~= t_130_) then t_130_ = t_130_._fargs else end if (nil ~= t_130_) then t_130_ = t_130_[key] else end if (nil ~= t_130_) then t_130_ = t_130_.fragments else end existing = t_130_ end
 if existing then local i_fragment = 1 local i_new_value = 1 local short_circuit_3f = false





 while (not short_circuit_3f and (i_new_value <= #new_value)) do

 local fragment = existing[i_fragment]
 local fragment_node = fragment["node"]
 local fragment_value = fragment["value"]
 local fragment__3finterp = fragment["?interp"]
 if false then elseif (string.sub(new_value, i_new_value, (i_new_value + #fragment_value + -1)) == fragment_value) then











 i_fragment = (i_fragment + 1)
 i_new_value = (i_new_value + #fragment_value) elseif (i_fragment == #existing) then



 local _local_134_ = coords({bufnr = bufnr, node = fragment_node}) local start_row = _local_134_["start-row"] local start_col = _local_134_["start-col"] local end_row = _local_134_["end-row"] local end_col = _local_134_["end-col"]

 table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}}) short_circuit_3f = true else














 local last_fragment = existing[#existing]
 local last_fragment__3finterp = last_fragment["?interp"]
 local last_fragment_node = last_fragment["node"]

 local _local_135_ = coords({bufnr = bufnr, node = (fragment__3finterp or fragment_node)}) local start_row = _local_135_["start-row"] local start_col = _local_135_["start-col"]



 local _local_136_ = coords({bufnr = bufnr, node = (last_fragment__3finterp or last_fragment_node)}) local end_row = _local_136_["end-row"] local end_col = _local_136_["end-col"]



 table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}}) short_circuit_3f = true end end else










 local _let_138_ = coords({bufnr = bufnr, node = fetch._fwhole}) local end_row = _let_138_["end-row"] local end_col = _let_138_["end-col"]
 table.insert(updates, {type = "new", data = {bufnr = bufnr, start = end_row, ["end"] = end_row, replacement = {string.format("%s%s = \"%s\";", vim.fn["repeat"](" ", ((end_col - 1) + vim.bo[bufnr].shiftwidth)), key, new_value)}}}) end end
















 return updates end


 local function preview_update(update)

 local namespace = vim.api.nvim_create_namespace("NixUpdate")

 if ((_G.type(update) == "table") and (update.type == "old") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data["start-row"]) and (nil ~= update.data["start-col"]) and (nil ~= update.data["end-row"]) and (nil ~= update.data["end-col"]) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start_row = update.data["start-row"] local start_col = update.data["start-col"] local end_row = update.data["end-row"] local end_col = update.data["end-col"] local replacement = update.data.replacement
















 local _140_ do local tbl_21_ = {} local i_22_ = 0 for _, line in ipairs(replacement) do
 local val_23_ = {line, "DiffAdd"} if (nil ~= val_23_) then i_22_ = (i_22_ + 1) tbl_21_[i_22_] = val_23_ else end end _140_ = tbl_21_ end return vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, start_col, {end_row = end_row, end_col = end_col, hl_mode = "replace", virt_text = _140_, virt_text_pos = "overlay"}) elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start = update.data.start local replacement = update.data.replacement











 local _142_ do local tbl_21_ = {} local i_22_ = 0 for _, line in ipairs(replacement) do
 local val_23_ = {{line, "DiffAdd"}} if (nil ~= val_23_) then i_22_ = (i_22_ + 1) tbl_21_[i_22_] = val_23_ else end end _142_ = tbl_21_ end return vim.api.nvim_buf_set_extmark(bufnr, namespace, start, 0, {virt_lines = _142_, virt_lines_above = true}) else return nil end end



 local function apply_update(update)
 if ((_G.type(update) == "table") and (update.type == "old") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data["start-row"]) and (nil ~= update.data["start-col"]) and (nil ~= update.data["end-row"]) and (nil ~= update.data["end-col"]) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start_row = update.data["start-row"] local start_col = update.data["start-col"] local end_row = update.data["end-row"] local end_col = update.data["end-col"] local replacement = update.data.replacement







 return vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, replacement) elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data["end"]) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start = update.data.start local _end = update.data["end"] local replacement = update.data.replacement











 return vim.api.nvim_buf_set_lines(bufnr, start, _end, true, replacement) else return nil end end







 local function notify_update(update)
 if ((_G.type(update) == "table") and (update.type == "old") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data["start-row"]) and (nil ~= update.data["start-col"]) and (nil ~= update.data["end-row"]) and (nil ~= update.data["end-col"]) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start_row = update.data["start-row"] local start_col = update.data["start-col"] local end_row = update.data["end-row"] local end_col = update.data["end-col"] local replacement = update.data.replacement







 return vim.notify(string.format("Replaced text from (%d, %d) to (%d, %d) in buffer %d with %s", start_row, start_col, end_row, end_col, bufnr, vim.inspect(replacement))) elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data["end"]) and (nil ~= update.data.replacement))) then local bufnr = update.data.bufnr local start = update.data.start local _end = update.data["end"] local replacement = update.data.replacement













 return vim.notify(string.format("Inserted text at (%d, %d) to (%d, %d) in buffer %d with %s", __fnl_global__start_2drow, __fnl_global__start_2dcol, __fnl_global__end_2drow, __fnl_global__end_2dcol, bufnr, vim.inspect(replacement))) else return nil end end











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

 local _149_ do local t_148_ = config if (nil ~= t_148_) then t_148_ = t_148_["extra-prefetchers"] else end if (nil ~= t_148_) then t_148_ = t_148_[fetch0._fname] else end _149_ = t_148_ end local or_152_ = _149_
 if not or_152_ then local t_153_ = prefetchers if (nil ~= t_153_) then t_153_ = t_153_[fetch0._fname] else end or_152_ = t_153_ end prefetcher = or_152_


 if not prefetcher then
 vim.notify(string.format("No prefetcher '%s' found", fetch0._fname))



 return nil else end


 local argument_values
 do
 local argument_values0 = {}
 local notfounds_pairs = {}


 for farg_name, farg_binding in pairs(fetch0._fargs) do



 local function _156_(result)
 argument_values0[farg_name] = result return nil end

 local function _157_(notfounds)
 return table.insert(notfounds_pairs, {["farg-name"] = farg_name, notfounds = notfounds}) end Result.bimap(fragments_to_value(farg_binding.fragments), _156_, _157_) end



 for _, _158_ in ipairs(notfounds_pairs) do local farg_name = _158_["farg-name"] local notfounds = _158_["notfounds"]
 vim.notify(string.format("Identifiers %s not found while evaluating %s!", vim.inspect(notfounds), farg_name)) end






 if (#notfounds_pairs > 0) then
 return nil else end


 argument_values = argument_values0 end



 local prefetcher_cmd = prefetcher(argument_values)


 if not prefetcher_cmd then
 vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch0._fname))



 return nil else end




 local function _162_(_161_) local stdout = _161_["stdout"] local stderr = _161_["stderr"]
 if (#stdout == 0) then
 cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, err = string.format("Oopsie: %s", vim.inspect(stderr))}








 return nil else end

 cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, data = prefetcher.extractor(stdout)} return nil end call_command(prefetcher_cmd, _162_)







 return vim.notify(string.format("Prefetch initiated, awaiting response...")) end



 return {["fetches-query-string"] = fetches_query_string, ["gen-fetches-names"] = gen_fetches_names, ["gen-fetches-query"] = gen_fetches_query, ["get-root"] = get_root, ["find-all-local-bindings"] = find_all_local_bindings, ["try-get-binding-value"] = try_get_binding_value, ["fragments-to-value"] = fragments_to_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["calculate-updates"] = calculate_updates, ["preview-update"] = preview_update, ["apply-update"] = apply_update, ["notify-update"] = notify_update, ["prefetch-fetch"] = prefetch_fetch}
