(local async vim.async)

(fn split-output [output]
  (if (= output "")
      []
      (vim.split output "\n" {:plain true :trimempty true})))

;;; Run a command without owning pipes, handles, or scheduling details.
(fn call-command [{: cmd : args}]
  (local result
         (async.await
           (fn [done]
             (vim.system
               (vim.list_extend [cmd] args)
               {:text true}
               done))))

  {:stdout (split-output result.stdout)
   :stderr (split-output result.stderr)})

{: call-command}
