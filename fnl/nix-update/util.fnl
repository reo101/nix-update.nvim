(local uv vim.loop)

(fn any [p? tbl]
  (each [k v (pairs tbl)]
    (when (p? k v)
      (lua "return true")))
  false)

(fn all [p? tbl]
  (each [k v (pairs tbl)]
    (when (not (p? k v))
      (lua "return false")))
  true)

(fn map [f tbl]
  (collect [k v (pairs tbl)]
    (values k (f v))))

(fn imap [f seq]
  (icollect [_ v (ipairs seq)]
    (f v)))

(fn filter [p? tbl]
  (collect [k v (pairs tbl)]
    (when (p? k v)
      (values k v))))

(fn flatten [seq ?res]
  (var res (or ?res []))
  (if (vim.tbl_islist seq)
    (each [_ v (pairs seq)]
      (flatten v res))
    ;; else (atom)
    (tset res
          (+ (length res) 1)
          seq))
  res)

(fn find-child [p? it]
  (each [child ?name it]
    (when (p? child ?name)
      (lua "return child"))))

(fn find-children [p? it]
  (icollect [child ?name it]
    (when (p? child ?name)
      child)))

(fn has-keys [tbl keys]
  (all (fn [_ key]
         (any (fn [k _]
                (= k key))
              tbl))
       keys))

(fn concat-two [xs ys]
  (each [_ y (ipairs ys)]
    (table.insert xs y))
  xs)

;;; Define helper to run async commands using libuv
(fn call-command [{: cmd : args} callback]
  ;; Define pipes
  (local stdout (uv.new_pipe))

  ;; Define options
  (local options {: args
                  :stdio [nil stdout nil]})

  ;; Declare handle
  (var handle nil)

  ;; Define result (will be appended to by `on-read`)
  (var result {})

  ;; Define on-exit handler
  (local on-exit (fn [_status]
                   (uv.read_stop stdout)
                   (uv.close stdout)
                   (uv.close handle)
                   (vim.schedule #(callback result))))

  ;; Define on-read handler (will append to `result`)
  (local on-read (fn [_status data]
                   (when data
                     (local vals (vim.split data "\n"))
                     (each [_ val (ipairs vals)]
                       (when (not= val "")
                         (table.insert result val))))))

  ;; Spawn command
  (set handle (uv.spawn cmd options on-exit))

  ;; Start reading
  (uv.read_start stdout on-read)

  nil)

{: any
 : all
 : map
 : imap
 : filter
 : flatten
 : find-child
 : find-children
 : has-keys
 : concat-two
 : call-command}
