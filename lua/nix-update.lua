 local _local_1_ = require("nix-update.fetches") local fetches_query_string = _local_1_["fetches-query-string"]
 local fetches_names = _local_1_["fetches-names"]
 local fetches_query = _local_1_["fetches-query"]
 local get_root = _local_1_["get-root"]
 local find_all_local_bindings = _local_1_["find-all-local-bindings"]
 local try_get_binding = _local_1_["try-get-binding"]
 local binding_to_value = _local_1_["binding-to-value"]
 local find_used_fetches = _local_1_["find-used-fetches"]
 local get_fetch_at_cursor = _local_1_["get-fetch-at-cursor"]
 local prefetch_fetch = _local_1_["prefetch-fetch"]


 local _local_2_ = require("nix-update.prefetchers") local gen_prefetcher_cmd = _local_2_["gen-prefetcher-cmd"]
 local get_prefetcher_extractor = _local_2_["get-prefetcher-extractor"]


 local _local_3_ = require("nix-update.diagnostics") local set_diagnostic = _local_3_["set-diagnostic"]


 local _local_4_ = require("nix-update.cache") local cache = _local_4_["cache"]


 local _local_5_ = require("nix-update.util") local call_command = _local_5_["call-command"]








 local function _6_(new, _key, value)
 if new then
 return set_diagnostic(value) else return nil end end cache({handler = _6_})

 return {fetches_query_string = fetches_query_string, fetches_names = fetches_names, fetches_query = fetches_query, get_root = get_root, try_get_binding = try_get_binding, binding_to_value = binding_to_value, find_used_fetches = find_used_fetches, get_fetch_at_cursor = get_fetch_at_cursor, prefetch_fetch = prefetch_fetch, gen_prefetcher_cmd = gen_prefetcher_cmd, call_prefether = call_command, cache = cache}