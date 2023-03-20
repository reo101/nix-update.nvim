 local _local_1_ = require("nix-update.fetches") local fetches_query_string = _local_1_["fetches-query-string"]
 local fetches_names = _local_1_["fetches-names"]
 local fetches_query = _local_1_["fetches-query"]
 local get_root = _local_1_["get-root"]
 local try_get_value = _local_1_["try-get-value"]
 local find_used_fetches = _local_1_["find-used-fetches"]
 local get_fetch_at_cursor = _local_1_["get-fetch-at-cursor"]
 local prefetch_fetch_at_cursor = _local_1_["prefetch-fetch-at-cursor"]


 local _local_2_ = require("nix-update.prefetchers") local gen_prefetcher_cmd = _local_2_["gen-prefetcher-cmd"]


 local _local_3_ = require("nix-update.util") local call_command = _local_3_["call-command"]


 local function nix_update(bufnr)

 local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())



 local found_fetchers = find_used_fetches(bufnr0)


 local namespace = vim.api.nvim_create_namespace("NixUpdate")


 vim.api.nvim_buf_clear_namespace(bufnr0, namespace, 0, -1)

 return found_fetchers end


 local function _4_() return nix_update() end vim.api.nvim_create_user_command("NixUpdate", _4_, {})

 return {fetches_query_string = fetches_query_string, fetches_names = fetches_names, fetches_query = fetches_query, get_root = get_root, try_get_value = try_get_value, find_used_fetches = find_used_fetches, get_fetch_at_cursor = get_fetch_at_cursor, prefetch_fetch_at_cursor = prefetch_fetch_at_cursor, gen_prefetcher_cmd = gen_prefetcher_cmd, call_prefether = call_command, nix_update = nix_update}