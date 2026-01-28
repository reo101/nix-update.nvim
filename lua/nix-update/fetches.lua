local _local_1_ = require("nix-update.prefetchers")
local prefetchers = _local_1_.prefetchers
local _local_2_ = require("nix-update._cache")
local cache = _local_2_.cache
local _local_3_ = require("nix-update._config")
local config = _local_3_.config
local _local_4_ = require("nix-update.utils.fp")
local Result = _local_4_.Result
local _local_5_ = require("nix-update.utils")
local find_child = _local_5_["find-child"]
local find_children = _local_5_["find-children"]
local coords = _local_5_.coords
local flatten_fragments = _local_5_["flatten-fragments"]
local call_command = _local_5_["call-command"]
local fetches_query_string = "\n(\n  (apply_expression\n    function:\n      [(variable_expression\n         name: (identifier) @_fname)\n       (select_expression\n         attrpath:\n           (attrpath\n             attr: (identifier) @_fname\n             .))]\n    argument:\n      [(attrset_expression\n         (binding_set) @_fargs)\n       (rec_attrset_expression\n         (binding_set) @_fargs)]\n  ) @_fwhole\n  (#any-of? @_fname %s)\n)\n       "
local function gen_fetches_names()
  local names
  local function _6_(k, _)
    return k
  end
  names = vim.iter(pairs(prefetchers)):map(_6_):totable()
  local _8_
  do
    local t_7_ = config
    if (nil ~= t_7_) then
      t_7_ = t_7_["extra-prefetchers"]
    else
    end
    _8_ = t_7_
  end
  local function _10_(k, _)
    return k
  end
  vim.list_extend(names, vim.iter(pairs((_8_ or {}))):map(_10_):totable())
  return table.concat(names, " ")
end
local function gen_fetches_query()
  return vim.treesitter.query.parse("nix", string.format(fetches_query_string, gen_fetches_names()))
end
local function get_root(opts)
  local opts0 = (opts or {})
  local bufnr = opts0.bufnr
  local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())
  if (vim.bo[bufnr0].filetype ~= "nix") then
    vim.notify_once("This is meant to be used with Nix files")
    return nil
  else
  end
  local parser = vim.treesitter.get_parser(bufnr0, "nix", {})
  local _let_12_ = parser:parse()
  local tree = _let_12_[1]
  return tree:root()
