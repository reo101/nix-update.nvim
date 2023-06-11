(local {: fetches-query-string
        : fetches-names
        : fetches-query
        : get-root
        : try-get-binding
        : binding-to-value
        : find-used-fetches
        : get-fetch-at-cursor
        : prefetch-fetch}
       (require :nix-update.fetches))

(local {: gen-prefetcher-cmd}
       (require "nix-update.prefetchers"))

(local {: set-diagnostic}
       (require "nix-update.diagnostics"))

(local {: cache}
       (require "nix-update.cache"))

(local {: call-command}
       (require "nix-update.util"))

;;; TODO: `config`-urize plugin
;;;        add options (=> config)
;;;        do not reexport everything
;;;        sort imports/exports alphabetically

;;; Set cache `on-index` handler
(cache {:handler (fn [new _key value]
                   (when new
                     (set-diagnostic value)))})

{:fetches_query_string  fetches-query-string
 :fetches_names         fetches-names
 :fetches_query         fetches-query
 :get_root              get-root
 :try_get_binding       try-get-binding
 :binding_to_value      binding-to-value
 :find_used_fetches     find-used-fetches
 :get_fetch_at_cursor   get-fetch-at-cursor
 :prefetch_fetch        prefetch-fetch
 :gen_prefetcher_cmd    gen-prefetcher-cmd
 :call_prefether        call-command
 :cache                 cache}
