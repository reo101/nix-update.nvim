(local {: calculate-updates
        : preview-update
        : apply-update
        : notify-update
        : flash-update
        : prefetch-fetch}
       (require "nix-update.fetches"))

(local {: cache}
       (require "nix-update._cache"))

(local {: config}
       (require "nix-update._config"))

(macro save-options [opts-symbol options]
  (assert-compile
    (sym? opts-symbol)
    "Expected a symbol"
    opts-symbol)
  (assert-compile
    (table? options)
    "Expected list of option names"
    options)
  (local res
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
    [:extra-prefetchers])

  ;;; Save update-actions if provided (simple value, not proxied table)
  (when (?. opts :update-actions)
    (tset config :update-actions opts.update-actions))

  ;;; Map action names to functions
  (local action-handlers
         {:preview preview-update
          :apply   apply-update
          :notify  notify-update
          :flash   flash-update})

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
            (lua "return nil"))
          (vim.notify "Successful prefetch, applying updates...")
          (local updates (calculate-updates
                           {: bufnr
                            : fetch
                            :new-data data}))
          (each [_ update (ipairs updates)]
            (each [_ action (ipairs config.update-actions)]
              (let [handler (?. action-handlers action)]
                (when handler
                  (handler update)))))))}))

{: setup
 :prefetch_fetch prefetch-fetch}