end
local function find_all_local_bindings(opts)
  local opts0 = (opts or {})
  local bufnr = opts0.bufnr
  local bounder = opts0.bounder
  local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())
  if not bounder then
    vim.notify("No bounder")
    return nil
  else
  end
  if (vim.bo[bufnr0].filetype ~= "nix") then
    vim.notify_once("This is meant to be used with Nix files")
    return nil
  else
  end
  local bindings = {}
  for binding, _ in bounder:iter_children() do
    local case_15_ = binding:type()
    if (case_15_ == "binding") then
      local attr
      local function _16_(_241, _242)
        return ((_241:type() == "attrpath") and (_242 == "attrpath"))
      end
      attr = find_child(binding, _16_)
      local attr_name
      if attr then
        attr_name = vim.treesitter.get_node_text(attr, bufnr0)
      else
        attr_name = nil
      end
      local bool_expr
      do
        local bool_expr0
        local function _18_(_241, _242)
          return ((_241:type() == "variable_expression") and (_242 == "expression"))
        end
        bool_expr0 = find_child(binding, _18_)
        if bool_expr0 then
          local bool_expr_value = vim.treesitter.get_node_text(bool_expr0, bufnr0)
          if vim.list_contains({"true", "false"}, bool_expr_value) then
            bool_expr = {{node = bool_expr0, value = bool_expr_value}}
          else
            bool_expr = nil
          end
        else
          bool_expr = nil
        end
      end
      local string_expr
      do
        local string_expression
        local function _21_(_241, _242)
          return ((_241:type() == "string_expression") and (_242 == "expression"))
        end
        string_expression = find_child(binding, _21_)
        if string_expression then
          if (string_expression:named_child_count() > 0) then
            local tbl_26_ = {}
            local i_27_ = 0
            for node, _0 in string_expression:iter_children() do
              local val_28_
              do
                local case_22_ = node:type()
                if (case_22_ == "interpolation") then
                  local _23_
                  do
                    local variable_expression
                    if (nil ~= node) then
                      local function _24_(_241, _242)
                        return ((_241:type() == "variable_expression") and (_242 == "expression"))
                      end
                      variable_expression = find_child(node, _24_)
                    else
                      variable_expression = nil
                    end
                    if variable_expression then
                      _23_ = {["?interp"] = node, name = vim.treesitter.get_node_text(variable_expression, bufnr0)}
                    else
                      _23_ = nil
                    end
                  end
                  local or_27_ = _23_
                  if not or_27_ then
                    local select_expression
                    if (nil ~= node) then
                      local function _29_(_241, _242)
                        return ((_241:type() == "select_expression") and (_242 == "expression"))
                      end
                      select_expression = find_child(node, _29_)
                    else
                      select_expression = nil
                    end
                    local attrset_name
                    if (nil ~= select_expression) then
                      local tmp_3_
                      local function _31_(_241, _242)
                        return ((_241:type() == "variable_expression") and (_242 == "expression"))
                      end
                      tmp_3_ = find_child(select_expression, _31_)
                      if (nil ~= tmp_3_) then
                        attrset_name = vim.treesitter.get_node_text(tmp_3_, bufnr0)
                      else
                        attrset_name = nil
                      end
                    else
                      attrset_name = nil
                    end
                    local attr_name0
                    if (nil ~= select_expression) then
                      local tmp_3_
                      local function _34_(_241, _242)
                        return ((_241:type() == "attrpath") and (_242 == "attrpath"))
                      end
                      tmp_3_ = find_child(select_expression, _34_)
                      if (nil ~= tmp_3_) then
                        attr_name0 = vim.treesitter.get_node_text(tmp_3_, bufnr0)
                      else
                        attr_name0 = nil
                      end
                    else
                      attr_name0 = nil
                    end
                    if (attrset_name and attr_name0) then
                      or_27_ = {["?interp"] = node, name = attr_name0, ["?from"] = attrset_name}
                    else
                      or_27_ = nil
                    end
                  end
                  val_28_ = or_27_
                else
                  local and_38_ = (nil ~= case_22_)
                  if and_38_ then
                    local t = case_22_
                    and_38_ = ((t == "string_fragment") or (t == "escape_sequence"))
                  end
                  if and_38_ then
                    local t = case_22_
                    val_28_ = {node = node, value = vim.treesitter.get_node_text(node, bufnr0)}
                  else
                    val_28_ = nil
                  end
                end
              end
              if (nil ~= val_28_) then
                i_27_ = (i_27_ + 1)
                tbl_26_[i_27_] = val_28_
              else
              end
            end
            string_expr = tbl_26_
          else
            local _let_42_ = coords({bufnr = bufnr0, node = string_expression})
            local start_row = _let_42_["start-row"]
            local start_col = _let_42_["start-col"]
            local msg = string.format("Please don't leave empty strings (row %s, col %s)", (1 + start_row), (1 + start_col))
            vim.notify(msg)
            string_expr = error(msg)
          end
        else
          string_expr = nil
        end
      end
      local var_expr
      do
        local variable_expression
        if (nil ~= binding) then
          local function _45_(_241, _242)
            return ((_241:type() == "variable_expression") and (_242 == "expression"))
          end
          variable_expression = find_child(binding, _45_)
        else
          variable_expression = nil
        end
        if variable_expression then
          var_expr = {{name = vim.treesitter.get_node_text(variable_expression, bufnr0)}}
        else
          var_expr = nil
        end
      end
      local attr_expr
      do
        local select_expression
        if (nil ~= binding) then
          local function _48_(_241, _242)
            return ((_241:type() == "select_expression") and (_242 == "expression"))
          end
          select_expression = find_child(binding, _48_)
        else
          select_expression = nil
        end
        local attrset_name
        if (nil ~= select_expression) then
          local tmp_3_
          local function _50_(_241, _242)
            return ((_241:type() == "variable_expression") and (_242 == "expression"))
          end
          tmp_3_ = find_child(select_expression, _50_)
          if (nil ~= tmp_3_) then
            attrset_name = vim.treesitter.get_node_text(tmp_3_, bufnr0)
          else
            attrset_name = nil
          end
        else
          attrset_name = nil
        end
        local attr_name0
        if (nil ~= select_expression) then
          local tmp_3_
          local function _53_(_241, _242)
            return ((_241:type() == "attrpath") and (_242 == "attrpath"))
          end
          tmp_3_ = find_child(select_expression, _53_)
          if (nil ~= tmp_3_) then
            attr_name0 = vim.treesitter.get_node_text(tmp_3_, bufnr0)
          else
            attr_name0 = nil
          end
        else
          attr_name0 = nil
        end
        if (attrset_name and attr_name0) then
          attr_expr = {{name = attr_name0, ["?from"] = attrset_name}}
        else
          attr_expr = nil
        end
      end
      local expr = (string_expr or bool_expr or var_expr or attr_expr)
      bindings[attr_name] = expr
    elseif (case_15_ == "inherit") then
      local attrs
      local function _57_(_241, _242)
        return ((_241:type() == "inherited_attrs") and (_242 == "attrs"))
      end
      attrs = find_child(binding, _57_)
      for node, node_name in attrs:iter_children() do
        if ((node:type() == "identifier") and (node_name == "attr")) then
          local attr_name = vim.treesitter.get_node_text(node, bufnr0)
          bindings[attr_name] = {{name = attr_name}}
        else
        end
      end
    else
    end
  end
  return bindings
