(local {: calculate-updates
        : preview-update
        : apply-update}
       (require "nix-update.fetches"))

(local {: cache}
       (require "nix-update._cache"))

(local {: config}
       (require "nix-update._config"))

;;; TODO: sort imports/exports alphabetically

(macro save-options [opts-symbol options]
  (assert-compile
    (sym? opts-symbol)
    "Expected a symbol"
    opts-symbol)
  (assert-compile
    (table? options)
    "Expected list of option names"
    options)
  (var res
    `(let [opts#
            (vim.tbl_deep_extend
              :keep
              ,opts-symbol ;;; Keep user-defined values
              ,(collect [_ v (pairs options)]
                 (values v [])))]))
  ;;; Store the config options
  (each [_ option (ipairs options)]
    (table.insert res
      `(each [k# v# (pairs (. opts# ,option))]
         (tset (. config ,option) k# v#))))
  res)

(fn setup [opts]
  ;;; Extract opts
  (local opts
         (or opts {}))
  (local opts
         (collect [k v (pairs opts)]
           (values (string.gsub k "_" "-") v)))

  ;;; Save user options in global config
  (save-options
    opts
    [:extra-prefetcher-cmds
     :extra-prefetcher-extractors])

  ;;; Set cache `on-index` handler
  (cache
    {:handler
      (fn [new _key value]
        (when new
          ;;; Extract opts
          (local {: bufnr
                  : fetch
                  : data
                  : err}
                 value)
          (when (and (= (length (or data [])) 0)
                     err)
            (vim.notify "Could not prefetch")
            (vim.print {: data : err})
            (lua "return"))
          (local updates (calculate-updates
                           {: bufnr
                            : fetch
                            :new-data data}))
          (each [_ update (ipairs updates)]
            ;;; TODO: fix preview-update (conceal/anticonceal)
            ;;
            ;; (preview-update update)
            (apply-update update))))}))

{: setup}
