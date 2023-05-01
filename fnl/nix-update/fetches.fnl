(local {: gen-prefetcher-cmd
        : get-prefetcher-extractor}
       (require :nix-update.prefetchers))

(local {: find-child
        : find-children
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
;;; NOTE: `string` -> name of referenced variable
;;;       `table` -> node + value of found definition
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
      (let [attr       (find-child
                         #(= ($1:type) "attrpath")
                         (binding:iter_children))
            attr-name  (when attr
                         (vim.treesitter.get_node_text
                           attr
                           bufnr))
            string-val (let [string-expression
                              (find-child
                                #(= ($1:type) "string_expression")
                                (binding:iter_children))]
                         ;;; TODO: iterate through all children:
                         ;;;       - string_fragment -> direct
                         ;;;       - interpolation -> indirecly
                         (when string-expression
                           (let [string-fragment
                                  (find-child
                                    #(= ($1:type) "string_fragment")
                                    (string-expression:iter_children))]
                             (when string-fragment
                               {:node  string-fragment
                                :value (vim.treesitter.get_node_text
                                         string-fragment
                                         bufnr)}))))
            var-val    (let [variable-expression
                              (find-child
                                #(= ($1:type) "variable_expression")
                                (binding:iter_children))]
                         (when variable-expression
                           (vim.treesitter.get_node_text
                             variable-expression
                             bufnr)))
            val (or string-val var-val)]
        (tset bindings attr-name val))
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
              (tset bindings attr-name attr-name)))))))

  ;;; Return the accumulated bindings
  bindings)

;;; Try finding bounded value
(fn try-get-value [bounder name ?bufnr]
  ;;; Get current buffer
  (local bufnr (or ?bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Early return if not in a Nix file
  (when (not= (. vim :bo bufnr :filetype)
              :nix)
    (vim.notify_once "This is meant to be used with Nix files")
    (lua "return nil"))

  ;;; Find all local bindings
  (local bindings (find-all-local-bindings bounder bufnr))

  ;;; Evaluate all found local bindings
  (let [binding (. bindings name)]
    (match (type binding)
      ;;; Found on this level - Done
      "table"
      binding
      ;;; Missing/variable reference - Recurse up
      other
      (do
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
                 (target:iter_children)))

          ;;; Check out what we are looking for
          (match other
            ;;; Recurse for directly referenced variable
            "string"
            (try-get-value target binding bufnr)
            ;;; Recurse for original variable
            "nil"
            (try-get-value target name bufnr)))))))

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
             (values
               (. fetches-query :captures id)
               (match (. fetches-query :captures id)
                 ;;; ... the fetch name ...
                 "_fname"
                 (vim.treesitter.get_node_text node bufnr)
                 ;;; ... its arguments ...
                 "_fargs"
                 (collect [name value (pairs (find-all-local-bindings node bufnr))]
                   (match (type value)
                     ;;; If found locally - use directly
                     "table"
                     (values name value)
                     ;;; If not - start recursing
                     "string"
                     (let [value (try-get-value node name bufnr)]
                       (when value
                         (values name value)))))
                 ;;; ... and the whole node
                 ;;; (for checking whether the cursor is inside of it)
                 "_fwhole"
                 node)))))

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
         (prefetcher fetch-at-cursor._fargs))

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
  (fn sed [res]
    (each [key value (pairs (prefetcher-extractor res))]
      (local node (?. fetch-at-cursor :_fargs key :node))
      ;;; If if there's already such a node - update it
      (if node
        (let [(start-row start-col end-row end-col)
              (vim.treesitter.get_node_range node bufnr)]
          (vim.api.nvim_buf_set_text
            bufnr
            start-row
            start-col
            end-row
            end-col
            [value]))
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
               value)])
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
 : try-get-value
 : find-used-fetches
 : get-fetch-at-cursor
 : prefetch-fetch-at-cursor}
