-- [nfnl] fnl/nix-update/utils/common.fnl
local function find_child(node, p_3f)
  for child, _3fname in node:iter_children() do
    if p_3f(child, _3fname) then
      return child
    else
    end
  end
  return nil
end
local function find_children(node, p_3f)
  local tbl_26_ = {}
  local i_27_ = 0
  for child, _3fname in node:iter_children() do
    local val_28_
    if p_3f(child, _3fname) then
      val_28_ = child
    else
      val_28_ = nil
    end
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function missing_keys(tbl, required_keys)
  local tbl_keys
  local function _4_(k, _)
    return k
  end
  tbl_keys = vim.iter(pairs(tbl)):map(_4_):totable()
  local function _5_(_, key)
    if vim.islist(key) then
      local found
      local function _6_(_0, k)
        return vim.list_contains(tbl_keys, k)
      end
      found = vim.iter(ipairs(key)):any(_6_)
      if not found then
        return {["any-of"] = key}
      else
        return nil
      end
    elseif not vim.list_contains(tbl_keys, key) then
      return {required = key}
    else
      return nil
    end
  end
  return vim.iter(ipairs(required_keys)):map(_5_):totable()
end
local function coords(opts)
  local opts0 = (opts or {})
  local bufnr = opts0.bufnr
  local node = opts0.node
  if not bufnr then
    vim.notify(string.format("No bufnr given for getting coords", bufnr))
    return nil
  else
  end
  if not node then
    vim.notify(string.format("No node given for getting coords", bufnr))
    return nil
  else
  end
  local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, bufnr)
  return {["start-row"] = start_row, ["start-col"] = start_col, ["end-row"] = end_row, ["end-col"] = end_col}
end
local function flatten_fragments(tbl)
  local result = {}
  local function recurse(t)
    if ((type(t) == "table") and vim.islist(t)) then
      for _, v in ipairs(t) do
        recurse(v)
      end
      return nil
    else
      return table.insert(result, t)
    end
  end
  recurse(tbl)
  return result
end
return {["find-child"] = find_child, ["find-children"] = find_children, ["missing-keys"] = missing_keys, coords = coords, ["flatten-fragments"] = flatten_fragments}
