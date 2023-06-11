(var cache {})

(var on-index (fn [_new _key _value]))

(local proxy {})

(local proxy-mt
       {:__index
          (fn [_self key]
            ;;; Trigger the on-index handler (old key)
            (on-index false key)
            (rawget cache key))
        :__newindex
          (fn [_self key value]
            ;;; Trigger the on-index handler (new key)
            (on-index true key value)
            (rawset cache key value))
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

            ;;; Clear cache
            (when clear
              (set cache {}))

            ;;; If empty - give access to raw table
            ;;;           (for iterating)
            (when (vim.tbl_isempty opts)
              cache))})

(setmetatable proxy proxy-mt)

{:cache proxy}
