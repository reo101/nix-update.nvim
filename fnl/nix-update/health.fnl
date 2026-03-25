(local {: config}
       (require "nix-update._config"))

(local {: prefetchers}
       (require "nix-update.prefetchers"))

(local health
       (or vim.health
           (require "health")))

(fn report-start [msg]
  ((or health.start health.report_start) msg))

(fn report-ok [msg]
  ((or health.ok health.report_ok) msg))

(fn report-warn [msg]
  ((or health.warn health.report_warn) msg))

(fn report-error [msg]
  ((or health.error health.report_error) msg))

(local valid-update-actions
       {:apply true
        :flash true
        :notify true
        :preview true})

(fn collect-required-commands []
  (local required-cmds {})
  (each [_ prefetcher (pairs prefetchers)]
    (each [_ cmd (ipairs (or prefetcher.required-cmds []))]
      (tset required-cmds cmd true)))
  (each [_ prefetcher (pairs (or config.extra-prefetchers {}))]
    (each [_ cmd (ipairs (or prefetcher.required-cmds []))]
      (tset required-cmds cmd true)))
  (vim.tbl_keys required-cmds))

(fn check-config []
  (local invalid-actions
         (icollect [_ action (ipairs (or config.update-actions []))]
           (if (not (?. valid-update-actions action))
             action)))
  (if (> (length invalid-actions) 0)
    (report-error
      (string.format
        "Invalid `update-actions`: %s"
        (table.concat invalid-actions ", ")))
    (report-ok
      (string.format
        "Configured update actions: %s"
        (table.concat config.update-actions ", ")))))

(fn check-dependencies []
  (local missing-cmds
         (-> (collect-required-commands)
             ipairs
             vim.iter
             (: :filter (fn [_ cmd]
                          (= (vim.fn.executable cmd) 0)))
             (: :totable)))
  (if (> (length missing-cmds) 0)
    (report-warn
      (string.format "Missing commands: %s" (table.concat missing-cmds ", ")))
    (report-ok "All configured prefetcher commands are available")))

(fn check []
  (report-start "nix-update")
  (check-config)
  (check-dependencies))

{: check}