end
local function try_get_binding_value(opts)
  local opts0 = (opts or {})
  local bufnr = opts0.bufnr
  local bounder = opts0.bounder
  local from = opts0.from
  local identifier = opts0.identifier
  local depth = opts0.depth
  local depth_limit = opts0["depth-limit"]
  local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())
  if not bounder then
    vim.notify("No bounder")
    return nil
  else
  end
  if not identifier then
    vim.notify("No identifier")
    return nil
  else
  end
  local depth0 = (depth or 0)
  local depth_limit0 = (depth_limit or 16)
  if (depth0 > depth_limit0) then
    vim.notify(string.format("Hit the depth-limit of %s!", depth_limit0))
    return nil
  else
  end
  local recurse_3f
  do
    local case_63_ = bounder:parent():type()
    if (case_63_ == "attrset_expression") then
      recurse_3f = false
    elseif ((case_63_ == "let_expression") or (case_63_ == "rec_attrset_expression")) then
      recurse_3f = true
    else
      recurse_3f = nil
    end
  end
  if not bounder then
    return nil
  else
  end
  if (vim.bo[bufnr0].filetype ~= "nix") then
    vim.notify_once("This is meant to be used with Nix files")
    return nil
  else
  end
  local function find_parent_bounder()
    local parent_bounder
    if (nil ~= bounder) then
      local tmp_3_ = bounder:parent()
      if (nil ~= tmp_3_) then
        parent_bounder = tmp_3_:parent()
      else
        parent_bounder = nil
      end
    else
      parent_bounder = nil
    end
    while true do
      local and_69_ = parent_bounder
      if and_69_ then
        local and_70_ = (parent_bounder:type() ~= "rec_attrset_expression") and (parent_bounder:type() ~= "let_expression")
        if and_70_ then
          local and_71_ = (parent_bounder:type() == "attrset_expression")
          if and_71_ then
            local tmp_3_ = parent_bounder:parent()
            if (nil ~= tmp_3_) then
              local tmp_3_0 = tmp_3_:type()
              if (nil ~= tmp_3_0) then
                and_71_ = (tmp_3_0 == "function_expression")
              else
                and_71_ = nil
              end
            else
              and_71_ = nil
            end
          end
          and_70_ = not and_71_
        end
        local or_76_ = and_70_
        if not or_76_ then
          local function _77_(_241)
            return (_241:type() == "binding_set")
          end
          or_76_ = not find_child(parent_bounder, _77_)
        end
        and_69_ = or_76_
      end
      if not and_69_ then break end
      parent_bounder = parent_bounder:parent()
    end
    local from0 = nil
    local only_for = nil
    local _78_
    if (nil ~= parent_bounder) then
      local tmp_3_ = parent_bounder:type()
      if (nil ~= tmp_3_) then
        _78_ = (tmp_3_ == "attrset_expression")
      else
        _78_ = nil
      end
    else
      _78_ = nil
    end
    local and_82_ = _78_
    if and_82_ then
      if (nil ~= parent_bounder) then
        local tmp_3_ = parent_bounder:parent()
        if (nil ~= tmp_3_) then
          local tmp_3_0 = tmp_3_:type()
          if (nil ~= tmp_3_0) then
            and_82_ = (tmp_3_0 == "function_expression")
          else
            and_82_ = nil
          end
        else
          and_82_ = nil
        end
      else
        and_82_ = nil
      end
    end
    if and_82_ then
      local parent = parent_bounder:parent()
      local universal_parameter
      local function _88_(_241, _242)
        return ((_241:type() == "identifier") and (_242 == "universal"))
      end
      universal_parameter = find_child(parent, _88_)
      local formals
      local _89_
      if (nil ~= parent) then
        local tmp_3_
        local function _91_(_241, _242)
          return ((_241:type() == "formals") and (_242 == "formals"))
        end
        tmp_3_ = find_child(parent, _91_)
        if (nil ~= tmp_3_) then
          local tmp_3_0
          local function _93_(_241, _242)
            local and_94_ = (_241:type() == "formal") and (_242 == "formal")
            if and_94_ then
              local function _95_(_2410, _2420)
                return (_2420 == "default")
              end
              and_94_ = (find_child(_241, _95_) == nil)
            end
            return and_94_
          end
          tmp_3_0 = find_children(tmp_3_, _93_)
          if (nil ~= tmp_3_0) then
            local tmp_3_1 = vim.iter(tmp_3_0)
            if (nil ~= tmp_3_1) then
              local tmp_3_2
              local function _98_(_241)
                local function _99_(_2410, _2420)
                  return (_2420 == "name")
                end
                return find_child(_241, _99_)
              end
              tmp_3_2 = tmp_3_1:map(_98_)
              if (nil ~= tmp_3_2) then
                local tmp_3_3
                local function _101_(_241)
                  return vim.treesitter.get_node_text(_241, bufnr0)
                end
                tmp_3_3 = tmp_3_2:map(_101_)
                if (nil ~= tmp_3_3) then
                  _89_ = tmp_3_3:totable()
                else
                  _89_ = nil
                end
              else
                _89_ = nil
              end
            else
              _89_ = nil
            end
          else
            _89_ = nil
          end
        else
          _89_ = nil
        end
      else
        _89_ = nil
      end
      formals = (_89_ or {})
      if (universal_parameter ~= nil) then
        from0 = vim.treesitter.get_node_text(universal_parameter, bufnr0)
      else
        only_for = formals
      end
    else
    end
    if parent_bounder then
      local function _110_(_241)
        return (_241:type() == "binding_set")
      end
      parent_bounder = find_child(parent_bounder, _110_)
    else
    end
    return {from = from0, ["only-for"] = only_for, ["parent-bounder"] = parent_bounder}
  end
  local bindings = find_all_local_bindings({bufnr = bufnr0, bounder = bounder})
  local binding = bindings[identifier]
  local final_binding
  if binding then
    local find_up
    local function _113_(_112_)
      local fragment = _112_.v
      if ((_G.type(fragment) == "table") and true and (nil ~= fragment.node) and (nil ~= fragment.value)) then
        local _3finterp = fragment["?interp"]
        local node = fragment.node
        local value = fragment.value
        return {["?interp"] = _3finterp, node = node, value = value}
      elseif ((_G.type(fragment) == "table") and true and (nil ~= fragment.name) and true) then
        local _3finterp = fragment["?interp"]
        local name = fragment.name
        local _3ffrom = fragment["?from"]
        local _let_114_ = find_parent_bounder()
        local next_from = _let_114_.from
        local only_for = _let_114_["only-for"]
        local parent_bounder = _let_114_["parent-bounder"]
        local next_bounder
        if (recurse_3f or (_3ffrom and (from == _3ffrom))) then
          next_bounder = bounder
        elseif (only_for and not vim.tbl_contains(only_for, name)) then
          if (nil ~= parent_bounder) then
            local tmp_3_ = parent_bounder:parent()
            if (nil ~= tmp_3_) then
              next_bounder = tmp_3_:parent()
            else
              next_bounder = nil
            end
          else
            next_bounder = nil
          end
        else
          next_bounder = parent_bounder
        end
        if next_bounder then
          local resolved = try_get_binding_value({bufnr = bufnr0, bounder = next_bounder, from = next_from, identifier = name, depth = (depth0 + 1), ["depth-limit"] = depth_limit0})
          for _, fragment0 in ipairs(resolved) do
            if not fragment0["?interp"] then
              fragment0["?interp"] = _3finterp
            else
            end
          end
          return resolved
        else
          return {{notfound = name}}
        end
      elseif ((_G.type(fragment) == "table") and (nil ~= fragment.notfound)) then
        local notfound = fragment.notfound
        return {{notfound = notfound}}
      else
        return nil
      end
    end
    find_up = _113_
    local full_fragments
    local function _121_(k, v)
      return find_up({k = k, v = v})
    end
    full_fragments = vim.iter(ipairs(binding)):map(_121_):totable()
    final_binding = full_fragments
  else
    local _let_122_ = find_parent_bounder()
    local parent_bounder = _let_122_["parent-bounder"]
    local from0 = _let_122_.from
    if parent_bounder then
      final_binding = try_get_binding_value({bufnr = bufnr0, bounder = parent_bounder, from = from0, identifier = identifier, depth = (depth0 + 1), ["depth-limit"] = depth_limit0})
    else
      final_binding = {{notfound = identifier}}
    end
  end
  return flatten_fragments(final_binding)
