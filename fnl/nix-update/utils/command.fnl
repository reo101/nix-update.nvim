(fn split-output [output]
  (if (= output "")
      []
      (vim.split output "\n" {:plain true :trimempty true})))

;;; Run a command without owning pipes, handles, or scheduling details.
(fn call-command [{: cmd : args}]
  (local result
         (vim.async.await
           (fn [done]
             (vim.system
               (vim.list_extend [cmd] args)
               {:text true}
               (vim.schedule_wrap done)))))

  {:code result.code
   :stdout (split-output result.stdout)
   :stderr (split-output result.stderr)})

{: call-command}
