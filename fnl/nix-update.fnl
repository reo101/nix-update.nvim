(local {: cache}
       (require "nix-update._cache"))

(local {: config
        : apply-options}
       (require "nix-update._config"))

(var initialized? false)
(var global-options-applied? false)

(fn normalize-options [opts]
  (collect [k v (pairs (or opts {}))]
    (if (= (type k) :string)
      (values (string.gsub k "_" "-") v)
      (values k v))))

(fn get-global-options []
  (let [raw-options (or vim.g.nix_update)]
    (if (= (type raw-options) :function)
      (let [(ok options-or-error) (pcall raw-options)]
        (if ok
          options-or-error
          (do
            (vim.notify
              (string.format "nix-update: failed to evaluate `vim.g.nix_update`: %s"
                             options-or-error)
              vim.log.levels.ERROR)
            nil)))
      raw-options)))

(fn apply-current-options []
  (local global-options (get-global-options))
  (local normalized-global-options
         (if (= (type global-options) :table)
           (normalize-options global-options)
           {}))

  (let [(ok err) (apply-options normalized-global-options)]
    (when (not ok)
      (vim.notify
        (string.format "nix-update: invalid configuration: %s" err)
        vim.log.levels.ERROR))
    ok))

(fn ensure-global-options []
  (when (not global-options-applied?)
    (apply-current-options)
    (set global-options-applied? true)))

(fn initialize []
  (ensure-global-options)

  (when initialized?
    (lua "return true"))

  (local {: calculate-updates
          : preview-update
          : apply-update
          : notify-update
          : flash-update}
         (require "nix-update.fetches"))

  (local action-handlers
         {:preview preview-update
          :apply apply-update
          :notify notify-update
          :flash flash-update})

  (fn on-cache-write [value]
    (local {: bufnr
            : fetch
            : data
            : err}
           value)

    (when (and (= (length (or data [])) 0)
               err)
      (vim.notify
        (string.format "Could not prefetch: %s" (vim.inspect err))
        vim.log.levels.ERROR)
      (lua "return nil"))

    (local updates
           (calculate-updates
             {:bufnr bufnr
              :fetch fetch
              :new-data data}))

    (each [_ update (ipairs updates)]
      (each [_ action (ipairs config.update-actions)]
        (let [handler (?. action-handlers action)]
          (when handler
            (handler update))))))

  (cache
    {:handler
      (fn [new _key value]
        (when new
          (on-cache-write value)))})

  (set initialized? true)
  true)

(fn setup [opts]
  (local normalized-current
         (normalize-options
           (or (get-global-options) {})))
  (local normalized-overrides
         (normalize-options opts))
  (local merged
         (vim.tbl_deep_extend
           :force
           normalized-current
           normalized-overrides))

  ;; NOTE: keeping `vim.g` as the source of truth (`setup` writes into it)
  (tset vim.g :nix_update merged)

  (set global-options-applied? false)
  (ensure-global-options)

  config)

(fn prefetch-fetch [opts]
  (initialize)
  (let [{: prefetch-fetch} (require "nix-update.fetches")]
    (prefetch-fetch opts)))

(fn prefetch-buffer [opts]
  (initialize)
  (let [{: prefetch-buffer} (require "nix-update.diagnostics")]
    (prefetch-buffer opts)))

{:setup setup
 :init initialize
 :prefetch_fetch prefetch-fetch
 :prefetch_buffer prefetch-buffer
 :config config}
