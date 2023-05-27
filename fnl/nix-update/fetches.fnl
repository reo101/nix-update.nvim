(local {: gen-prefetcher-cmd
        : get-prefetcher-extractor}
       (require :nix-update.prefetchers))

(local {: map
        : imap
        : flatten
        : find-child
        : call-command}
       (require :nix-update.util))

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
      (attrset_expression
        (binding_set) @_fargs)
      ;; FIXME: make argument resolution work for a rec_attrset_expression
      ;;
      ;; [(attrset_expression
      ;;    (binding_set) @_fargs)
      ;;  (rec_attrset_expression
      ;;    (binding_set) @_fargs)]
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
(fn get-root [?bufnr]
  ;;; Get current buffer
  (local bufnr (or ?bufnr
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
(fn find-all-local-bindings [bounder ?bufnr]
  ;;; Get current buffer
  (local bufnr (or ?bufnr
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
                          (binding:iter_children))
            attr-name   (when attr
                          (vim.treesitter.get_node_text
                            attr
                            bufnr))
            string-expr (let [string-expression
                               (find-child
                                  #(= ($1:type) "string_expression")
                                  (binding:iter_children))]
                          (when string-expression
                            (icollect [node _ (string-expression:iter_children)]
                              (match (node:type)
                                ;;; Variable reference
                                "interpolation"
                                (let [expression
                                       (find-child
                                         #(and (= ($1:type) "variable_expression")
                                               (= $2 "expression"))
                                         (node:iter_children))]
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
                                (binding:iter_children))]
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
                    (binding:iter_children))]
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
(fn try-get-binding [bounder identifier ?bufnr]
  ;;; Get current buffer
  (local bufnr (or ?bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Early return if bounder is nil
  (when (not bounder)
    (lua "return nil"))

  ;;; Early return if not in a Nix file
  (when (not= (. vim :bo bufnr :filetype)
              :nix)
    (vim.notify_once "This is meant to be used with Nix files")
    (lua "return nil"))

  ;;; Find all local bindings
  (local bindings (find-all-local-bindings bounder bufnr))

  ;;; Evaluate all found local bindings
  (let [binding (. bindings identifier)]
    ;;; Find closest parent with a binding_set
    ;;; (immediate parent would short-circuit the loop)
    (var target (: (: bounder :parent) :parent))
    (while (and target
                (not= (target:type) "rec_attrset_expression")
                (not= (target:type) "let_expression"))
      (set target (target:parent)))

    ;;; If we find such a parent
    (when target
      ;;; Step down into its binding_set
      (set target
           (find-child
             #(= ($:type) "binding_set")
             (target:iter_children))))

    (local
      final-binding
      (if binding
         ;;; Table - Final value/Variable reference
         (let [find-up
                (fn [fragment]
                  (match fragment
                    ;;; Final value - Return
                    {: ?interp : node : value}
                    {: ?interp : node : value}
                    ;;; Variable reference - Recurse up for name
                    {: ?interp : name}
                    (let [resolved (flatten (try-get-binding target name bufnr))]
                      ;;; When no upper-level interpolation - keep old one
                      (each [i fragment (ipairs resolved)]
                        (when (not fragment.?interp)
                          (tset fragment :?interp ?interp)))
                      resolved)
                    ;;; Nil - Error (unhandled)
                    nil
                    nil))
               ;; BUG: might have `nil`s inside
               full-fragments
                (imap find-up binding)]
           full-fragments)
         ;;; Nil - Recurse up for same
        (try-get-binding target binding bufnr)))

    ;; Return the (flattened) `fragment`s
    (flatten final-binding)))

;;; Concatinate all `fragment`s from a binding
(fn binding-to-value [binding]
  (table.concat
    (imap
      #$.value
      binding)))

;;; Get used fetches in bufnr
(fn find-used-fetches [?bufnr]
  ;;; Get current buffer
  (local bufnr (or ?bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Early return if not in a Nix file
  (when (not= (. vim :bo bufnr :filetype)
              :nix)
    (vim.notify_once "This is meant to be used with Nix files")
    (lua "return nil"))

  ;;; Get the AST root
  (local root (get-root bufnr))

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
                             (pairs (find-all-local-bindings node bufnr))]
                     (let [value (try-get-binding node name bufnr)]
                       (values name value)))
                   ;;; ... and the whole node
                   ;;; (for checking whether the cursor is inside of it)
                   "_fwhole"
                   node))))))

  ;;; Return the accumulated fetches
  found-fetches)

(fn get-fetch-at-cursor [?bufnr]
  ;;; Get selected buffer (custom or current)
  (local bufnr (or ?bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get found fetches
  (local found-fetches (find-used-fetches bufnr))

  ;;; Get cursor position
  (local [_ cursor-row cursor-col _ _] (vim.fn.getcursorcharpos))

  ;;; (Try to) find a fetch containing the cursor
  (each [_ fetch (ipairs found-fetches)]
    (when (vim.treesitter.is_in_node_range
            fetch._fwhole
            cursor-row
            cursor-col)
      (lua "return fetch"))))

(fn prefetch-fetch-at-cursor [?bufnr]
  ;;; Get selected buffer (custom or current)
  (local bufnr (or ?bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get fetch at cursor
  (local fetch-at-cursor (get-fetch-at-cursor bufnr))

  ;;; Early return if not found
  (when (= fetch-at-cursor nil)
    (vim.notify "No fetch found at cursor")
    (lua "return"))

  ;;; Get correct prefetcher cmd generator
  (local prefetcher
         (?. gen-prefetcher-cmd fetch-at-cursor._fname))

  ;;; Early return if not found
  (when (= prefetcher nil)
    (vim.notify
      (string.format
        "No prefetcher '%s' found"
        fetch-at-cursor._fname))
    (lua "return"))

  ;;; Get the commands components
  (local prefetcher-cmd
         (prefetcher
           (map binding-to-value
                fetch-at-cursor._fargs)))

  ;;; Early return if invalid
  (when (= prefetcher-cmd nil)
    (vim.notify
      (string.format
        "Could not generate command for the prefetcher '%s'"
        fetch-at-cursor._fname))
    (lua "return"))

  ;;; Get correct prefetcher result extractor
  (local prefetcher-extractor
         (?. get-prefetcher-extractor fetch-at-cursor._fname))

  ;;; Early return if not found
  (when (= prefetcher-extractor nil)
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
          (let [(_start-row _start-col end-row _end-col)
                (vim.treesitter.get_node_range fetch-at-cursor._fwhole bufnr)]
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
