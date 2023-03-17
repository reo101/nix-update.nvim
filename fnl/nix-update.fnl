(local updaters (require "nix-update.updaters"))

;;; Define TS query for getting the fetchers
(local fetchers-query-string
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

;;; Calculate fetchers' names
(local fetchers-names
       (table.concat
         (icollect [fetcher _ (pairs updaters)]
           (string.format "\"%s\"" fetcher))
         " "))

;;; Define query for matching
(local fetchers-query
       (vim.treesitter.parse_query
         :nix
         (string.format fetchers-query-string
                        fetchers-names)))

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
                ;; lhs
                "attrpath"
                (vim.treesitter.get_node_text
                  binding-elem
                  bufnr)
                ;; rhs - string (BOTTOM)
                "string_expression"
                (icollect [binding-part _ (binding-elem:iter_children)]
                  (when (binding-part:named)
                    {:node  binding-part
                     :value (vim.treesitter.get_node_text
                              binding-part
                              bufnr)}))
                ;; rhs - variable (RECURSION)
                "variable_expression"
                [(vim.treesitter.get_node_text
                                 binding-elem
                                 bufnr)]))
       [attr [val]] (values attr val))))

  (let [binding (. bindings name)]
    (match (type binding)
      ;; Found on this level
      "table"
      binding
      ;; Missing/variable reference
      other
      (do
        ;; Find closest parent binding_set
        (var target (attrset:parent))
        (while (and (not= target nil)
                    (not= (target:type) "binding_set"))
          (set target (target:parent)))

        ;; If we find such an attrset
        (when (not= target nil)
          (match other
            ;; Recurse for referenced variable
            "string"
            (try-get-value bufnr target binding)
            ;; Recurse for original variable
            "nil"
            (try-get-value bufnr target name)))))))

;;; Get used fetchers in bufnr
(fn find-used-fetchers [bufnr]
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

  ;;; Find all used fetchers and store them
  (local found-fetchers
         ;; For each query match
         (icollect [_pattern matcher _metadata
                    (fetchers-query:iter_matches root bufnr 0 -1)]
           ;; Construct a table from ...
           (collect [id node
                     (pairs matcher)]
             (values
               (. fetchers-query :captures id)
               (match (. fetchers-query :captures id)
                 ;; ... the fetcher name ...
                 "_fname"
                 (vim.treesitter.get_node_text node bufnr)
                 ; {:name  (vim.treesitter.get_node_text node bufnr)
                 ;  :range (let [(start-row start-col end-row end-col)
                 ;               (vim.treesitter.get_node_range node bufnr)]
                 ;           {: start-row
                 ;            : start-col
                 ;            : end-row
                 ;            : end-col})}
                 ;; ... its arguments ...
                 "_fargs"
                 (collect [binding _ (node:iter_children)]
                  (match (icollect [binding-elem _ (binding:iter_children)]
                           (match (binding-elem:type)
                             ;; lhs
                             "attrpath"
                             (vim.treesitter.get_node_text binding-elem bufnr)))
                    [attr] (values attr (try-get-value bufnr node attr))))
                 ;; ... and the whole node
                 ;; (for checking whether the cursor is inside)
                 "_fwhole"
                 node)))))

  found-fetchers)

(fn get-fetcher-at-cursor [bufnr]
  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get found fetchers
  (local found-fetchers (find-used-fetchers bufnr))

  ;;; Get cursor position
  (local [_ cursor-row cursor-col _ _] (vim.fn.getcursorcharpos))

  ;;; (Try to) find a fetcher containing the cursor
  (each [_ fetcher (ipairs found-fetchers)]
    (when (vim.treesitter.is_in_node_range
            fetcher._fwhole
            cursor-row
            cursor-col)
      (lua "return fetcher"))))

(fn update-fetcher-at-cursor [bufnr]
  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get fetcher at cursor
  (local fetcher-at-cursor (get-fetcher-at-cursor bufnr))

  ;;; Early return if not found
  (when (= fetcher-at-cursor nil)
    (lua "return nil"))

  ;;; Get correct fetcher
  (local updater
         (. updaters fetcher-at-cursor._fname))

  (updater fetcher-at-cursor._fargs))

(fn nix-update [bufnr]
  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get found fetchers
  (local found-fetchers (find-used-fetchers bufnr))

  ;;; Create namespace for the extmarks
  (local namespace (vim.api.nvim_create_namespace "NixUpdate"))

  ;;; Clear old extmarks
  (vim.api.nvim_buf_clear_namespace bufnr namespace 0 -1)

  found-fetchers)

;;; Define command
(vim.api.nvim_create_user_command "NixUpdate" #(nix-update) {})

{:get_used_fetchers        find-used-fetchers
 :get_fetcher_at_cursor    get-fetcher-at-cursor
 :update_fetcher_at_cursor update-fetcher-at-cursor
 :nix_update               nix-update}
