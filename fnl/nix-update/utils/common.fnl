(fn find-child [node p?]
  (each [child ?name (node:iter_children)]
    (when (p? child ?name)
      (lua "return child"))))

(fn find-children [node p?]
  (icollect [child ?name (node:iter_children)]
    (when (p? child ?name)
      child)))

;;; Check which required keys are missing from tbl
;;; Supports:
;;;   :key          - required key (atom)
;;;   [:a :b]       - any of these (list)
;;; Returns list of missing requirements with error info
(fn missing-keys [tbl required-keys]
  (local tbl-keys
         (-> tbl
             pairs
             vim.iter
             (: :map (fn [k _] k))
             (: :totable)))
  (-> required-keys
      ipairs
      vim.iter
      (: :map
         (fn [_ key]
           (if
             ;; List = any of these must be present
             (vim.islist key)
             (let [found (-> key
                             ipairs
                             vim.iter
                             (: :any (fn [_ k] (vim.list_contains tbl-keys k))))]
               (when (not found)
                 {:any-of key}))
             ;; Atom = required key
             (not (vim.list_contains tbl-keys key))
             {:required key})))
      (: :totable)))

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
    (lua "return nil"))

  ;;; Early return if no node
  (when (not node)
    (vim.notify
      (string.format
        "No node given for getting coords"
        bufnr))
    (lua "return nil"))

  (let [(start-row start-col end-row end-col)
        (vim.treesitter.get_node_range node bufnr)]
    {: start-row
     : start-col
     : end-row
     : end-col}))

;;; Flatten nested arrays, treating dict-like tables as leaf nodes
;;; This is needed because vim.iter():flatten() requires all elements to be array-like
(fn flatten-fragments [tbl]
  (local result [])
  (fn recurse [t]
    (if (and (= (type t) :table)
             (vim.islist t))
        ;; Array-like: recurse into elements
        (each [_ v (ipairs t)]
          (recurse v))
        ;; Dict-like or non-table: treat as leaf
        (table.insert result t)))
  (recurse tbl)
  result)

{: find-child
 : find-children
 : missing-keys
 : coords
 : flatten-fragments}
