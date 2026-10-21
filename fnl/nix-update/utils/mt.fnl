(local {: missing-keys}
       (require "nix-update.utils.common"))

(local {: call-command}
       (require "nix-update.utils.command"))

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

;;; Format a missing key error for display
(fn format-missing-key [m]
  (match m
    {:any-of keys} (string.format "one of: %s" (table.concat keys ", "))
    {:required key} key
    _ (vim.inspect m)))

(local
  prefetcher-mt
  {:__call
   (fn [self args]
     (vim.async.run
       (fn []
         (when self.required-keys
           (let [missing (missing-keys args self.required-keys)]
             (when (> (length missing) 0)
               (local formatted
                      (-> missing
                          vim.iter
                          (: :map format-missing-key)
                          (: :totable)))
               (error (string.format "Missing keys: %s"
                                     (table.concat formatted "; "))))))

         (when self.required-cmds
           (let [missing (-> self.required-cmds
                             vim.iter
                             (: :filter #(= (vim.fn.executable $) 0))
                             (: :totable))]
             (when (> (length missing) 0)
               (error (string.format "Missing commands: %s"
                                     (table.concat missing ", "))))))

         (local {: code : stdout : stderr}
                (call-command (self.prefetcher args)))
         (when (not= code 0)
           (error (string.format "Prefetch command exited with code %d: %s"
                                 code
                                 (table.concat stderr "\n"))))
         (self.extractor stdout))))})

{: create-proxied
 : prefetcher-mt}
