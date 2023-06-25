(var config {})

(var on-index (fn [_new _key _value]))

(local proxy {})

(local proxy-mt
       {:__index
          (fn [_self key]
            ;;; Trigger the on-index handler (old key)
            (on-index false key)
            (rawget config key))
        :__newindex
          (fn [_self key value]
            ;;; Trigger the on-index handler (new key)
            (on-index true key value)
            (rawset config key value))
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

            ;;; Clear config
            (when clear
              (set config {}))

            ;;; If empty - give access to raw table
            ;;;           (for iterating)
            (when (vim.tbl_isempty opts)
              config))})

(setmetatable proxy proxy-mt)

{:config proxy}