end
local function try_get_binding_bounder(opts)
  local opts0 = (opts or {})
  local bufnr = opts0.bufnr
  local node = opts0.node
  local name = opts0.name
  if not bufnr then
    vim.notify("No bufnr")
    return nil
  else
  end
  if not node then
    vim.notify("No node")
    return nil
  else
  end
  if not name then
    vim.notify("No name")
    return nil
  else
  end
  local bindings
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for binding, _ in node:iter_children() do
      local val_28_
      do
        local case_128_ = binding:type()
        if (case_128_ == "binding") then
          local attr
          local function _129_(_241)
            return (_241:type() == "attrpath")
          end
          attr = find_child(binding, _129_)
          local attr_name
          if attr then
            attr_name = vim.treesitter.get_node_text(attr, bufnr)
          else
            attr_name = nil
          end
          if (attr_name == name) then
            val_28_ = binding
          else
            val_28_ = nil
          end
        elseif (case_128_ == "inherit") then
          local attrs
          local function _132_(_241, _242)
            return ((_241:type() == "inherited_attrs") and (_242 == "attrs"))
          end
          attrs = find_child(binding, _132_)
          local attr
          local function _133_(_241, _242)
            return ((_241:type() == "identifier") and (_242 == "attr") and (vim.treesitter.get_node_text(_241, bufnr) == name))
          end
          attr = find_child(attrs, _133_)
          val_28_ = attr
        else
          val_28_ = nil
        end
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    bindings = tbl_26_
  end
  return bindings[1]
