 local fetchers = require("nix-update.fetchers") local fetchers_query_string = "\n(\n  (apply_expression\n    function:\n      [(variable_expression\n         name: (identifier) @_fname)\n       (select_expression\n         attrpath:\n           (attrpath\n             attr: (identifier) @_fname\n             .))]\n    argument:\n      (attrset_expression\n        (binding_set) @_fargs)\n  )\n  (#any-of? @_fname %s)\n)\n       "























 local fetchers_names

 local _1_ do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for fetcher, _ in pairs(fetchers) do
 local val_19_auto = string.format("\"%s\"", fetcher) if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end _1_ = tbl_17_auto end fetchers_names = table.concat(_1_, " ")




 local fetchers_query = vim.treesitter.parse_query("nix", string.format(fetchers_query_string, fetchers_names))





 local function get_root(bufnr)
 local parser = vim.treesitter.get_parser(bufnr, "nix", {})
 local _let_3_ = parser:parse() local tree = _let_3_[1] return tree:root() end



 local function get_used_fetchers(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 if (vim.bo[bufnr0].filetype ~= "nix") then

 vim.notify("This is meant to be used with Nix files")
 return else end


 local root = get_root(bufnr0)


 local called_fetchers
 do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for _pattern, matcher, _metadata in fetchers_query:iter_matches(root, bufnr0, 0, -1) do local val_19_auto

 do local tbl_14_auto = {} for id, node in pairs(matcher) do local k_15_auto, v_16_auto = nil, nil



 local function _6_() local _5_ = fetchers_query.captures[id] if (_5_ == "_fname") then


 local _7_ do
 local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, bufnr0)
 _7_ = {["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col} end return {name = vim.treesitter.get_node_text(node, bufnr0), range = _7_} elseif (_5_ == "_fargs") then local tbl_14_auto0 = {}




 for binding_node, _ in node:iter_children() do local k_15_auto0, v_16_auto0 = nil, nil
 do local _8_ do local tbl_17_auto0 = {} local i_18_auto0 = #tbl_17_auto0 for binding, _0 in binding_node:iter_children() do local val_19_auto0
 do local _9_ = binding:type() if (_9_ == "attrpath") then

 val_19_auto0 = vim.treesitter.get_node_text(binding, bufnr0) elseif (_9_ == "string_expression") then local tbl_17_auto1 = {}

 local i_18_auto1 = #tbl_17_auto1 for binding_part, _1 in binding:iter_children() do local val_19_auto1
 if binding_part:named() then
 val_19_auto1 = {node = binding_part, value = vim.treesitter.get_node_text(binding_part, bufnr0)} else val_19_auto1 = nil end if (nil ~= val_19_auto1) then i_18_auto1 = (i_18_auto1 + 1) do end (tbl_17_auto1)[i_18_auto1] = val_19_auto1 else end end val_19_auto0 = tbl_17_auto1 else val_19_auto0 = nil end end if (nil ~= val_19_auto0) then i_18_auto0 = (i_18_auto0 + 1) do end (tbl_17_auto0)[i_18_auto0] = val_19_auto0 else end end _8_ = tbl_17_auto0 end if ((_G.type(_8_) == "table") and (nil ~= (_8_)[1]) and ((_G.type((_8_)[2]) == "table") and (nil ~= ((_8_)[2])[1]))) then local attr = (_8_)[1] local val = ((_8_)[2])[1]

 k_15_auto0, v_16_auto0 = attr, val else k_15_auto0, v_16_auto0 = nil end end if ((k_15_auto0 ~= nil) and (v_16_auto0 ~= nil)) then tbl_14_auto0[k_15_auto0] = v_16_auto0 else end end return tbl_14_auto0 else return nil end end k_15_auto, v_16_auto = fetchers_query.captures[id], _6_() if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end val_19_auto = tbl_14_auto end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end called_fetchers = tbl_17_auto end

 return called_fetchers end

 local function nix_update(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local used_fetchers = get_used_fetchers(bufnr0)


 local namespace = vim.api.nvim_create_namespace("NixUpdate")


 vim.api.nvim_buf_clear_namespace(bufnr0, namespace, 0, -1)

 return used_fetchers end


 local function _19_() return nix_update() end vim.api.nvim_create_user_command("NixUpdate", _19_, {})

 return {get_used_fetchers = get_used_fetchers, nix_update = nix_update}