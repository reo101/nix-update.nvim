(local {: prefetchers}
       (require :nix-update.prefetchers))

(local {: cache}
       (require :nix-update._cache))

(local {: config}
       (require :nix-update._config))

(local {: Result}
       (require :nix-update.utils.fp))

(local {: keys
        : imap
        : flatten
        : find-child
        : find-children
        : coords
        : call-command}
       (require :nix-update.utils))

;;; Define TS query for getting the fetches
(local fetches-query-string
       "
(
  (apply_expression
    function:
      [(variable_expression
         name: (identifier) @_fname)
       (select_expression
         attrpath:
           (attrpath
             attr: (identifier) @_fname
             .))]
    argument:
      [(attrset_expression
         (binding_set) @_fargs)
       (rec_attrset_expression
         (binding_set) @_fargs)]
  ) @_fwhole
  (#any-of? @_fname %s)
)
       ")

;;; Calculate fetches' names
(fn gen-fetches-names []
  (let [names []]
    (vim.list_extend names (keys prefetchers))
    (vim.list_extend names (keys ((?. config :extra-prefetchers))))
    (table.concat names " ")))

;;; Define query for matching
(fn gen-fetches-query []
  (vim.treesitter.query.parse
    :nix
    (string.format fetches-query-string
                   (gen-fetches-names))))

;;; Get AST root
(fn get-root [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr}
         opts)

  ;;; Get current buffer
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Early return if not in a Nix file
  (when (not= (. vim :bo bufnr :filetype)
              :nix)
    (vim.notify_once "This is meant to be used with Nix files")
    (lua "return nil"))

  (let [parser (vim.treesitter.get_parser bufnr :nix {})
        [tree] (parser:parse)]
    (tree:root)))

;;; Find all local bindings
;;; NOTE: `{: ?interp : name : ?from}` -> name of referenced variable 
;;;                                       (optionally from specific attrset)
;;;       `{: ?interp : node : value}` -> node + value of found definition
;;;       `{: notfound}`               -> not found
(fn find-all-local-bindings [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr
          : bounder}
         opts)

  ;;; Get current buffer
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Early return if there is no bounder
  (when (not bounder)
    (vim.notify "No bounder")
    (lua "return nil"))

  ;;; Early return if not in a Nix file
  (when (not= (. vim :bo bufnr :filetype)
              :nix)
    (vim.notify_once "This is meant to be used with Nix files")
    (lua "return nil"))

  ;;; Define map for storing the found bindings
  (local bindings {})
  (each [binding _ (bounder:iter_children)]
    (match (binding:type)
      ;;; Classic binding
      "binding"
      (let [attr        (find-child
                          binding
                          #(and (= ($1:type) "attrpath")
                                (= $2 "attrpath")))
            attr-name   (when attr
                          (vim.treesitter.get_node_text
                            attr
                            bufnr))
            ;; NOTE: special case, treat `true`/`false` as strings
            bool-expr   (let [bool-expr
                               (find-child
                                 binding
                                 #(and (= ($1:type) "variable_expression")
                                       (= $2 "expression")))]
                          (when bool-expr
                            (let [bool-expr-value (vim.treesitter.get_node_text bool-expr bufnr)]
                              (when (vim.list_contains [:true :false] bool-expr-value)
                                [{:node bool-expr
                                  :value bool-expr-value}]))))
            string-expr (let [string-expression
                               (find-child
                                 binding
                                 #(and (= ($1:type) "string_expression")
                                       (= $2 "expression")))]
                          (when string-expression
                            (if
                              (> (string-expression:named_child_count)
                                 0)
                              (icollect [node _ (string-expression:iter_children)]
                                (match (node:type)
                                  ;;; Variable reference
                                  "interpolation"
                                  (or ;; Either a classic variable
                                      (let [variable-expression
                                              (-?> node
                                                   (find-child
                                                     #(and (= ($1:type) "variable_expression")
                                                           (= $2 "expression"))))]
                                        (if variable-expression
                                          ;;; Mark for search up
                                          {:?interp node
                                           :name    (vim.treesitter.get_node_text
                                                      variable-expression
                                                      bufnr)}))
                                       ;; ... or variable attribute (`finalAttrs.attr`)
                                      (let [select-expression
                                              (-?> node
                                                   (find-child
                                                     #(and (= ($1:type) "select_expression")
                                                           (= $2 "expression"))))
                                            attrset-name
                                              (-?> select-expression
                                                   (find-child
                                                     #(and (= ($1:type) "variable_expression")
                                                           (= $2 "expression")))
                                                   (vim.treesitter.get_node_text bufnr))
                                            attr-name
                                              (-?> select-expression
                                                   (find-child
                                                     #(and (= ($1:type) "attrpath")
                                                           (= $2 "attrpath")))
                                                   (vim.treesitter.get_node_text bufnr))]
                                        (when (and attrset-name attr-name)
                                          ;;; Mark for search up
                                          {:?interp node
                                           :name attr-name
                                           :?from attrset-name})))
                                  ;;; Final value - string
                                  (where t (or (= t "string_fragment")
                                               (= t "escape_sequence")))
                                  {:node  node
                                   :value (vim.treesitter.get_node_text
                                            node
                                            bufnr)}))
                              ;; else (empty string)
                              (let [{: start-row : start-col}
                                    (coords {: bufnr :node string-expression})
                                    msg (string.format
                                          "Please don't leave empty strings (row %s, col %s)"
                                          (+ 1 start-row)
                                          (+ 1 start-col))]
                                ;;; TODO: better handling of empty strings
                                (vim.notify msg)
                                (error msg)))))
            var-expr   (let [variable-expression
                               (-?> binding
                                    (find-child
                                      #(and (= ($1:type) "variable_expression")
                                            (= $2 "expression"))))]
                         (if variable-expression
                           ;;; Mark for search up
                           [{:name (vim.treesitter.get_node_text
                                     variable-expression
                                     bufnr)}]))
            attr-expr  (let [select-expression
                               (-?> binding
                                    (find-child
                                      #(and (= ($1:type) "select_expression")
                                            (= $2 "expression"))))
                             attrset-name
                               (-?> select-expression
                                    (find-child
                                      #(and (= ($1:type) "variable_expression")
                                            (= $2 "expression")))
                                    (vim.treesitter.get_node_text bufnr))
                             attr-name
                               (-?> select-expression
                                    (find-child
                                      #(and (= ($1:type) "attrpath")
                                            (= $2 "attrpath")))
                                    (vim.treesitter.get_node_text bufnr))]
                         (when (and attrset-name attr-name)
                           ;;; Mark for search up
                           [{:name attr-name
                             :?from attrset-name}]))
            expr (or string-expr
                     bool-expr
                     var-expr
                     attr-expr)]
        (tset bindings attr-name expr))
      ;;; (Plain) inherit bindings
      "inherit"
      (let [attrs (find-child
                    binding
                    #(and (= ($1:type) "inherited_attrs")
                          (= $2 "attrs")))]
        (each [node node-name (attrs:iter_children)]
          (when (and (= (node:type) "identifier")
                     (= node-name "attr"))
            ;;; Set value to attribute name - to be found later
            (let [attr-name (vim.treesitter.get_node_text
                              node
                              bufnr)]
              ;;; NOTE: `inherit attr;` is the same as `attr = attr;`
              (tset bindings attr-name [{:name attr-name}])))))))

  ;;; Return the accumulated bindings
  bindings)