end
local function fragments_to_value(binding)
  local result = ""
  local notfounds = {}
  for _, fragment in ipairs(binding) do
    if ((_G.type(fragment) == "table") and (nil ~= fragment.value)) then
      local value = fragment.value
      result = (result .. value)
    elseif ((_G.type(fragment) == "table") and (nil ~= fragment.notfound)) then
      local notfound = fragment.notfound
      table.insert(notfounds, notfound)
    else
    end
  end
  if (#notfounds > 0) then
    return Result.err(notfounds)
  else
    return Result.ok(result)
  end
end
local function find_used_fetches(opts)
  local opts0 = (opts or {})
  local bufnr = opts0.bufnr
  local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())
  if (vim.bo[bufnr0].filetype ~= "nix") then
    vim.notify_once("This is meant to be used with Nix files")
    return nil
  else
  end
  local root = get_root({bufnr = bufnr0})
  local found_fetches
  do
    local fetches_query = gen_fetches_query()
    local tbl_26_ = {}
    local i_27_ = 0
    for _pattern, matcher, _metadata in fetches_query:iter_matches(root, bufnr0, 0, -1, {all = true}) do
      local val_28_
      do
        local res = {}
        for id, nodes in pairs(matcher) do
          local tbl_21_ = res
          for _, node in ipairs(nodes) do
            local k_22_, v_23_
            do
              local capture_id = fetches_query.captures[id]
              local function _140_()
                if (capture_id == "_fname") then
                  return vim.treesitter.get_node_text(node, bufnr0)
                elseif (capture_id == "_fargs") then
                  local all_bindings = find_all_local_bindings({bufnr = bufnr0, bounder = node})
                  vim.notify(string.format("DEBUG all-bindings keys: %s", vim.inspect(vim.tbl_keys(all_bindings))))
                  local tbl_21_0 = {}
                  for name, _0 in pairs(all_bindings) do
                    local k_22_0, v_23_0
                    do
                      local binding = try_get_binding_bounder({bufnr = bufnr0, node = node, name = name})
                      local fragments = try_get_binding_value({bufnr = bufnr0, bounder = node, identifier = name})
                      vim.notify(string.format("DEBUG try-get-binding-value(%s) = %s", name, vim.inspect(fragments)))
                      k_22_0, v_23_0 = name, {binding = binding, fragments = fragments}
                    end
                    if ((k_22_0 ~= nil) and (v_23_0 ~= nil)) then
                      tbl_21_0[k_22_0] = v_23_0
                    else
                    end
                  end
                  return tbl_21_0
                elseif (capture_id == "_fwhole") then
                  return node
                else
                  return nil
                end
              end
              k_22_, v_23_ = capture_id, _140_()
            end
            if ((k_22_ ~= nil) and (v_23_ ~= nil)) then
              tbl_21_[k_22_] = v_23_
            else
            end
          end
        end
        val_28_ = res
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    found_fetches = tbl_26_
  end
  return found_fetches
