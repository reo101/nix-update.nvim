(local {: create-proxied
        : prefetcher-mt}
       (require :nix-update.utils))

(local config {})

(tset config :extra-prefetchers (create-proxied))
(config.extra-prefetchers
  {:handler (fn [new _key value]
              (when new
                (setmetatable value prefetcher-mt)))})

{: config}
