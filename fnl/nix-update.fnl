(local {: set-diagnostic}
       (require "nix-update.diagnostics"))

(local {: prefetcher-cmd-mt}
       (require "nix-update.prefetchers"))

(local {: cache}
       (require "nix-update._cache"))

(local {: config}
       (require "nix-update._config"))

;;; TODO: `config`-urize plugin
;;;        add options (=> config)
;;;        do not reexport everything
;;;        sort imports/exports alphabetically

(fn setup [opts]
  ;;; Extract opts
  (local opts
         (or opts {}))
  (local opts
         (collect [k v (pairs opts)]
           (values (string.gsub k "_" "-") v)))
  (local opts
         (vim.tbl_deep_extend
           :keep ;; Keep user-defined values
           opts
           {:extra-prefetcher-cmds       []
            :extra-prefetcher-extractors []}))
  (local {: extra-prefetcher-cmds
          : extra-prefetcher-extractors}
         opts)

  ;;; Store the config options
  (tset config :extra-prefetcher-cmds (vim.tbl_map
                                        #(setmetatable $ prefetcher-cmd-mt)
                                        extra-prefetcher-cmds))
  (tset config :extra-prefetcher-extractors extra-prefetcher-extractors)

  ;;; Set cache `on-index` handler
  (cache {:handler (fn [new _key value]
                     (when new
                       (set-diagnostic value)))}))

{: setup}
