 local _local_1_ = require("nix-update.fetches") local find_used_fetches = _local_1_["find-used-fetches"]
 local prefetch_fetch = _local_1_["prefetch-fetch"]


 local _local_2_ = require("nix-update._cache") local cache = _local_2_["cache"]


 local _local_3_ = require("nix-update.utils") local coords = _local_3_["coords"]
 local concat_two = _local_3_["concat-two"]


 local function set_diagnostic(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]
 local fetch = opts0["fetch"]
 local data = opts0["data"]
 local err = opts0["err"]



 if not bufnr then
 vim.notify(string.format("No bufnr given for setting extmark", bufnr))



 return nil else end


 if not fetch then
 vim.notify(string.format("No fetch given for setting extmark", fetch))



 return nil else end


 local namespace = vim.api.nvim_create_namespace("NixUpdate")

 if (err and (#(data or {}) == 0)) then

 do local _let_6_ = coords({bufnr = bufnr, node = fetch._fwhole}) local start_row = _let_6_["start-row"]
 local start_col = _let_6_["start-col"]

 vim.diagnostic.set(namespace, bufnr, {{lnum = start_row, col = start_col, severity = vim.diagnostic.severity.ERROR, message = vim.inspect(err), source = "NixUpdate"}}) end







 return nil else end

 local diagnostics
 do local tbl_21_ = {} local i_22_ = 0 for key, value in pairs(data) do local val_23_
 do



 local function _8_() local farg = fetch._fargs[key]
 if farg then

 local _let_9_ = coords({bufnr = bufnr, node = farg.binding}) local start_row = _let_9_["start-row"] local start_col = _let_9_["start-col"]

 return {["start-row"] = start_row, ["start-col"] = start_col, message = string.format("Update field \"%s\" to \"%s\"", key, value), severity = vim.diagnostic.severity.HINT} else







 local _let_10_ = coords({bufnr = bufnr, node = fetch._fwhole}) local start_row = _let_10_["start-row"] local start_col = _let_10_["start-col"]

 return {["start-row"] = start_row, ["start-col"] = start_col, message = string.format("Add new field \"%s\" with value \"%s\"", key, value), severity = vim.diagnostic.severity.WARN} end end local _let_12_ = _8_() local start_row = _let_12_["start-row"] local start_col = _let_12_["start-col"] local message = _let_12_["message"] local severity = _let_12_["severity"]






 val_23_ = {lnum = start_row, col = start_col, severity = severity, message = message, source = "NixUpdate"} end if (nil ~= val_23_) then i_22_ = (i_22_ + 1) tbl_21_[i_22_] = val_23_ else end end diagnostics = tbl_21_ end






 return vim.diagnostic.set(namespace, bufnr, concat_two(vim.diagnostic.get(nil, {namespace = namespace}), diagnostics)) end











 local function remove_diagnostic(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]




 return nil end

 local function NixPrefetch(opts)

 local opts0 = (opts or {})
 local bufnr = opts0["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches({bufnr = bufnr0})


 local namespace = vim.api.nvim_create_namespace("NixPrefetch")



 vim.diagnostic.reset(namespace, bufnr0)


 cache({clear = true})



 for _, fetch in ipairs(found_fetches) do
 prefetch_fetch({bufnr = bufnr0, fetch = fetch}) end return nil end


 local function _14_() return NixPrefetch() end vim.api.nvim_create_user_command("NixPrefetch", _14_, {})

 return {["set-diagnostic"] = set_diagnostic, ["remove-diagnostic"] = remove_diagnostic}