end
local function get_fetch_at_cursor(opts)
  local opts0 = (opts or {})
  local bufnr = opts0.bufnr
  local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())
  local found_fetches = find_used_fetches({bufnr = bufnr0})
  local _local_143_ = vim.fn.getcursorcharpos()
  local _ = _local_143_[1]
  local cursor_row = _local_143_[2]
  local cursor_col = _local_143_[3]
  local _0 = _local_143_[4]
  local _1 = _local_143_[5]
  for _2, fetch in ipairs(found_fetches) do
    if vim.treesitter.is_in_node_range(fetch._fwhole, cursor_row, cursor_col) then
      return fetch
    else
    end
  end
  return nil
end
local function calculate_updates(opts)
  local opts0 = (opts or {})
  local bufnr = opts0.bufnr
  local fetch = opts0.fetch
  local new_data = opts0["new-data"]
  local updates = {}
  for key, new_value in pairs(new_data) do
    local existing
    do
      local t_145_ = fetch
      if (nil ~= t_145_) then
        t_145_ = t_145_._fargs
      else
      end
      if (nil ~= t_145_) then
        t_145_ = t_145_[key]
      else
      end
      if (nil ~= t_145_) then
        t_145_ = t_145_.fragments
      else
      end
      existing = t_145_
    end
    if existing then
      local i_fragment = 1
      local i_new_value = 1
      local short_circuit_3f = false
      while (not short_circuit_3f and (i_new_value <= #new_value)) do
        local fragment = existing[i_fragment]
        local fragment_node = fragment.node
        local fragment_value = fragment.value
        local fragment__3finterp = fragment["?interp"]
        if false then
        elseif (string.sub(new_value, i_new_value, (i_new_value + #fragment_value + -1)) == fragment_value) then
          i_fragment = (i_fragment + 1)
          i_new_value = (i_new_value + #fragment_value)
        elseif (i_fragment == #existing) then
          local _local_149_ = coords({bufnr = bufnr, node = fragment_node})
          local start_row = _local_149_["start-row"]
          local start_col = _local_149_["start-col"]
          local end_row = _local_149_["end-row"]
          local end_col = _local_149_["end-col"]
          table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}})
          short_circuit_3f = true
        else
          local last_fragment = existing[#existing]
          local last_fragment__3finterp = last_fragment["?interp"]
          local last_fragment_node = last_fragment.node
          local _local_150_ = coords({bufnr = bufnr, node = (fragment__3finterp or fragment_node)})
          local start_row = _local_150_["start-row"]
          local start_col = _local_150_["start-col"]
          local _local_151_ = coords({bufnr = bufnr, node = (last_fragment__3finterp or last_fragment_node)})
          local end_row = _local_151_["end-row"]
          local end_col = _local_151_["end-col"]
          table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}})
          short_circuit_3f = true
        end
      end
    else
      local _let_153_ = coords({bufnr = bufnr, node = fetch._fwhole})
      local end_row = _let_153_["end-row"]
      local end_col = _let_153_["end-col"]
      table.insert(updates, {type = "new", data = {bufnr = bufnr, start = end_row, ["end"] = end_row, replacement = {string.format("%s%s = \"%s\";", vim.fn["repeat"](" ", ((end_col - 1) + vim.bo[bufnr].shiftwidth)), key, new_value)}}})
    end
  end
  return updates
end
local function preview_update(update)
  local namespace = vim.api.nvim_create_namespace("NixUpdate")
  if ((_G.type(update) == "table") and (update.type == "old") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data["start-row"]) and (nil ~= update.data["start-col"]) and (nil ~= update.data["end-row"]) and (nil ~= update.data["end-col"]) and (nil ~= update.data.replacement))) then
    local bufnr = update.data.bufnr
    local start_row = update.data["start-row"]
    local start_col = update.data["start-col"]
    local end_row = update.data["end-row"]
    local end_col = update.data["end-col"]
    local replacement = update.data.replacement
    local _155_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, line in ipairs(replacement) do
        local val_28_ = {line, "DiffAdd"}
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _155_ = tbl_26_
    end
    return vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, start_col, {end_row = end_row, end_col = end_col, hl_mode = "replace", virt_text = _155_, virt_text_pos = "overlay"})
  elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data.replacement))) then
    local bufnr = update.data.bufnr
    local start = update.data.start
    local replacement = update.data.replacement
    local _157_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, line in ipairs(replacement) do
        local val_28_ = {{line, "DiffAdd"}}
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _157_ = tbl_26_
    end
    return vim.api.nvim_buf_set_extmark(bufnr, namespace, start, 0, {virt_lines = _157_, virt_lines_above = true})
  else
    return nil
  end
