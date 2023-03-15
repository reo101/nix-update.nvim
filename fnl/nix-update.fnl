(local fetchers (require "nix-update.fetchers"))

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
  )
  (#any-of? @_fname %s)
)
       ")

;;; Calculate fetchers' names
(local fetchers-names
       (table.concat
         (icollect [fetcher _ (pairs fetchers)]
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
  (let [parser (vim.treesitter.get_parser bufnr :nix {})
        [tree] (parser:parse)]
    (tree:root)))

;;; Get used fetchers in bufnr
(fn get-used-fetchers [bufnr]
  ;;; Get current buffer
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Early return if not in a Nix file
  (when (not= (. vim :bo bufnr :filetype)
              :nix)
    (vim.notify "This is meant to be used with Nix files")
    (lua "return"))

  ;;; Get the AST root
  (local root (get-root bufnr))

  ;;; Find all called fetchers and store them
  (local called-fetchers
         (icollect [_pattern matcher _metadata
                    (fetchers-query:iter_matches root bufnr 0 -1)]
           (collect [id node
                     (pairs matcher)]
             (values
               (. fetchers-query :captures id)
               (match (. fetchers-query :captures id)
                 "_fname"
                 {:name  (vim.treesitter.get_node_text node bufnr)
                  :range (let [(start-row start-col end-row end-col)
                               (vim.treesitter.get_node_range node bufnr)]
                           {: start-row
                            : start-col
                            : end-row
                            : end-col})}
                 "_fargs"
                 (collect [binding-node _ (node:iter_children)]
                   (match (icollect [binding _ (binding-node:iter_children)]
                            (match (binding:type)
                              "attrpath"
                              (vim.treesitter.get_node_text binding bufnr)
                              "string_expression"
                              (icollect [binding-part _ (binding:iter_children)]
                                (when (binding-part:named)
                                  {:node  binding-part
                                   :value (vim.treesitter.get_node_text binding-part bufnr)}))))
                     [attr [val]] (values attr val))))))))

  called-fetchers)

(fn nix-update [bufnr]
  ;;; Get selected buffer (custom or current)
  (local bufnr (or bufnr
                   (vim.api.nvim_get_current_buf)))

  ;;; Get used fetchers
  (local used-fetchers (get-used-fetchers bufnr))

  ;;; Create namespace for the extmarks
  (local namespace (vim.api.nvim_create_namespace "NixUpdate"))

  ;;; Clear old extmarks
  (vim.api.nvim_buf_clear_namespace bufnr namespace 0 -1)

  used-fetchers)

;;; Define command
(vim.api.nvim_create_user_command "NixUpdate" #(nix-update) {})

{:get_used_fetchers get-used-fetchers
 :nix_update        nix-update}
