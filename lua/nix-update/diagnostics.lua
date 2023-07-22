 local _local_1_ = require("nix-update.fetches") local find_used_fetches = _local_1_["find-used-fetches"]
 local prefetch_fetch = _local_1_["prefetch-fetch"]


 local _local_2_ = require("nix-update._cache") local cache = _local_2_["cache"]


 local _local_3_ = require("nix-update.utils") local coords = _local_3_["coords"]
 local concat_two = _local_3_["concat-two"]


 local function set_diagnostic(opts)

 local opts0 = (opts or {})
 local _local_4_ = opts0 local bufnr = _local_4_["bufnr"]
 local fetch = _local_4_["fetch"]
 local data = _local_4_["data"]
 local err = _local_4_["err"]



 if not bufnr then
 vim.notify(string.format("No bufnr given for setting extmark", bufnr))



 return nil else end


 if not fetch then
 vim.notify(string.format("No fetch given for setting extmark", fetch))



 return nil else end


 local namespace = vim.api.nvim_create_namespace("NixUpdate")

 if (err and (#(data or {}) == 0)) then

 do local _let_7_ = coords({bufnr = bufnr, node = fetch._fwhole}) local start_row = _let_7_["start-row"]
 local start_col = _let_7_["start-col"]

 vim.diagnostic.set(namespace, bufnr, {{lnum = start_row, col = start_col, severity = vim.diagnostic.severity.ERROR, message = vim.inspect(err), source = "NixUpdate"}}) end







 return nil else end

 local diagnostics
 do local tbl_17_auto = {} local i_18_auto = #tbl_17_auto for key, value in pairs(data) do local val_19_auto
 do



 local function _10_() local farg = fetch._fargs[key]
 if farg then

 local _let_11_ = coords({bufnr = bufnr, node = farg.binding}) local start_row = _let_11_["start-row"] local start_col = _let_11_["start-col"]

 return {["start-row"] = start_row, ["start-col"] = start_col, message = string.format("Update field \"%s\" to \"%s\"", key, value), severity = vim.diagnostic.severity.HINT} else







 local _let_12_ = coords({bufnr = bufnr, node = fetch._fwhole}) local start_row = _let_12_["start-row"] local start_col = _let_12_["start-col"]

 return {["start-row"] = start_row, ["start-col"] = start_col, message = string.format("Add new field \"%s\" with value \"%s\"", key, value), severity = vim.diagnostic.severity.WARN} end end local _let_9_ = _10_() local start_row = _let_9_["start-row"] local start_col = _let_9_["start-col"] local message = _let_9_["message"] local severity = _let_9_["severity"]






 val_19_auto = {lnum = start_row, col = start_col, severity = severity, message = message, source = "NixUpdate"} end if (nil ~= val_19_auto) then i_18_auto = (i_18_auto + 1) do end (tbl_17_auto)[i_18_auto] = val_19_auto else end end diagnostics = tbl_17_auto end






 return vim.diagnostic.set(namespace, bufnr, concat_two(vim.diagnostic.get(nil, {namespace = namespace}), diagnostics)) end











 local function remove_diagnostic(opts)

 local opts0 = (opts or {})
 local _local_15_ = opts0 local bufnr = _local_15_["bufnr"]




 return nil end

 local function NixPrefetch(opts)

 local opts0 = (opts or {})
 local _local_16_ = opts0 local bufnr = _local_16_["bufnr"]



 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetches = find_used_fetches({bufnr = bufnr0})


 local namespace = vim.api.nvim_create_namespace("NixPrefetch")



 vim.diagnostic.reset(namespace, bufnr0)


 cache({clear = true})



 for _, fetch in ipairs(found_fetches) do
 prefetch_fetch({bufnr = bufnr0, fetch = fetch}) end return nil end


 local function _17_() return NixPrefetch() end vim.api.nvim_create_user_command("NixPrefetch", _17_, {})

 return {["set-diagnostic"] = set_diagnostic, ["remove-diagnostic"] = remove_diagnostic}
