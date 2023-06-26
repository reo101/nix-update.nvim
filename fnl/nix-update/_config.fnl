(local {: prefetcher-cmd-mt}
       (require :nix-update.util))

(fn create-proxied []
  (var raw {})

  (var on-index (fn [_new _key _value]))

  (local proxy {})

  (local proxy-mt
         {:__index
            (fn [_self key]
              ;;; Trigger the on-index handler (old key)
              (on-index false key)
              (rawget raw key))
          :__newindex
            (fn [_self key value]
              ;;; Trigger the on-index handler (new key)
              (on-index true key value)
              (rawset raw key value))
          :__call
            (fn [_self opts]
              ;;; Extract opts
              (local opts (or opts {}))
              (local {: handler
                      : clear}
                     opts)

              ;;; Set the on-index handler
              (when handler
                (set on-index handler))

              ;;; Clear raw
              (when clear
                (set raw {}))

              ;;; If empty - give access to raw table
              ;;;           (for iterating)
              (when (vim.tbl_isempty opts)
                raw))})

  (setmetatable proxy proxy-mt))

(local config {})

(tset config :extra-prefetcher-cmds (create-proxied))
(config.extra-prefetcher-cmds
  {:handler (fn [new _key value]
              (when new
                (setmetatable value prefetcher-cmd-mt)))})

(tset config :extra-prefetcher-extractors (create-proxied))

{: config}
