(local {: missing-keys
        : filter}
       (require "nix-update.utils.common"))

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

(local
  prefetcher-mt
  {:__call
   (fn [self args]
     ;;; Check for missing keys
     (when self.required-keys
       (let [missing (missing-keys args self.required-keys)]
         (when (> (length missing) 0)
           (vim.notify
             (string.format
               "Missing keys: %s"
               (vim.inspect
                 missing)))
           (lua "return nil"))))

     ;;; Check for missing cmds
     (when self.required-cmds
       (let [missing (filter #(= (vim.fn.executable $.v) 0) self.required-cmds)]
         (when (> (length missing) 0)
           (vim.notify
             (string.format
               "Missing commands: %s"
               (vim.inspect
                 missing)))
           (lua "return nil"))))

     ;;; Finally, safely call the prefetcher function
     (self.prefetcher args))})

{: create-proxied
 : prefetcher-mt}