;;; Try finding bounded value
;;; TODO: optimize to work for many identifiers
(fn try-get-binding-value [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr
          : bounder
          : from
          : identifier
          : depth
          : depth-limit}
         opts)

  ;;; Get current buffer
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Early return if there is no bounder
  (when (not bounder)
    (vim.notify "No bounder")
    (lua "return nil"))

  ;;; Early return if there is no identifier
  (when (not identifier)
    (vim.notify "No identifier")
    (lua "return nil"))

  ;;; Set depth and early return if too deep
  (local depth (or depth 0))
  (local depth-limit (or depth-limit 16))
  (when (> depth depth-limit)
    (vim.notify
      (string.format
        "Hit the depth-limit of %s!"
        depth-limit))
    (lua "return nil"))

  ;;; NOTE: `false` <- `attrset_expression`
  ;;;       `true`  <- `let_expression` / `rec_attrset_expression`
  ;;;
  ;;; NOTE: we would want to recursing on the same level (bounder)
  ;;;       if we are on `let_expression` and `rec_attrset_expression`
  ;;;       because they are are recursive in nature
  ;;; NOTE: we also want to recurse on plain old `attrset_expression`
  ;;;       when it's right under a function (`finalAttrs` pattern)
  ;;;       but only for bindings having the same `from`
  ;;;       (all of this is handled down, not here, because second
  ;;;        `from` depends on the binding itself, it local by nature)
  (local recurse? (case (-> bounder
                            (: :parent)
                            (: :type))
                     (where (or "attrset_expression"))     false
                     (where (or "let_expression"
                                "rec_attrset_expression")) true))

  ;;; Early return if bounder is nil
  (when (not bounder)
    (lua "return nil"))

  ;;; Early return if not in a Nix file
  (when (not= (. vim :bo bufnr :filetype)
              :nix)
    (vim.notify_once "This is meant to be used with Nix files")
    (lua "return nil"))

  (fn find-parent-bounder []
    ;;; Find closest parent with a binding_set
    ;;; (immediate parent would short-circuit the loop)
    (var parent-bounder (-?> bounder
                             (: :parent)
                             (: :parent)))

    ;;; NOTE: Continue while we both:
    ;;; - have a `parent-bounder`
    ;;; - it is either:
    ;;;    - neither a:
    ;;;      - `rec_attrset_expression`
    ;;;      - `let_expression`
    ;;;    - or doesn't have a `binding_set`
    (while (and parent-bounder
                (or (and (not= (parent-bounder:type) "rec_attrset_expression")
                         (not= (parent-bounder:type) "let_expression")
                         (and (not= (parent-bounder:type) "attrset_expression")
                              (-?> (parent-bounder:parent)
                                   (: :type)
                                   (not= "function_expression"))))
                    (not (find-child
                           parent-bounder
                           #(= ($:type) "binding_set")))))
      (set parent-bounder (parent-bounder:parent)))

    ;;; If normal `attrset_expression`, annotate where it came from
    (var from nil)
    (var only-for nil)
    (when (-?> parent-bounder
               (: :parent)
               (: :type)
               (= "function_expression"))
      ;; NOTE: name of `config`-like attrset argument
      ;;       or `nil` if its destructured
      (local parent (parent-bounder:parent))
      ;; param: ...
      (local universal-parameter
             (-> parent
                 (find-child
                   #(and (= ($1:type) "identifier")
                         (= $2 "universal")))))
      ;; { a, b, c ? 5 }: ...
      ;; NOTE: formals with default values are ignored
      (local formals
             (-> parent
                 (find-child
                   #(and (= ($1:type) "formals")
                         (= $2 "formals")))
                 (find-children
                   #(and (= ($1:type) "formal")
                         (= $2 "formal")
                         (= (find-child $1 #(= $2 "default"))
                            nil)))
                 vim.iter
                 (: :map #(find-child $1 #(= $2 "name")))
                 (: :map #(vim.treesitter.get_node_text $ bufnr))
                 (: :totable)))
      (if (not= universal-parameter nil)
          ;; Found a universal parameter
          (set from (vim.treesitter.get_node_text universal-parameter bufnr))
          ;; else
          ;; Rely on found formals (can be empty)
          (set only-for formals)))

    ;;; If found, step down into its binding_set
    (when parent-bounder
      (set parent-bounder
           (find-child
             parent-bounder
             #(= ($:type) "binding_set"))))

    ;; NOTE: a `nil` `from` means that either we're not working
    ;;       with a `function_expression` binder or that we are
    ;;       but it doesn't have a `universal` parameter (catch-all)
    ;;       and instead does destructuring which store the bound attributes
    ;;       in `only-for` instead
    {: from
     : only-for
     : parent-bounder})

  ;;; Find all local bindings
  (local bindings (find-all-local-bindings {: bufnr : bounder}))

  ;;; Evaluate all found local bindings
  (let [binding (. bindings identifier)]
    (local
      final-binding
      (if binding
         ;;; Table - Final value/Variable reference
         (let [find-up
                (fn [{:v fragment}]
                  (match fragment
                    ;;; Final value - Return
                    {: ?interp : node : value}
                    {: ?interp : node : value}
                    ;;; Variable reference - Recurse for name
                    {: ?interp : name : ?from}
                    (let [{:from next-from
                           : only-for
                           : parent-bounder} (find-parent-bounder)
                          ;;; NOTE: `recurse?` matters here
                          next-bounder
                           (if (or recurse?
                                   ;; TODO: should this be here?
                                   (and ?from
                                        (= from ?from)))
                               bounder
                               ;; NOTE: not in destructured attrs
                               ;;       -> directly skip upwards
                               ;; TODO: somehow carry `only-for` as an arg
                               (and only-for
                                    (not (vim.tbl_contains
                                           only-for
                                           name)))
                               (-?> parent-bounder
                                    (: :parent)
                                    (: :parent))
                               ;; else
                               ;; NOTE: either in destructured attrs
                               ;;       or a non-recursive binder
                               parent-bounder)]
                      (if next-bounder
                        ;; Search upwards*
                        (let [resolved (try-get-binding-value
                                         {: bufnr
                                          :bounder next-bounder
                                          :from next-from
                                          :identifier name
                                          :depth (+ depth 1)
                                          : depth-limit})]
                          ;;; When no upper-level interpolation - keep old one
                          (each [_ fragment (ipairs resolved)]
                            (when (not fragment.?interp)
                              (tset fragment :?interp ?interp)))
                          resolved)
                        ;; Nowhere to search
                        {:notfound name}))
                    ;;; Not found - leave be
                    {: notfound}
                    {: notfound}))
               ;; NOTE: might have `notfound`s inside
               full-fragments
                (imap find-up binding)]
           full-fragments)
         ;;; Not found on this level - Recurse up for same
         ;;; NOTE: unlike with variable reference
         ;;;       here we just recurse upwards
         (let [{: parent-bounder : from} (find-parent-bounder)]
           (if parent-bounder
             ;; Search upwards
             (try-get-binding-value
               {: bufnr
                :bounder parent-bounder
                : from
                : identifier
                :depth (+ depth 1)
                : depth-limit})
             ;; Nowhere to seach
             {:notfound identifier}))))

    ;; Return the (flattened) `fragment`s
    (flatten final-binding)))

(fn try-get-binding-bounder [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr
          : node
          : name}
         opts)

  ;;; Early return if there is no bufnr
  (when (not bufnr)
    (vim.notify "No bufnr")
    (lua "return nil"))

  ;;; Early return if there is no node
  (when (not node)
    (vim.notify "No node")
    (lua "return nil"))

  ;;; Early return if there is no name
  (when (not name)
    (vim.notify "No name")
    (lua "return nil"))

  ;;; Find binding(s)
  (local
    bindings
    (icollect [binding _ (node:iter_children)]
      (match (binding:type)
        ;;; Classic binding
        "binding"
        (let [attr      (find-child
                          binding
                          #(= ($1:type) "attrpath"))
              attr-name (when attr
                          (vim.treesitter.get_node_text
                            attr
                            bufnr))]
          (when (= attr-name name)
            binding))
        ;;; (Plain) inherit bindings
        "inherit"
        (let [attrs (find-child
                      binding
                      #(and (= ($1:type) "inherited_attrs")
                            (= $2 "attrs")))
              attr  (find-child
                      attrs
                      #(and (= ($1:type) "identifier")
                            (= $2 "attr")
                            (= (vim.treesitter.get_node_text
                                 $1
                                 bufnr)
                               name)))]
          attr))))

  (. bindings 1))

;;; Concatinate all `fragment`s from a binding
(fn fragments-to-value [binding]
  (var result "")
  (local notfounds [])

  (each [_ fragment (ipairs binding)]
    (do
      (match fragment
        ;;; Resolved
        {: value}
        (set result (.. result value))
        ;;; Unresolved
        {: notfound}
        (table.insert notfounds notfound))))

  (if (> (length notfounds) 0)
      (Result.err notfounds)
      (Result.ok result)))

;;; Get used fetches in bufnr
(fn find-used-fetches [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr}
         opts)

  ;;; Get current buffer
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Early return if not in a Nix file
  (when (not= (. vim :bo bufnr :filetype)
              :nix)
    (vim.notify_once "This is meant to be used with Nix files")
    (lua "return nil"))

  ;;; Get the AST root
  (local root (get-root {: bufnr}))

  ;;; Find all used fetches and store them
  (local found-fetches
         (let [fetches-query (gen-fetches-query)]
           ;;; For each query match
           (icollect [_pattern matcher _metadata
                      (fetches-query:iter_matches
                        root
                        bufnr
                        0
                        -1
                        ;; NOTE: stable `nvim` compatability
                        {:all true})]
             ;;; Construct a table from ...
             (do
               (local res {})
               (each [id nodes (pairs matcher)]
                 (collect [_ node (ipairs nodes) &into res]
                   (let [capture-id (. fetches-query :captures id)]
                     (values
                       capture-id
                       (match capture-id
                         ;;; ... the fetch name ...
                         "_fname"
                         (vim.treesitter.get_node_text node bufnr)
                         ;;; ... its arguments ...
                         "_fargs"
                         (collect [name _ (-> {: bufnr
                                               :bounder node}
                                              find-all-local-bindings
                                              pairs)]
                           (let [binding (try-get-binding-bounder
                                           {: bufnr
                                            : node
                                            : name})
                                 fragments (try-get-binding-value
                                             {: bufnr
                                              :bounder node
                                              :identifier name})]
                             (values name {: binding
                                           : fragments})))
                         ;;; ... and the whole node
                         ;;; (for checking whether the cursor is inside of it)
                         "_fwhole"
                         node)))))
               res))))

  ;;; Return the accumulated fetches
  found-fetches)

(fn get-fetch-at-cursor [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr}
         opts)

  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get found fetches
  (local found-fetches (find-used-fetches {: bufnr}))

  ;;; Get cursor position
  (local [_ cursor-row cursor-col _ _] (vim.fn.getcursorcharpos))

  ;;; (Try to) find a fetch containing the cursor
  (each [_ fetch (ipairs found-fetches)]
    (when (vim.treesitter.is_in_node_range
            fetch._fwhole
            cursor-row
            cursor-col)
      (lua "return fetch"))))

;;; Calculate the text updates for one KV pair
(fn calculate-updates [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr
          : fetch
          : new-data}
         opts)

  (local updates [])
  (each [key new-value (pairs new-data)]
    (local existing (?. fetch :_fargs key :fragments))
    (if existing
      ;;; If already exists - update
      (do
        (var i-fragment  1)
        (var i-new-value 1)
        (var short-circuit? false)
        (while (and (not short-circuit?)
                    (<= i-new-value (length new-value)))
          (let [fragment (. existing i-fragment)
                {:node    fragment-node
                 :value   fragment-value
                 :?interp fragment-?interp} fragment]
            (if
              ;;; TODO: handle unexpected ends
              false
              (values nil nil)
              ;;; If fragment is same - leave alone
              (= (string.sub new-value
                             i-new-value
                             (+ i-new-value
                                (length fragment-value)
                                -1))
                 fragment-value)
              (do
                (set i-fragment  (+ i-fragment  1))
                (set i-new-value (+ i-new-value (length fragment-value))))
              ;;; If on last fragment - update it
              (= i-fragment (length existing))
              (do
                (local {: start-row : start-col : end-row : end-col}
                       (coords {: bufnr :node fragment-node}))
                (table.insert
                  updates
                  {:type :old
                   :data {: bufnr
                          : start-row
                          : start-col
                          : end-row
                          : end-col
                          :replacement [(string.sub new-value i-new-value)]}})
                (set short-circuit? true))
              ;;; If neither - nuke
              (do
                ;;; TODO: collect all discarded interpolated fragments
                ;;;       and report to the user that they are invalidated
                (local last-fragment
                       (. existing (length existing)))
                (local {:?interp last-fragment-?interp
                        :node    last-fragment-node}
                       last-fragment)
                (local {: start-row : start-col}
                       (coords {: bufnr
                                :node (or fragment-?interp
                                          fragment-node)}))
                (local {: end-row : end-col}
                       (coords {: bufnr
                                :node (or last-fragment-?interp
                                          last-fragment-node)}))
                (table.insert
                  updates
                  {:type :old
                   :data {: bufnr
                          : start-row
                          : start-col
                          : end-row
                          : end-col
                          :replacement [(string.sub new-value i-new-value)]}})
                (set short-circuit? true))))))
      ;;; If not - insert it at the end
      (let [{: end-row : end-col} (coords {: bufnr :node fetch._fwhole})]
        (table.insert
          updates
          {:type :new
           :data {: bufnr
                  :start end-row
                  :end end-row
                  :replacement [(string.format
                                  "%s%s = \"%s\";"
                                  ;;; Offset
                                  (vim.fn.repeat
                                    " "
                                    (+ (- end-col 1)
                                       (. vim :bo bufnr :shiftwidth)))
                                  key
                                  new-value)]}}))))

  ;;; Return calculated updates
  updates)

;;; Preview update
(fn preview-update [update]
  ;;; Create namespace for the extmarks
  (local namespace (vim.api.nvim_create_namespace "NixUpdate"))

  (match update
    {:type :old
     :data {: bufnr
            : start-row
            : start-col
            : end-row
            : end-col
            : replacement}}
    (vim.api.nvim_buf_set_extmark
      bufnr
      namespace
      start-row
      start-col
      {:end_row end-row
       :end_col end-col
       :hl_mode :replace
       :virt_text
        (icollect [_ line (ipairs replacement)]
          [line :DiffAdd])
       :virt_text_pos :overlay})
    {:type :new
     :data {: bufnr
            : start
            : replacement}}
    (vim.api.nvim_buf_set_extmark
      bufnr
      namespace
      start
      0
      {:virt_lines
        (icollect [_ line (ipairs replacement)]
          [[line :DiffAdd]])
       :virt_lines_above true})))

;;; Apply update to buffer
(fn apply-update [update]
  (match update
    {:type :old
     :data {: bufnr
            : start-row
            : start-col
            : end-row
            : end-col
            : replacement}}
    (vim.api.nvim_buf_set_text
      bufnr
      start-row
      start-col
      end-row
      end-col
      replacement)
    {:type :new
     :data {: bufnr
            : start
            : end
            : replacement}}
    (vim.api.nvim_buf_set_lines
      bufnr
      start
      end
      true
      replacement)))

;;; Prefetch given fetch
;;; store its results in the global state table
(fn prefetch-fetch [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr
          : fetch}
         opts)

  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get selected fetch (cursor or at cursor)
  (local fetch (or fetch
                   (get-fetch-at-cursor {: bufnr})))

  ;; ;;; Early return if there is no callback
  ;; (when (not= (type callback) :function)
  ;;   (vim.notify "Callback is not a function")
  ;;   (lua "return nil"))

  ;;; Early return if there is no fetch
  (when (not fetch)
    (vim.notify "No fetch (neither given nor one at cursor)")
    (lua "return nil"))

  ;;; Get correct prefetcher cmd generator
  (local prefetcher
         ;;; NOTE: referencing user-defined cmds
         (or (?. config :extra-prefetchers fetch._fname)
             (?. prefetchers               fetch._fname)))

  ;;; Early return if not found
  (when (not prefetcher)
    (vim.notify
      (string.format
        "No prefetcher '%s' found"
        fetch._fname))
    (lua "return nil"))

  ;;; Resolve and validate arguments' values
  (local argument-values
         (do
           (local argument-values {})
           (local notfounds-pairs [])

           ;;; Go through all fargs
           (each [farg-name farg-binding (pairs fetch._fargs)]
             (do
               (Result.bimap (fragments-to-value farg-binding.fragments)
                 ;;; It the value is resolved - set
                 (fn [result]
                   (tset argument-values farg-name result))
                 ;;; If the value is not resolved - remember which and why
                 (fn [notfounds]
                   (table.insert notfounds-pairs {: farg-name
                                                  : notfounds})))))

           ;;; For each unresolved value - report which and why
           (each [_ {: farg-name : notfounds} (ipairs notfounds-pairs)]
             (vim.notify
               (string.format
                 "Identifiers %s not found while evaluating %s!"
                 (vim.inspect notfounds)
                 farg-name)))

           ;;; If any values were unresolved - abort
           (when (> (length notfounds-pairs) 0)
             (lua "return nil"))

           ;;; Return the accumulated values
           argument-values))

  ;;; Get the commands components
  (local prefetcher-cmd
         (prefetcher argument-values))

  ;;; Early return if invalid
  (when (not prefetcher-cmd)
    (vim.notify
      (string.format
        "Could not generate command for the prefetcher '%s'"
        fetch._fname))
    (lua "return nil"))

  ;;; Call the command (will see results through `sed`)
  (call-command
    prefetcher-cmd
    (fn [{: stdout : stderr}]
      (when (= (length stdout) 0)
        (tset
          cache
          fetch._fwhole
          {: bufnr
           : fetch
           :err (string.format
                  "Oopsie: %s"
                  (vim.inspect
                    stderr))})
        (lua "return nil"))
      ;;; Cache the prefetched data
      (tset
        cache
        fetch._fwhole
        {: bufnr
         : fetch
         :data (prefetcher.extractor stdout)})))

  ;;; Notify user that we are now waiting
  (vim.notify
    (string.format
      "Prefetch initiated, awaiting response...")))

{: fetches-query-string
 : gen-fetches-names
 : gen-fetches-query
 : get-root
 : find-all-local-bindings
 : try-get-binding-value
 : fragments-to-value
 : find-used-fetches
 : get-fetch-at-cursor
 : calculate-updates
 : preview-update
 : apply-update
 : prefetch-fetch}
