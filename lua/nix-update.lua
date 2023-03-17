 local updaters = require("nix-update.updaters") local fetchers_query_string = "\n(\n  (apply_expression\n    function:\n      [(variable_expression\n         name: (identifier) @_fname)\n       (select_expression\n         attrpath:\n           (attrpath\n             attr: (identifier) @_fname\n             .))]\n    argument:\n      (attrset_expression\n        (binding_set) @_fargs)\n  ) @_fwhole\n  (#any-of? @_fname %s)\n)\n       "























 local fetchers_names

 local _1_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for fetcher, _ in pairs(updaters) do
 local val_19_auto = string.format("\"%s\"", fetcher) if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _1_ = tbl_17_auto end fetchers_names = table.concat(_1_, " ")




 local fetchers_query = vim.treesitter.parse_query("nix", string.format(fetchers_query_string, fetchers_names))





 local function get_root(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local parser = vim.treesitter.get_parser(bufnr0, "nix", {})
 local _let_4_ = parser:parse() local tree = _let_4_[1] return tree:root() end



 local function try_get_value(bufnr, attrset, name)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end

 local bindings

 do local tbl_14_auto = {} for binding, _ in attrset:iter_children() do local k_15_auto, v_16_auto = nil, nil
 do local _6_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for binding_elem, _0 in binding:iter_children() do local val_19_auto
 do local _7_ = binding_elem:type() if (_7_ == "attrpath") then


 val_19_auto = vim.treesitter.get_node_text(binding_elem, bufnr0) elseif (_7_ == "string_expression") then local tbl_17_auto0 = {}




 local i_18_auto0 = #tbl_17_auto0 for binding_part, _1 in binding_elem:iter_children() do local val_19_auto0
 if binding_part:named() then
 val_19_auto0 = {node = binding_part, value = vim.treesitter.get_node_text(binding_part, bufnr0)} else val_19_auto0 = nil end if (nil ~= val_19_auto0) then i_18_auto0 = (i_18_auto0 + 1) do end (tbl_17_auto0)[i_18_auto0] = val_19_auto0 else end end val_19_auto = tbl_17_auto0 elseif (_7_ == "variable_expression") then





 val_19_auto = {vim.treesitter.get_node_text(binding_elem, bufnr0)} else val_19_auto = nil end end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _6_ = tbl_17_auto end if ((_G.type(_6_) == "table") and (nil ~= (_6_)[1]) and ((_G.type((_6_)[2]) == "table") and (nil ~= ((_6_)[2])[1]))) then local attr = (_6_)[1] local val = ((_6_)[2])[1]


 k_15_auto, v_16_auto = attr, val else k_15_auto, v_16_auto = nil end end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end bindings = tbl_14_auto end

 local binding = bindings[name]
 local _14_ = type(binding) if (_14_ == "table") then


 return binding elseif (nil ~= _14_) then local other = _14_ local target = attrset:parent()





 while ((target ~= nil) and (target:type() ~= "binding_set")) do target = target:parent() end




 if (target ~= nil) then
 local _15_ = other if (_15_ == "string") then


 return try_get_value(bufnr0, target, binding) elseif (_15_ == "nil") then


 return try_get_value(bufnr0, target, name) else return nil end else return nil end else return nil end end


 local function find_used_fetchers(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify_once("This is meant to be used with Nix files")
 return nil else end


 local root = get_root(bufnr0)


 local found_fetchers

 do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _pattern, matcher, _metadata in fetchers_query:iter_matches(root, bufnr0, 0, -1) do local val_19_auto


 do local tbl_14_auto = {} for id, node in pairs(matcher) do local k_15_auto, v_16_auto = nil, nil



 local function _21_() local _20_ = fetchers_query.captures[id] if (_20_ == "_fname") then


 return vim.treesitter.get_node_text(node, bufnr0) elseif (_20_ == "_fargs") then local tbl_14_auto0 = {}









 for binding, _ in node:iter_children() do local k_15_auto0, v_16_auto0 = nil, nil
 do local _22_ do local tbl_17_auto0 = {} local i_18_auto0 = #tbl_17_auto0 for binding_elem, _0 in binding:iter_children() do local val_19_auto0
 do local _23_ = binding_elem:type() if (_23_ == "attrpath") then


 val_19_auto0 = vim.treesitter.get_node_text(binding_elem, bufnr0) else val_19_auto0 = nil end end if (nil ~= val_19_auto0) then i_18_auto0 = (i_18_auto0 + 1) do end (tbl_17_auto0)[i_18_auto0] = val_19_auto0 else end end _22_ = tbl_17_auto0 end if ((_G.type(_22_) == "table") and (nil ~= (_22_)[1])) then local attr = (_22_)[1]
 k_15_auto0, v_16_auto0 = attr, try_get_value(bufnr0, node, attr) else k_15_auto0, v_16_auto0 = nil end end if ((k_15_auto0 ~= nil) and (v_16_auto0 ~= nil)) then tbl_14_auto0[k_15_auto0] = v_16_auto0 else end end return tbl_14_auto0 elseif (_20_ == "_fwhole") then



 return node else return nil end end k_15_auto, v_16_auto = fetchers_query.captures[id], _21_() if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end val_19_auto = tbl_14_auto end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end found_fetchers = tbl_17_auto end

 return found_fetchers end

 local function get_fetcher_at_cursor(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetchers = find_used_fetchers(bufnr0)


 local _local_31_ = vim.fn.getcursorcharpos() local _ = _local_31_[1] local cursor_row = _local_31_[2] local cursor_col = _local_31_[3] local _0 = _local_31_[4] local _1 = _local_31_[5]


 for _2, fetcher in ipairs(found_fetchers) do
 if vim.treesitter.is_in_node_range(fetcher._fwhole, cursor_row, cursor_col) then



 return fetcher else end end return nil end

 local function update_fetcher_at_cursor(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local fetcher_at_cursor = get_fetcher_at_cursor(bufnr0)


 if (fetcher_at_cursor == nil) then
 return nil else end



 local updater = updaters[fetcher_at_cursor._fname]

 return updater(fetcher_at_cursor._fargs) end

 local function nix_update(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetchers = find_used_fetchers(bufnr0)


 local namespace = vim.api.nvim_create_namespace("NixUpdate")


 vim.api.nvim_buf_clear_namespace(bufnr0, namespace, 0, -1)

 return found_fetchers end


 local function _34_() return nix_update() end vim.api.nvim_create_user_command("NixUpdate", _34_, {})

 return {get_used_fetchers = find_used_fetchers, get_fetcher_at_cursor = get_fetcher_at_cursor, update_fetcher_at_cursor = update_fetcher_at_cursor, nix_update = nix_update}