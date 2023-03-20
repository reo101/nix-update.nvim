(local {: fetches-query-string
        : fetches-names
        : fetches-query
        : get-root
        : try-get-value
        : find-used-fetches
        : get-fetch-at-cursor
        : prefetch-fetch-at-cursor}
       (require :nix-update.fetches))

(local {: gen-prefetcher-cmd}
       (require "nix-update.prefetchers"))

(local {: call-command}
       (require "nix-update.util"))

(fn nix-update [bufnr]
  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get found fetchers
  (local found-fetchers (find-used-fetches bufnr))

  ;;; Create namespace for the extmarks
  (local namespace (vim.api.nvim_create_namespace "NixUpdate"))

  ;;; Clear old extmarks
  (vim.api.nvim_buf_clear_namespace bufnr namespace 0 -1)

  found-fetchers)

;;; Define command
(vim.api.nvim_create_user_command "NixUpdate" #(nix-update) {})

{:fetches_query_string     fetches-query-string
 :fetches_names            fetches-names
 :fetches_query            fetches-query
 :get_root                 get-root
 :try_get_value            try-get-value
 :find_used_fetches        find-used-fetches
 :get_fetch_at_cursor      get-fetch-at-cursor
 :prefetch_fetch_at_cursor prefetch-fetch-at-cursor
 :gen_prefetcher_cmd       gen-prefetcher-cmd
 :call_prefether           call-command
 :nix_update               nix-update}