end
local function apply_update(update)
  if ((_G.type(update) == "table") and (update.type == "old") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data["start-row"]) and (nil ~= update.data["start-col"]) and (nil ~= update.data["end-row"]) and (nil ~= update.data["end-col"]) and (nil ~= update.data.replacement))) then
    local bufnr = update.data.bufnr
    local start_row = update.data["start-row"]
    local start_col = update.data["start-col"]
    local end_row = update.data["end-row"]
    local end_col = update.data["end-col"]
    local replacement = update.data.replacement
    return vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, replacement)
  elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data["end"]) and (nil ~= update.data.replacement))) then
    local bufnr = update.data.bufnr
    local start = update.data.start
    local _end = update.data["end"]
    local replacement = update.data.replacement
    return vim.api.nvim_buf_set_lines(bufnr, start, _end, true, replacement)
  else
    return nil
  end
end
local function notify_update(update)
  if ((_G.type(update) == "table") and (update.type == "old") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data["start-row"]) and (nil ~= update.data["start-col"]) and (nil ~= update.data["end-row"]) and (nil ~= update.data["end-col"]) and (nil ~= update.data.replacement))) then
    local bufnr = update.data.bufnr
    local start_row = update.data["start-row"]
    local start_col = update.data["start-col"]
    local end_row = update.data["end-row"]
    local end_col = update.data["end-col"]
    local replacement = update.data.replacement
    return vim.notify(string.format("Replaced text from (%d, %d) to (%d, %d) in buffer %d with %s", start_row, start_col, end_row, end_col, bufnr, vim.inspect(replacement)))
  elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data.replacement))) then
    local bufnr = update.data.bufnr
    local start = update.data.start
    local replacement = update.data.replacement
    return vim.notify(string.format("Inserted text at row %d in buffer %d with content %s", start, bufnr, vim.inspect(replacement)))
  else
    return nil
  end
