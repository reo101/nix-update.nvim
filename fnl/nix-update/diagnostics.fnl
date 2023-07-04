(local {: find-used-fetches
        : prefetch-fetch}
       (require :nix-update.fetches))

(local {: cache}
       (require :nix-update._cache))

(local {: coords
        : concat-two}
       (require "nix-update.utils"))

(fn set-diagnostic [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr
          : fetch
          : data
          : err}
         opts)

  ;;; Early return if no bufnr
  (when (not bufnr)
    (vim.notify
      (string.format
        "No bufnr given for setting extmark"
        bufnr))
    (lua "return"))

  ;;; Early return if no fetch
  (when (not fetch)
    (vim.notify
      (string.format
        "No fetch given for setting extmark"
        fetch))
    (lua "return"))

  ;;; Create namespace for the extmarks
  (local namespace (vim.api.nvim_create_namespace "NixUpdate"))

  (when (and err
             (= (length (or data [])) 0))
    (let [{: start-row
           : start-col}
          (coords {: bufnr :node fetch._fwhole})]
      (vim.diagnostic.set
        namespace
        bufnr
        [{:lnum start-row
          :col start-col
          :severity vim.diagnostic.severity.ERROR
          :message (vim.inspect err)
          :source :NixUpdate}]))
    (lua "return"))

  (local diagnostics
         (icollect [key value (pairs data)]
           (let [{: start-row
                  : start-col
                  : message
                  : severity}
                 (let [farg (. fetch._fargs key)]
                   (if farg
                     ;;; Existing field
                     (let [{: start-row : start-col}
                           (coords {: bufnr :node farg.binding})]
                       {: start-row
                        : start-col
                        :message (string.format
                                   "Update field \"%s\" to \"%s\""
                                   key
                                   value)
                        :severity vim.diagnostic.severity.HINT})
                     ;;; New field
                     (let [{: start-row : start-col}
                           (coords {: bufnr :node fetch._fwhole})]
                       {: start-row
                        : start-col
                        :message (string.format
                                   "Add new field \"%s\" with value \"%s\""
                                   key
                                   value)
                        :severity vim.diagnostic.severity.WARN})))]
             {:lnum start-row
              :col  start-col
              : severity
              : message
              :source :NixUpdate})))

  ;;; Update diagnostics
  (vim.diagnostic.set
    namespace
    bufnr
    ;;; NOTE: there should be no race condition here
    ;;;       since everything is run synchronously
    ;;;       on the event loop (`:help vim.schedule()`)
    (concat-two
      (vim.diagnostic.get
        nil
        {: namespace})
      diagnostics)))

(fn remove-diagnostic [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr}
         opts)

  ;; TODO: implement

  nil)

(fn NixPrefetch [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr}
         opts)

  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get found fetches
  (local found-fetches (find-used-fetches {: bufnr}))

  ;;; Create namespace for the diagnostics
  (local namespace (vim.api.nvim_create_namespace "NixPrefetch"))

  ;;; Clear old diagnostics
  ;; (vim.api.nvim_buf_clear_namespace bufnr namespace 0 -1)
  (vim.diagnostic.reset namespace bufnr)

  ;;; Clear cache
  (cache {:clear true})

  ;;; Populate cache (auto-populates diagnostics)
  ;;; TODO: signify which fetches are waiting
  (each [_ fetch (ipairs found-fetches)]
    (prefetch-fetch {: bufnr : fetch})))

;;; Define command
(vim.api.nvim_create_user_command "NixPrefetch" #(NixPrefetch) {})

{: set-diagnostic
 : remove-diagnostic}
