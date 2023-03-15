(let [{: build}  (require :hotpot.api.make)
      ;; NOTE: We'll force building every file each time
      ;; and raise an error if any files don't compile
      (oks errs) (build "./fnl" {:force?  true
                                 :atomic? true}
                        "./fnl/(.+)" (fn [p {: join-path}]
                                       (join-path :./lua p)))]
  ;; NOTE: You may have binds which print results from hotpot-eval-buffer,
  ;; so we return nil here instead of the results from build to avoid printing
  ;; all the oks and errs.
  ;; You may not need to do this if you're always going to use :Fnlfile
  (values nil))