end
local ns = vim.api.nvim_create_namespace("nix-update")
local function flash_update(update)
  if ((_G.type(update) == "table") and (update.type == "old") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data["start-row"]) and (nil ~= update.data["start-col"]) and (nil ~= update.data["end-row"]) and (nil ~= update.data["end-col"]))) then
    local bufnr = update.data.bufnr
    local start_row = update.data["start-row"]
    local start_col = update.data["start-col"]
    local end_row = update.data["end-row"]
    local end_col = update.data["end-col"]
    return vim.hl.range(bufnr, ns, "IncSearch", {start_row, start_col}, {end_row, end_col}, {regtype = "v", timeout = 1000, inclusive = false})
  elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data["end"]) and (nil ~= update.data.replacement))) then
    local bufnr = update.data.bufnr
    local start = update.data.start
    local _end = update.data["end"]
    local replacement = update.data.replacement
    return vim.hl.range(bufnr, ns, "DiffChange", {start, 0}, {(_end + #replacement), -1}, {regtype = "V", inclusive = true, timeout = 1000})
  else
    return nil
  end
end
local function prefetch_fetch(opts)
  local opts0 = (opts or {})
  local bufnr = opts0.bufnr
  local fetch = opts0.fetch
  local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())
  local fetch0 = (fetch or get_fetch_at_cursor({bufnr = bufnr0}))
  if not fetch0 then
    vim.notify("No fetch (neither given nor one at cursor)")
    return nil
  else
  end
  local prefetcher
  local _165_
  do
    local t_164_ = config
    if (nil ~= t_164_) then
      t_164_ = t_164_["extra-prefetchers"]
    else
    end
    if (nil ~= t_164_) then
      t_164_ = t_164_[fetch0._fname]
    else
    end
    _165_ = t_164_
  end
  local or_168_ = _165_
  if not or_168_ then
    local t_169_ = prefetchers
    if (nil ~= t_169_) then
      t_169_ = t_169_[fetch0._fname]
    else
    end
    or_168_ = t_169_
  end
  prefetcher = or_168_
  if not prefetcher then
    vim.notify(string.format("No prefetcher '%s' found", fetch0._fname))
    return nil
  else
  end
  local argument_values
  do
    local argument_values0 = {}
    local notfounds_pairs = {}
    for farg_name, farg_binding in pairs(fetch0._fargs) do
      vim.notify(string.format("DEBUG %s fragments: %s", farg_name, vim.inspect(farg_binding.fragments)))
      local function _172_(result)
        argument_values0[farg_name] = result
        return nil
      end
      local function _173_(notfounds)
        return table.insert(notfounds_pairs, {["farg-name"] = farg_name, notfounds = notfounds})
      end
      Result.bimap(fragments_to_value(farg_binding.fragments), _172_, _173_)
    end
    for _, _174_ in ipairs(notfounds_pairs) do
      local farg_name = _174_["farg-name"]
      local notfounds = _174_.notfounds
      vim.notify(string.format("Identifiers %s not found while evaluating %s!", vim.inspect(notfounds), farg_name))
    end
    if (#notfounds_pairs > 0) then
      return nil
    else
    end
    argument_values = argument_values0
  end
  vim.notify(string.format("DEBUG fetch._fname: %s", fetch0._fname))
  vim.notify(string.format("DEBUG argument-values: %s", vim.inspect(argument_values)))
  local prefetcher_cmd = prefetcher(argument_values)
  if not prefetcher_cmd then
    vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch0._fname))
    return nil
  else
  end
  local function _178_(_177_)
    local stdout = _177_.stdout
    local stderr = _177_.stderr
    if (#stdout == 0) then
      cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, err = string.format("Oopsie: %s", vim.inspect(stderr))}
      return nil
    else
    end
    cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, data = prefetcher.extractor(stdout)}
    return nil
  end
  call_command(prefetcher_cmd, _178_)
  return vim.notify(string.format("Prefetch initiated, awaiting response..."))
end
return {["fetches-query-string"] = fetches_query_string, ["gen-fetches-names"] = gen_fetches_names, ["gen-fetches-query"] = gen_fetches_query, ["get-root"] = get_root, ["find-all-local-bindings"] = find_all_local_bindings, ["try-get-binding-value"] = try_get_binding_value, ["fragments-to-value"] = fragments_to_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["calculate-updates"] = calculate_updates, ["preview-update"] = preview_update, ["apply-update"] = apply_update, ["notify-update"] = notify_update, ["flash-update"] = flash_update, ["prefetch-fetch"] = prefetch_fetch}
