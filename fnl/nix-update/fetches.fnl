(local {: gen-prefetcher-cmd
        : get-prefetcher-extractor}
       (require :nix-update.prefetchers))

(local {: call-command}
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
(fn get-root [bufnr]
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

;;; Try finding bounded value
(fn try-get-value [bufnr attrset name]
  ;;; Get current buffer
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Early return if not in a Nix file
  (when (not= (. vim :bo bufnr :filetype)
              :nix)
    (vim.notify_once "This is meant to be used with Nix files")
    (lua "return nil"))

  (local
    bindings
    (collect [binding _ (attrset:iter_children)]
     (match (icollect [binding-elem _ (binding:iter_children)]
              (match (binding-elem:type)
                ;;; lhs
                "attrpath"
                (vim.treesitter.get_node_text
                  binding-elem
                  bufnr)
                ;;; rhs - string (BOTTOM)
                "string_expression"
                (icollect [binding-part _ (binding-elem:iter_children)]
                  (when (binding-part:named)
                    {:node  binding-part
                     :value (vim.treesitter.get_node_text
                              binding-part
                              bufnr)}))
                ;;; rhs - variable (RECURSION)
                "variable_expression"
                [(vim.treesitter.get_node_text
                                 binding-elem
                                 bufnr)]))
       [attr [val]] (values attr val))))

  (let [binding (. bindings name)]
    (match (type binding)
      ;;; Found on this level
      "table"
      binding
      ;;; Missing/variable reference
      other
      (do
        ;;; Find closest parent binding_set
        (var target (attrset:parent))
        (while (and (not= target nil)
                    (not= (target:type) "binding_set"))
          (set target (target:parent)))

        ;;; If we find such an attrset
        (when (not= target nil)
          (match other
            ;;; Recurse for referenced variable
            "string"
            (try-get-value bufnr target binding)
            ;;; Recurse for original variable
            "nil"
            (try-get-value bufnr target name)))))))

;;; Get used fetches in bufnr
(fn find-used-fetches [bufnr]
  ;;; Get current buffer
  (local bufnr (or bufnr
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
                 ; {:name  (vim.treesitter.get_node_text node bufnr)
                 ;  :range (let [(start-row start-col end-row end-col)
                 ;               (vim.treesitter.get_node_range node bufnr)]
                 ;           {: start-row
                 ;            : start-col
                 ;            : end-row
                 ;            : end-col})}
                 ;;; ... its arguments ...
                 "_fargs"
                 (collect [binding _ (node:iter_children)]
                  (match (icollect [binding-elem _ (binding:iter_children)]
                           (match (binding-elem:type)
                             ;;; lhs
                             "attrpath"
                             (vim.treesitter.get_node_text binding-elem bufnr)))
                    [attr] (values attr (try-get-value bufnr node attr))))
                 ;;; ... and the whole node
                 ;;; (for checking whether the cursor is inside)
                 "_fwhole"
                 node)))))

  found-fetches)

(fn get-fetch-at-cursor [bufnr]
  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
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

(fn prefetch-fetch-at-cursor [bufnr]
  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
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
        (let [(_start-row _start-col end-row _end-col)
              (vim.treesitter.get_node_range fetch-at-cursor._fwhole bufnr)]
          (vim.api.nvim_buf_set_lines
            bufnr
            end-row
            end-row
            true
            [(string.format
               "sha256 = \"%s\";"
               value)])
          (vim.cmd
            (string.format
              "normal ma%sggj==`a"
              end-row))))))

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
 : try-get-value
 : find-used-fetches
 : get-fetch-at-cursor 
 : prefetch-fetch-at-cursor}
