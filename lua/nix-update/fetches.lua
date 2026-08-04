-- [nfnl] fnl/nix-update/fetches.fnl
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
  local function fn_6_(k, _)
    return k
  end
  names = vim.iter(pairs(prefetchers)):map(fn_6_):totable()
  local do_tgt_8_
  do
    local t_7_ = config
    if (nil ~= t_7_) then
      t_7_ = t_7_["extra-prefetchers"]
    else
    end
    do_tgt_8_ = t_7_
  end
  local function fn_10_(k, _)
    return k
  end
  vim.list_extend(names, vim.iter(pairs((do_tgt_8_ or {}))):map(fn_10_):totable())
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
      local function hashfn_16_(_241, _242)
        return ((_241:type() == "attrpath") and (_242 == "attrpath"))
      end
      attr = find_child(binding, hashfn_16_)
      local attr_name
      if attr then
        attr_name = vim.treesitter.get_node_text(attr, bufnr0)
      else
        attr_name = nil
      end
      local bool_expr
      do
        local bool_expr0
        local function hashfn_18_(_241, _242)
          return ((_241:type() == "variable_expression") and (_242 == "expression"))
        end
        bool_expr0 = find_child(binding, hashfn_18_)
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
      local number_expr
      do
        local number_3f
        local function hashfn_21_(_241)
          return vim.list_contains({"integer_expression", "float_expression"}, _241:type())
        end
        number_3f = hashfn_21_
        local number_expression
        local function hashfn_22_(_241, _242)
          return ((_242 == "expression") and number_3f(_241))
        end
        local or_23_ = find_child(binding, hashfn_22_)
        if not or_23_ then
          local unary_expression
          local function hashfn_25_(_241, _242)
            return ((_242 == "expression") and (_241:type() == "unary_expression"))
          end
          unary_expression = find_child(binding, hashfn_25_)
          local and_26_ = unary_expression
          if and_26_ then
            local function hashfn_27_(_241, _242)
              return ((_242 == "argument") and number_3f(_241))
            end
            and_26_ = find_child(unary_expression, hashfn_27_)
          end
          if and_26_ then
            or_23_ = unary_expression
          else
            or_23_ = nil
          end
        end
        number_expression = or_23_
        if number_expression then
          number_expr = {{node = number_expression, value = vim.treesitter.get_node_text(number_expression, bufnr0)}}
        else
          number_expr = nil
        end
      end
      local string_expr
      do
        local string_expression
        local function hashfn_30_(_241, _242)
          return ((_241:type() == "string_expression") and (_242 == "expression"))
        end
        string_expression = find_child(binding, hashfn_30_)
        if string_expression then
          if (string_expression:named_child_count() > 0) then
            local tbl_26_ = {}
            local i_27_ = 0
            for node, _0 in string_expression:iter_children() do
              local val_28_
              do
                local case_31_ = node:type()
                if (case_31_ == "interpolation") then
                  local let_32_
                  do
                    local variable_expression
                    if (nil ~= node) then
                      local function hashfn_33_(_241, _242)
                        return ((_241:type() == "variable_expression") and (_242 == "expression"))
                      end
                      variable_expression = find_child(node, hashfn_33_)
                    else
                      variable_expression = nil
                    end
                    if variable_expression then
                      let_32_ = {["?interp"] = node, name = vim.treesitter.get_node_text(variable_expression, bufnr0)}
                    else
                      let_32_ = nil
                    end
                  end
                  local or_36_ = let_32_
                  if not or_36_ then
                    local select_expression
                    if (nil ~= node) then
                      local function hashfn_38_(_241, _242)
                        return ((_241:type() == "select_expression") and (_242 == "expression"))
                      end
                      select_expression = find_child(node, hashfn_38_)
                    else
                      select_expression = nil
                    end
                    local attrset_name
                    if (nil ~= select_expression) then
                      local tmp_3_
                      local function hashfn_40_(_241, _242)
                        return ((_241:type() == "variable_expression") and (_242 == "expression"))
                      end
                      tmp_3_ = find_child(select_expression, hashfn_40_)
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
                      local function hashfn_43_(_241, _242)
                        return ((_241:type() == "attrpath") and (_242 == "attrpath"))
                      end
                      tmp_3_ = find_child(select_expression, hashfn_43_)
                      if (nil ~= tmp_3_) then
                        attr_name0 = vim.treesitter.get_node_text(tmp_3_, bufnr0)
                      else
                        attr_name0 = nil
                      end
                    else
                      attr_name0 = nil
                    end
                    if (attrset_name and attr_name0) then
                      or_36_ = {["?interp"] = node, name = attr_name0, ["?from"] = attrset_name}
                    else
                      or_36_ = nil
                    end
                  end
                  val_28_ = or_36_
                else
                  local and_47_ = (nil ~= case_31_)
                  if and_47_ then
                    local t = case_31_
                    and_47_ = ((t == "string_fragment") or (t == "escape_sequence"))
                  end
                  if and_47_ then
                    local t = case_31_
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
            local _let_51_ = coords({bufnr = bufnr0, node = string_expression})
            local start_row = _let_51_["start-row"]
            local start_col = _let_51_["start-col"]
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
          local function hashfn_54_(_241, _242)
            return ((_241:type() == "variable_expression") and (_242 == "expression"))
          end
          variable_expression = find_child(binding, hashfn_54_)
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
          local function hashfn_57_(_241, _242)
            return ((_241:type() == "select_expression") and (_242 == "expression"))
          end
          select_expression = find_child(binding, hashfn_57_)
        else
          select_expression = nil
        end
        local attrset_name
        if (nil ~= select_expression) then
          local tmp_3_
          local function hashfn_59_(_241, _242)
            return ((_241:type() == "variable_expression") and (_242 == "expression"))
          end
          tmp_3_ = find_child(select_expression, hashfn_59_)
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
          local function hashfn_62_(_241, _242)
            return ((_241:type() == "attrpath") and (_242 == "attrpath"))
          end
          tmp_3_ = find_child(select_expression, hashfn_62_)
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
      local expr = (string_expr or bool_expr or number_expr or var_expr or attr_expr)
      bindings[attr_name] = expr
    elseif (case_15_ == "inherit") then
      local attrs
      local function hashfn_66_(_241, _242)
        return ((_241:type() == "inherited_attrs") and (_242 == "attrs"))
      end
      attrs = find_child(binding, hashfn_66_)
      for node, node_name in attrs:iter_children() do
        if ((node:type() == "identifier") and (node_name == "attr")) then
          local attr_name = vim.treesitter.get_node_text(node, bufnr0)
          bindings[attr_name] = {{name = attr_name, ["?inherit"] = true}}
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
    local case_72_ = bounder:parent():type()
    if (case_72_ == "attrset_expression") then
      recurse_3f = false
    elseif ((case_72_ == "let_expression") or (case_72_ == "rec_attrset_expression")) then
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
      local and_78_ = parent_bounder
      if and_78_ then
        local and_79_ = (parent_bounder:type() ~= "rec_attrset_expression") and (parent_bounder:type() ~= "let_expression")
        if and_79_ then
          local and_80_ = (parent_bounder:type() == "attrset_expression")
          if and_80_ then
            local tmp_3_ = parent_bounder:parent()
            if (nil ~= tmp_3_) then
              local tmp_3_0 = tmp_3_:type()
              if (nil ~= tmp_3_0) then
                and_80_ = (tmp_3_0 == "function_expression")
              else
                and_80_ = nil
              end
            else
              and_80_ = nil
            end
          end
          and_79_ = not and_80_
        end
        local or_85_ = and_79_
        if not or_85_ then
          local function hashfn_86_(_241)
            return (_241:type() == "binding_set")
          end
          or_85_ = not find_child(parent_bounder, hashfn_86_)
        end
        and_78_ = or_85_
      end
      if not and_78_ then break end
      parent_bounder = parent_bounder:parent()
    end
    local from0 = nil
    local only_for = nil
    local if_tgt_87_
    if (nil ~= parent_bounder) then
      local tmp_3_ = parent_bounder:type()
      if (nil ~= tmp_3_) then
        if_tgt_87_ = (tmp_3_ == "attrset_expression")
      else
        if_tgt_87_ = nil
      end
    else
      if_tgt_87_ = nil
    end
    local and_91_ = if_tgt_87_
    if and_91_ then
      if (nil ~= parent_bounder) then
        local tmp_3_ = parent_bounder:parent()
        if (nil ~= tmp_3_) then
          local tmp_3_0 = tmp_3_:type()
          if (nil ~= tmp_3_0) then
            and_91_ = (tmp_3_0 == "function_expression")
          else
            and_91_ = nil
          end
        else
          and_91_ = nil
        end
      else
        and_91_ = nil
      end
    end
    if and_91_ then
      local parent = parent_bounder:parent()
      local universal_parameter
      local function hashfn_97_(_241, _242)
        return ((_241:type() == "identifier") and (_242 == "universal"))
      end
      universal_parameter = find_child(parent, hashfn_97_)
      local formals
      local if_tgt_98_
      if (nil ~= parent) then
        local tmp_3_
        local function hashfn_100_(_241, _242)
          return ((_241:type() == "formals") and (_242 == "formals"))
        end
        tmp_3_ = find_child(parent, hashfn_100_)
        if (nil ~= tmp_3_) then
          local tmp_3_0
          local function hashfn_102_(_241, _242)
            local and_103_ = (_241:type() == "formal") and (_242 == "formal")
            if and_103_ then
              local function hashfn_104_(_2410, _2420)
                return (_2420 == "default")
              end
              and_103_ = (find_child(_241, hashfn_104_) == nil)
            end
            return and_103_
          end
          tmp_3_0 = find_children(tmp_3_, hashfn_102_)
          if (nil ~= tmp_3_0) then
            local tmp_3_1 = vim.iter(tmp_3_0)
            if (nil ~= tmp_3_1) then
              local tmp_3_2
              local function hashfn_107_(_241)
                local function hashfn_108_(_2410, _2420)
                  return (_2420 == "name")
                end
                return find_child(_241, hashfn_108_)
              end
              tmp_3_2 = tmp_3_1:map(hashfn_107_)
              if (nil ~= tmp_3_2) then
                local tmp_3_3
                local function hashfn_110_(_241)
                  return vim.treesitter.get_node_text(_241, bufnr0)
                end
                tmp_3_3 = tmp_3_2:map(hashfn_110_)
                if (nil ~= tmp_3_3) then
                  if_tgt_98_ = tmp_3_3:totable()
                else
                  if_tgt_98_ = nil
                end
              else
                if_tgt_98_ = nil
              end
            else
              if_tgt_98_ = nil
            end
          else
            if_tgt_98_ = nil
          end
        else
          if_tgt_98_ = nil
        end
      else
        if_tgt_98_ = nil
      end
      formals = (if_tgt_98_ or {})
      if (universal_parameter ~= nil) then
        from0 = vim.treesitter.get_node_text(universal_parameter, bufnr0)
      else
        only_for = formals
      end
    else
    end
    if parent_bounder then
      local function hashfn_119_(_241)
        return (_241:type() == "binding_set")
      end
      parent_bounder = find_child(parent_bounder, hashfn_119_)
    else
    end
    return {from = from0, ["only-for"] = only_for, ["parent-bounder"] = parent_bounder}
  end
  local bindings = find_all_local_bindings({bufnr = bufnr0, bounder = bounder})
  local binding = bindings[identifier]
  local final_binding
  if binding then
    local find_up
    local function fn_122_(arg_121_)
      local fragment = arg_121_.v
      if ((_G.type(fragment) == "table") and true and (nil ~= fragment.node) and (nil ~= fragment.value)) then
        local _3finterp = fragment["?interp"]
        local node = fragment.node
        local value = fragment.value
        return {["?interp"] = _3finterp, node = node, value = value}
      elseif ((_G.type(fragment) == "table") and (nil ~= fragment.name) and (nil ~= fragment["?inherit"])) then
        local name = fragment.name
        local inherit_3f = fragment["?inherit"]
        local _let_123_ = find_parent_bounder()
        local next_from = _let_123_.from
        local parent_bounder = _let_123_["parent-bounder"]
        if parent_bounder then
          return (try_get_binding_value({bufnr = bufnr0, bounder = parent_bounder, from = next_from, identifier = name, depth = (depth0 + 1), ["depth-limit"] = depth_limit0}) or {{notfound = name}})
        else
          return {{notfound = name}}
        end
      elseif ((_G.type(fragment) == "table") and true and (nil ~= fragment.name) and true) then
        local _3finterp = fragment["?interp"]
        local name = fragment.name
        local _3ffrom = fragment["?from"]
        local _let_125_ = find_parent_bounder()
        local next_from = _let_125_.from
        local only_for = _let_125_["only-for"]
        local parent_bounder = _let_125_["parent-bounder"]
        local next_bounder
        if (recurse_3f or (_3ffrom and (from == _3ffrom))) then
          next_bounder = bounder
        elseif (only_for and _3ffrom and not vim.tbl_contains(only_for, _3ffrom)) then
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
          local resolved = (try_get_binding_value({bufnr = bufnr0, bounder = next_bounder, from = next_from, identifier = name, depth = (depth0 + 1), ["depth-limit"] = depth_limit0}) or {{notfound = name}})
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
    find_up = fn_122_
    local full_fragments
    local function fn_132_(k, v)
      return find_up({k = k, v = v})
    end
    full_fragments = vim.iter(ipairs(binding)):map(fn_132_):totable()
    final_binding = full_fragments
  else
    local _let_133_ = find_parent_bounder()
    local parent_bounder = _let_133_["parent-bounder"]
    local from0 = _let_133_.from
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
        local case_139_ = binding:type()
        if (case_139_ == "binding") then
          local attr
          local function hashfn_140_(_241)
            return (_241:type() == "attrpath")
          end
          attr = find_child(binding, hashfn_140_)
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
        elseif (case_139_ == "inherit") then
          local attrs
          local function hashfn_143_(_241, _242)
            return ((_241:type() == "inherited_attrs") and (_242 == "attrs"))
          end
          attrs = find_child(binding, hashfn_143_)
          local attr
          local function hashfn_144_(_241, _242)
            return ((_241:type() == "identifier") and (_242 == "attr") and (vim.treesitter.get_node_text(_241, bufnr) == name))
          end
          attr = find_child(attrs, hashfn_144_)
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
              local function if_else_151_()
                if (capture_id == "_fname") then
                  return vim.treesitter.get_node_text(node, bufnr0)
                elseif (capture_id == "_fargs") then
                  local all_bindings = find_all_local_bindings({bufnr = bufnr0, bounder = node})
                  local tbl_21_0 = {}
                  for name, _0 in pairs(all_bindings) do
                    local k_22_0, v_23_0
                    do
                      local binding = try_get_binding_bounder({bufnr = bufnr0, node = node, name = name})
                      local fragments = try_get_binding_value({bufnr = bufnr0, bounder = node, identifier = name})
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
              k_22_, v_23_ = capture_id, if_else_151_()
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
  local _local_154_ = vim.api.nvim_win_get_cursor(0)
  local cursor_row = _local_154_[1]
  local cursor_col = _local_154_[2]
  for _, fetch in ipairs(found_fetches) do
    if vim.treesitter.is_in_node_range(fetch._fwhole, (cursor_row - 1), cursor_col) then
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
      local t_156_ = fetch
      if (nil ~= t_156_) then
        t_156_ = t_156_._fargs
      else
      end
      if (nil ~= t_156_) then
        t_156_ = t_156_[key]
      else
      end
      if (nil ~= t_156_) then
        t_156_ = t_156_.fragments
      else
      end
      existing = t_156_
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
          local _local_160_ = coords({bufnr = bufnr, node = fragment_node})
          local start_row = _local_160_["start-row"]
          local start_col = _local_160_["start-col"]
          local end_row = _local_160_["end-row"]
          local end_col = _local_160_["end-col"]
          table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}})
          short_circuit_3f = true
        else
          local last_fragment = existing[#existing]
          local last_fragment__3finterp = last_fragment["?interp"]
          local last_fragment_node = last_fragment.node
          local _local_161_ = coords({bufnr = bufnr, node = (fragment__3finterp or fragment_node)})
          local start_row = _local_161_["start-row"]
          local start_col = _local_161_["start-col"]
          local _local_162_ = coords({bufnr = bufnr, node = (last_fragment__3finterp or last_fragment_node)})
          local end_row = _local_162_["end-row"]
          local end_col = _local_162_["end-col"]
          table.insert(updates, {type = "old", data = {bufnr = bufnr, ["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col, replacement = {string.sub(new_value, i_new_value)}}})
          short_circuit_3f = true
        end
      end
    else
      local _let_164_ = coords({bufnr = bufnr, node = fetch._fwhole})
      local end_row = _let_164_["end-row"]
      local end_col = _let_164_["end-col"]
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
    local let_166_
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
      let_166_ = tbl_26_
    end
    return vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, start_col, {end_row = end_row, end_col = end_col, hl_mode = "replace", virt_text = let_166_, virt_text_pos = "overlay"})
  elseif ((_G.type(update) == "table") and (update.type == "new") and ((_G.type(update.data) == "table") and (nil ~= update.data.bufnr) and (nil ~= update.data.start) and (nil ~= update.data.replacement))) then
    local bufnr = update.data.bufnr
    local start = update.data.start
    local replacement = update.data.replacement
    local let_168_
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
      let_168_ = tbl_26_
    end
    return vim.api.nvim_buf_set_extmark(bufnr, namespace, start, 0, {virt_lines = let_168_, virt_lines_above = true})
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
  local do_tgt_176_
  do
    local t_175_ = config
    if (nil ~= t_175_) then
      t_175_ = t_175_["extra-prefetchers"]
    else
    end
    if (nil ~= t_175_) then
      t_175_ = t_175_[fetch0._fname]
    else
    end
    do_tgt_176_ = t_175_
  end
  local or_179_ = do_tgt_176_
  if not or_179_ then
    local t_180_ = prefetchers
    if (nil ~= t_180_) then
      t_180_ = t_180_[fetch0._fname]
    else
    end
    or_179_ = t_180_
  end
  prefetcher = or_179_
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
      local function fn_183_(result)
        argument_values0[farg_name] = result
        return nil
      end
      local function fn_184_(notfounds)
        return table.insert(notfounds_pairs, {["farg-name"] = farg_name, notfounds = notfounds})
      end
      Result.bimap(fragments_to_value(farg_binding.fragments), fn_183_, fn_184_)
    end
    for _, each_185_ in ipairs(notfounds_pairs) do
      local farg_name = each_185_["farg-name"]
      local notfounds = each_185_.notfounds
      vim.notify(string.format("Identifiers %s not found while evaluating %s!", vim.inspect(notfounds), farg_name))
    end
    if (#notfounds_pairs > 0) then
      return nil
    else
    end
    argument_values = argument_values0
  end
  local prefetcher_cmd = prefetcher(argument_values)
  if not prefetcher_cmd then
    vim.notify(string.format("Could not generate command for the prefetcher '%s'", fetch0._fname))
    return nil
  else
  end
  local function fn_189_(arg_188_)
    local stdout = arg_188_.stdout
    local stderr = arg_188_.stderr
    if (#stdout == 0) then
      cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, err = string.format("Oopsie: %s", vim.inspect(stderr))}
      return nil
    else
    end
    cache[fetch0._fwhole] = {bufnr = bufnr0, fetch = fetch0, data = prefetcher.extractor(stdout)}
    return nil
  end
  call_command(prefetcher_cmd, fn_189_)
  return vim.notify(string.format("Prefetch initiated, awaiting response..."))
end
return {["fetches-query-string"] = fetches_query_string, ["gen-fetches-names"] = gen_fetches_names, ["gen-fetches-query"] = gen_fetches_query, ["get-root"] = get_root, ["find-all-local-bindings"] = find_all_local_bindings, ["try-get-binding-value"] = try_get_binding_value, ["fragments-to-value"] = fragments_to_value, ["find-used-fetches"] = find_used_fetches, ["get-fetch-at-cursor"] = get_fetch_at_cursor, ["calculate-updates"] = calculate_updates, ["preview-update"] = preview_update, ["apply-update"] = apply_update, ["notify-update"] = notify_update, ["flash-update"] = flash_update, ["prefetch-fetch"] = prefetch_fetch}
