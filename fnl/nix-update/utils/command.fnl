(local uv (or vim.uv vim.loop))

;;; Define helper to run async commands using libuv
(fn call-command [{: cmd : args} callback]
  ;;; Define pipes
  (local stdout (uv.new_pipe))
  (local stderr (uv.new_pipe))

  ;;; Define options
  (local options {: args
                  :stdio [nil stdout stderr]})

  ;;; Declare handle
  (var handle nil)

  ;;; Define result (will be appended to by `on-read`)
  (var result {:stdout []
               :stderr []})

  ;;; Define on-exit handler
  (fn on-exit [_code _status]
    (each [_ pipe (ipairs [stdout stderr])]
      (uv.read_stop pipe)
      (uv.close pipe))
    (uv.close handle)
    (vim.schedule #(callback result)))

  ;;; Define on-read handlers (will append to `result`)
  (fn on-read [pipe]
    (fn [_status data]
      (when data
        (each [val (vim.gsplit data "\n")]
          (when (not= val "")
            (table.insert
              (. result pipe)
              val))))))

  ;;; Spawn command
  (set handle (uv.spawn cmd options on-exit))

  ;;; Start reading
  (uv.read_start stdout (on-read :stdout))
  (uv.read_start stderr (on-read :stderr))

  nil)

{: call-command}
