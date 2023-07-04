(fn any [p? tbl]
  (each [k v (pairs tbl)]
    (when (p? {: k : v})
      (lua "return true")))
  false)

(fn all [p? tbl]
  (each [k v (pairs tbl)]
    (when (not (p? {: k : v}))
      (lua "return false")))
  true)

(fn map [f tbl]
  (collect [k v (pairs tbl)]
    (values (f {: k : v}))))

(fn imap [f seq]
  (icollect [k v (ipairs seq)]
    (f {: k : v})))

(fn filter [p? seq]
  (icollect [k v (ipairs seq)]
    (when (p? {: k : v})
      v)))

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

(fn find-child [p? node]
  (each [child ?name (node:iter_children)]
    (when (p? child ?name)
      (lua "return child"))))

(fn find-children [p? node]
  (icollect [child ?name (node:iter_children)]
    (when (p? child ?name)
      child)))

(fn missing-keys [tbl keys]
  (filter (fn [{:v key}]
            (not
              (any (fn [{: k}]
                     (= k key))
                   tbl)))
          keys))

(fn concat-two [xs ys]
  (each [_ y (ipairs ys)]
    (table.insert xs y))
  xs)

(fn coords [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr
          : node}
         opts)

  ;;; Early return if no bufnr
  (when (not bufnr)
    (vim.notify
      (string.format
        "No bufnr given for getting coords"
        bufnr))
    (lua "return"))

  ;;; Early return if no node
  (when (not node)
    (vim.notify
      (string.format
        "No node given for getting coords"
        bufnr))
    (lua "return"))

  (let [(start-row start-col end-row end-col)
        (vim.treesitter.get_node_range node bufnr)]
    {: start-row
     : start-col
     : end-row
     : end-col}))

{: any
 : all
 : map
 : imap
 : filter
 : flatten
 : find-child
 : find-children
 : missing-keys
 : concat-two
 : coords}
