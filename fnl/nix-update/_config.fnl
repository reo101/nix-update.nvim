(local {: create-proxied
        : prefetcher-mt}
       (require :nix-update.utils))

(local default-update-actions [:apply :notify])

(local valid-update-actions
       {:apply true
        :flash true
        :notify true
        :preview true})

(local valid-option-keys
       {:extra-prefetchers true
        :extra-prefetcher-cmds true
        :update-actions true})

(local config {})

(tset config :extra-prefetchers (create-proxied))
(config.extra-prefetchers
  {:handler (fn [new _key value]
              (when new
                (setmetatable value prefetcher-mt)))})

(tset config :update-actions (vim.deepcopy default-update-actions))

(fn validate-extra-prefetchers [extra-prefetchers]
  (if (not (or (= extra-prefetchers nil)
               (= (type extra-prefetchers) :table)))
    (values false "`extra-prefetchers` must be a table")
    (if (not= (type extra-prefetchers) :table)
      (values true nil)
      (do
        (var err nil)
        (each [name prefetcher (pairs extra-prefetchers)]
          (when (and (not err)
                     (not= (type prefetcher) :table))
            (set err (string.format "`extra-prefetchers.%s` must be a table" name)))
          (when (and (not err)
                     (= (type prefetcher) :table)
                     (not= (type prefetcher.prefetcher) :function))
            (set err (string.format "`extra-prefetchers.%s.prefetcher` must be a function" name)))
          (when (and (not err)
                     (= (type prefetcher) :table)
                     prefetcher.extractor
                     (not= (type prefetcher.extractor) :function))
            (set err (string.format "`extra-prefetchers.%s.extractor` must be a function when set" name))))
        (if err
          (values false err)
          (values true nil))))))

(fn validate-update-actions [update-actions]
  (if (not (or (= update-actions nil)
               (= (type update-actions) :table)))
    (values false "`update-actions` must be a list")
    (if (not= (type update-actions) :table)
      (values true nil)
      (do
        (var err nil)
        (each [i action (ipairs update-actions)]
          (when (and (not err)
                     (not (?. valid-update-actions action)))
            (set err
              (string.format
                "`update-actions[%d]` must be one of: apply, flash, notify, preview"
                i))))
        (if err
          (values false err)
          (values true nil))))))

(fn validate-options [opts]
  (var err nil)

  (each [key _ (pairs opts)]
    (when (and (not err)
               (not (?. valid-option-keys key)))
      (set err (string.format "Unknown setup option `%s`" key))))

  (if err
    (values false err)
    (let [extra-prefetchers (or opts.extra-prefetchers
                               opts.extra-prefetcher-cmds)]
      (let [(ok-prefetchers err-prefetchers)
            (validate-extra-prefetchers extra-prefetchers)]
      (if (not ok-prefetchers)
        (values false err-prefetchers)
        (let [(ok-actions err-actions)
              (validate-update-actions opts.update-actions)]
          (if (not ok-actions)
            (values false err-actions)
            (values true nil))))))))

(fn apply-options [opts]
  (local opts (or opts {}))
  (let [(ok err) (validate-options opts)]
    (if (not ok)
      (values false err)
      (do
        (local extra-prefetchers (or opts.extra-prefetchers
                                   opts.extra-prefetcher-cmds))

        (config.extra-prefetchers {:clear true})
        (tset config :update-actions (vim.deepcopy default-update-actions))

        (when (= (type extra-prefetchers) :table)
          (each [name prefetcher (pairs extra-prefetchers)]
            (tset config.extra-prefetchers name prefetcher)))

        (when (= (type opts.update-actions) :table)
          (tset config :update-actions (vim.deepcopy opts.update-actions)))

        (values true nil)))))

{: config
 :apply-options apply-options}
