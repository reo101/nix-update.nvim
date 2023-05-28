(local {: gen-prefetcher-cmd
        : get-prefetcher-extractor}
       (require :nix-update.prefetchers))

(local {: imap
        : flatten
        : find-child
        : call-command}
       (require :nix-update.util))

(macro -m> [val ...]
  "Thread a value through a list of method calls"
  (assert-compile
    val
    "There should be an input value to the pipeline")
  (accumulate [res val
               _   [f & args] (ipairs [...])]
    `(: ,res ,f ,(unpack args))))

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
(local fetches-names
       (table.concat
         (icollect [fetch _ (pairs gen-prefetcher-cmd)]
           (string.format "\"%s\"" fetch))
         " "))

;;; Define query for matching
(local fetches-query
       (vim.treesitter.parse_query
         :nix
         (string.format fetches-query-string
                        fetches-names)))

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
;;; NOTE: `{: ?interp : name}` -> name of referenced variable
;;;       `{: ?interp : node : value}` -> node + value of found definition
;;;       `{: notfound}` -> not found
(fn find-all-local-bindings [bounder opts]
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

  ;;; Define map for storing the found bindings
  (local bindings {})
  (each [binding _ (bounder:iter_children)]
    (match (binding:type)
      ;;; Classic binding
      "binding"
      (let [attr        (find-child
                          #(= ($1:type) "attrpath")
                          binding)
            attr-name   (when attr
                          (vim.treesitter.get_node_text
                            attr
                            bufnr))
            string-expr (let [string-expression
                               (find-child
                                  #(= ($1:type) "string_expression")
                                  binding)]
                          (when string-expression
                            (icollect [node _ (string-expression:iter_children)]
                              (match (node:type)
                                ;;; Variable reference
                                "interpolation"
                                (let [expression
                                       (find-child
                                         #(and (= ($1:type) "variable_expression")
                                               (= $2 "expression"))
                                         node)]
                                  (when expression
                                    ;;; Mark for search up
                                    {:?interp node
                                     :name    (vim.treesitter.get_node_text
                                               expression
                                               bufnr)}))
                                ;;; Final value - string
                                "string_fragment"
                                {:node  node
                                 :value (vim.treesitter.get_node_text
                                          node
                                          bufnr)}))))
            var-expr   (let [variable-expression
                              (find-child
                                #(= ($1:type) "variable_expression")
                                binding)]
                         (when variable-expression
                           ;;; Mark for search up
                           [{:name (vim.treesitter.get_node_text
                                      variable-expression
                                      bufnr)}]))
            expr (or string-expr
                     var-expr)]
        (tset bindings attr-name expr))
      ;;; (Plain) inherit bindings
      "inherit"
      (let [attrs (find-child
                    #(and (= ($1:type) "inherited_attrs")
                          (= $2 "attrs"))
                    binding)]
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
(fn try-get-binding [bounder identifier opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr
          : depth
          : depth-limit}
         opts)

  ;;; Get current buffer
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

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
  (local recurse? (not= (-m> bounder
                             [:parent]
                             [:type])
                        "attrset_expression"))

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
    (var parent-bounder (-m> bounder
                             [:parent]
                             [:parent]))
    ;; (var parent-bounder (: (: bounder :parent) :parent))
    (while (and parent-bounder
                (not= (parent-bounder:type) "rec_attrset_expression")
                (not= (parent-bounder:type) "let_expression"))
      (set parent-bounder (parent-bounder:parent)))

    ;;; If found, step down into its binding_set
    (when parent-bounder
      (set parent-bounder
           (find-child
             #(= ($:type) "binding_set")
             parent-bounder)))

    parent-bounder)

  ;;; Find all local bindings
  (local bindings (find-all-local-bindings bounder {: bufnr}))

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
                    {: ?interp : name}
                    (let [parent-bounder (find-parent-bounder)
                          ;;; NOTE: `recurse?` matters here
                          next-bounder (if recurse?
                                           bounder
                                           parent-bounder)]
                      (if next-bounder
                        ;; Search upwards*
                        (let [resolved (try-get-binding
                                         next-bounder
                                         name
                                         {: bufnr
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
         (let [parent-bounder (find-parent-bounder)]
           (if parent-bounder
             ;; Search upwards
             (try-get-binding
               parent-bounder
               identifier
               {: bufnr
                :depth (+ depth 1)
                : depth-limit})
             ;; Nowhere to seach
             {:notfound identifier}))))

    ;; Return the (flattened) `fragment`s
    (flatten final-binding)))

;;; Concatinate all `fragment`s from a binding
(fn binding-to-value [binding]
  (var result "")
  (var notfounds [])

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
      {:bad notfounds}
      {:good result}))

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
         ;;; For each query match
         (icollect [_pattern matcher _metadata
                    (fetches-query:iter_matches root bufnr 0 -1)]
           ;;; Construct a table from ...
           (collect [id node
                     (pairs matcher)]
             (let [capture-id (. fetches-query :captures id)]
               (values
                 capture-id
                 (match capture-id
                   ;;; ... the fetch name ...
                   "_fname"
                   (vim.treesitter.get_node_text node bufnr)
                   ;;; ... its arguments ...
                   "_fargs"
                   (collect [name _
                             (pairs (find-all-local-bindings node {: bufnr}))]
                     (let [value (try-get-binding node name {: bufnr})]
                       (values name value)))
                   ;;; ... and the whole node
                   ;;; (for checking whether the cursor is inside of it)
                   "_fwhole"
                   node))))))

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

(fn prefetch-fetch-at-cursor [opts]
  ;;; Extract opts
  (local opts (or opts {}))
  (local {: bufnr}
         opts)

  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get fetch at cursor
  (local fetch-at-cursor (get-fetch-at-cursor {: bufnr}))

  ;;; Early return if not found
  (when (not fetch-at-cursor)
    (vim.notify "No fetch found at cursor")
    (lua "return"))

  ;;; Get correct prefetcher cmd generator
  (local prefetcher
         (?. gen-prefetcher-cmd fetch-at-cursor._fname))

  ;;; Early return if not found
  (when (not prefetcher)
    (vim.notify
      (string.format
        "No prefetcher '%s' found"
        fetch-at-cursor._fname))
    (lua "return nil"))

  ;;; Resolve and validate arguments' values
  (local argument-values
         (do
           (var argument-values {})
           (var notfounds-pairs [])

           ;;; Go through all fargs
           (each [farg-name farg-binding (pairs fetch-at-cursor._fargs)]
             (do
               (match (binding-to-value farg-binding)
                 ;;; It the value is resolved - set
                 {:good result}
                 (tset argument-values farg-name result)
                 ;;; If the value is not resolved - remember which and why
                 {:bad notfounds}
                 (table.insert notfounds-pairs {: farg-name
                                                : notfounds}))))

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
        fetch-at-cursor._fname))
    (lua "return"))

  ;;; Get correct prefetcher result extractor
  (local prefetcher-extractor
         (?. get-prefetcher-extractor fetch-at-cursor._fname))

  ;;; Early return if not found
  (when (not prefetcher-extractor)
    (vim.notify
      (string.format
        "No data extractor for the prefetcher '%s' found"
        fetch-at-cursor._fname))
    (lua "return"))

  ;;; Update the values of the new prefetched fields
  (fn sed [{: stdout : stderr}]
    (when (= (length stdout) 0)
      (vim.print stderr)
      (lua "return"))

    (fn coords [node]
      (let [(start-row start-col end-row end-col)
            (vim.treesitter.get_node_range node bufnr)]
        {: start-row
         : start-col
         : end-row
         : end-col}))

    (each [key new-value (pairs (prefetcher-extractor stdout))]
      (local existing (?. fetch-at-cursor :_fargs key))
      (if existing
          ;;; If already exists - update
          (do
            (var i-fragment  1)
            (var i-new-value 1)
            (var short-circuit? false)
            (while (and (not short-circuit?)
                       (<= i-new-value (length new-value)))
              (let [fragment                   (. existing i-fragment)
                    {:?interp fragment-?interp
                     :node    fragment-node
                     :value   fragment-value}  fragment]
                (if
                  ;;; TODO: handle unexpected ends
                  false
                  nil
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
                           (coords fragment-node))
                    (vim.api.nvim_buf_set_text
                      bufnr
                      start-row
                      start-col
                      end-row
                      end-col
                      [(string.sub new-value i-new-value)])
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
                    (local {: start-row : start-col} (coords (or fragment-?interp
                                                                 fragment-node)))
                    (local {: end-row : end-col} (coords (or last-fragment-?interp
                                                             last-fragment-node)))
                    (vim.api.nvim_buf_set_text
                      bufnr
                      start-row
                      start-col
                      end-row
                      end-col
                      [(string.sub new-value i-new-value)])
                    (set short-circuit? true))))))
          ;;; If not - insert it at the end
          (let [{: end-row} (coords fetch-at-cursor._fwhole)]
            (vim.api.nvim_buf_set_lines
              bufnr
              end-row
              end-row
              true
              [(string.format
                 "%s = \"%s\";"
                 key
                 new-value)])
            ;;; TODO:
            ;;; nvim_buf_set_mark
            ;;; nvim_win_set_cursor
            ;;; ==
            ;;; nvim_buf_get_mark
            ;;; nvim_win_set_cursor
            (vim.cmd
              (string.format
                "normal ma%sggj==`a"
                end-row)))))

    (vim.notify "Prefetch complete!"))

  ;;; Call the command (will see results through `sed`)
  (call-command prefetcher-cmd sed)

  ;;; Notify user that we are now waiting
  (vim.notify
    (string.format
      "Prefetch initiated, awaiting response...")))

{: fetches-query-string
 : fetches-names
 : fetches-query
 : get-root
 : find-all-local-bindings
 : try-get-binding
 : binding-to-value
 : find-used-fetches
 : get-fetch-at-cursor
 : prefetch-fetch-at-cursor}
