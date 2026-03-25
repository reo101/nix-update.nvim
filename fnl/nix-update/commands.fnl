(var registered? false)

(local subcommand-tbl
       {"prefetch"
         {:impl (fn [_args _opts]
                  (let [nix-update (require "nix-update")]
                    (nix-update.prefetch_fetch {})))}
        "buffer"
         {:impl (fn [_args _opts]
                  (let [nix-update (require "nix-update")]
                    (nix-update.prefetch_buffer {})))}
        "health"
         {:impl (fn [_args _opts]
                  (vim.cmd "checkhealth nix-update"))}
        "help"
         {:impl (fn [_args _opts]
                  (vim.cmd "help nix-update"))}})

(fn complete-subcommands [arg-lead]
  (-> subcommand-tbl
      vim.tbl_keys
      ipairs
      vim.iter
      (: :filter (fn [_ key]
                   (not= (string.find key arg-lead 1 true) nil)))
      (: :totable)))

(fn complete [arg-lead cmdline _]
  (let [matches [(string.match cmdline "^['<,'>]*NixUpdate[!]*%s(%S+)%s(.*)$")]
        subcmd-key (. matches 1)
        subcmd-arg-lead (. matches 2)]
    (local subcommand (?. subcommand-tbl subcmd-key))
    (local complete-fn (?. subcommand :complete))

    (if (and subcmd-key
             subcmd-arg-lead
             complete-fn)
      (complete-fn subcmd-arg-lead)
      (if (string.match cmdline "^['<,'>]*NixUpdate[!]*%s+%w*$")
        (complete-subcommands arg-lead)
        []))))

(fn run-command [opts]
  (local fargs (or opts.fargs []))
  (local subcommand-key (or (. fargs 1) "prefetch"))
  (local args (if (> (length fargs) 1)
                (vim.list_slice fargs 2 (length fargs))
                []))
  (local subcommand (?. subcommand-tbl subcommand-key))

  (when (not subcommand)
    (vim.notify
      (string.format "nix-update: unknown subcommand `%s`" subcommand-key)
      vim.log.levels.ERROR)
    (lua "return nil"))

  (subcommand.impl args opts))

(fn register []
  (when registered?
    (lua "return nil"))

  (vim.api.nvim_create_user_command "NixUpdate" run-command
    {:nargs "*"
     :desc "nix-update commands (prefetch, buffer, health, help)"
     :complete complete})

  ;; backwards-compatible alias for the old command behavior
  (vim.api.nvim_create_user_command "NixPrefetch"
    (fn [_]
      (let [nix-update (require "nix-update")]
        (nix-update.prefetch_buffer {})))
    {:desc "Prefetch all fetches in the current buffer"})

  (vim.keymap.set "n" "<Plug>(NixUpdatePrefetch)"
    (fn []
      (let [nix-update (require "nix-update")]
        (nix-update.prefetch_fetch {})))
    {:silent true
     :desc "Prefetch and update fetch at cursor"})

  (vim.keymap.set "n" "<Plug>(NixUpdatePrefetchBuffer)"
    (fn []
      (let [nix-update (require "nix-update")]
        (nix-update.prefetch_buffer {})))
    {:silent true
     :desc "Prefetch and update all fetches in buffer"})

  (set registered? true))

{: register}
