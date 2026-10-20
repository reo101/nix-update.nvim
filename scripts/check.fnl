(fn fail [msg]
  (error (.. "[check] " msg)))

(fn assert-truthy [value msg]
  (when (not value)
    (fail msg)))

(assert-truthy (and vim.async vim.async.run vim.async.await)
               "vim.async is required for checks")

(tset vim.g :nix_update
      {:update_actions [:preview :notify]})

(local nix-update (require :nix-update))
(local fp (require :nix-update.utils.fp))
(nix-update.init)

(assert-truthy (= (fp.Option.unwrap (fp.Option.pure "value"))
                  "value")
               "Option.pure did not construct Some")
(assert-truthy (= (fp.Result.unwrap (fp.Result.pure "value"))
                  "value")
               "Result.pure did not construct Ok")
(assert-truthy
  (= (fp.Result.unwrap
       (fp.Result.validate
         (fp.Result.ok 1)
         (fn [value] (= value 1))
         "wrong value"))
     1)
  "Result.validate did not preserve Ok")
(assert-truthy
  (fp.Result.err?
    (fp.Result.validate
      (fp.Result.ok 1)
      (fn [_] false)
      "wrong value"))
  "Result.validate did not construct Err")

(assert-truthy (= (?. nix-update.config :update-actions 1)
                  :preview)
               "vim.g.nix_update did not apply")

(nix-update.setup {:update_actions [:apply :notify]})
(assert-truthy (= (?. nix-update.config :update-actions 1)
                  :apply)
               "setup overrides did not apply")

(local {: call-command} (require :nix-update.utils))
(local command-task
       (vim.async.run
         #(let [{: stdout}
                (call-command {:cmd "printf"
                               :args ["async-ok\\n"]})]
            (assert-truthy (= (table.concat stdout) "async-ok")
                           "vim.async command prefetch did not finish")
            (assert-truthy (not (vim.in_fast_event))
                           "command completion resumed in a fast event"))))
(command-task:wait 1000)

(local {: prefetcher-mt} (require :nix-update.utils))
(let [original-notify vim.notify
      notifications []]
  (var called? false)
  (local prefetcher
         (setmetatable
           {:required-cmds ["nix-update-nonexistent-prefetch-command"]
            :prefetcher (fn [_] (set called? true))}
           prefetcher-mt))
  (set vim.notify #(table.insert notifications $1))
  (let [(ok result) (pcall prefetcher {})]
    (set vim.notify original-notify)
    (assert-truthy ok "missing command validation raised an error")
    (assert-truthy (= result nil) "missing command validation did not abort")
    (assert-truthy (not called?) "prefetcher ran without its required command")
    (assert-truthy (= (. notifications 1)
                      "Missing commands: nix-update-nonexistent-prefetch-command")
                   "missing command diagnostic is incorrect")))

(let [expected {:cmd vim.v.progpath :args []}
      prefetcher (setmetatable
                   {:required-cmds [vim.v.progpath]
                    :prefetcher (fn [_] expected)}
                   prefetcher-mt)]
  (assert-truthy (= (prefetcher {}) expected)
                 "available command validation blocked the prefetcher"))

(local commands (require :nix-update.commands))
(commands.register)
(assert-truthy (= (vim.fn.exists ":NixUpdate") 2)
               ":NixUpdate command is missing")
(assert-truthy (= (vim.fn.exists ":NixPrefetch") 2)
               ":NixPrefetch command is missing")
(assert-truthy (not= (vim.fn.maparg "<Plug>(NixUpdatePrefetch)" :n) "")
               "prefetch <Plug> map is missing")
(assert-truthy (not= (vim.fn.maparg "<Plug>(NixUpdatePrefetchBuffer)" :n) "")
               "prefetch-buffer <Plug> map is missing")

(local nix-parser vim.env.NIX_UPDATE_NIX_PARSER)

(when nix-parser
  (assert-truthy (vim.uv.fs_stat nix-parser) "Nix parser is missing")
  (vim.treesitter.language.add :nix {:path nix-parser})

  (fn assert-fetch-values [label source expected]
    (local bufnr (vim.api.nvim_create_buf false true))
    (tset vim.bo bufnr :filetype :nix)
    (vim.api.nvim_buf_set_lines
      bufnr
      0
      -1
      false
      (vim.split source "\n" {:plain true}))

    (local fetches (require :nix-update.fetches))
    (local found (fetches.find-used-fetches {:bufnr bufnr}))
    (assert-truthy (and found (. found 1))
                   (.. label ": fetch was not found"))

    (each [key value (pairs expected)]
      (local arg (?. (. found 1) :_fargs key))
      (assert-truthy arg (.. label ": missing " key))
      (local parts [])
      (each [_ fragment (ipairs arg.fragments)]
        (assert-truthy fragment.value
                       (.. label ": unresolved " key))
        (table.insert parts fragment.value))
      (assert-truthy (= (table.concat parts) value)
                     (.. label ": wrong " key))))

  (assert-fetch-values "numeric literal"
                       (table.concat
                         ["let version = -1.2; in fetchFromGitHub {"
                          "  owner = \"reo101\"; repo = \"nix-update.nvim\"; rev = \"v${version}\"; hash = \"old\";"
                          "}"]
                         "\n")
                       {:rev "v-1.2"})

  (assert-fetch-values
    "finalAttrs stays in function binder"
    (table.concat
      ["let pname = \"outer\"; version = \"outer\"; in stdenv.mkDerivation (finalAttrs: {"
       "  pname = \"nix-update.nvim\"; version = \"0.1.2\";"
       "  src = fetchFromGitHub {"
       "    owner = \"reo101\"; repo = finalAttrs.pname; rev = finalAttrs.version; hash = \"old\";"
       "  };"
       "})"]
      "\n")
    {:repo "nix-update.nvim" :rev "0.1.2"})

  (assert-fetch-values
    "dream2nix config"
    (table.concat
      ["{ config, ... }: {"
       "  name = \"nix-update.nvim\"; version = \"0.1.2\";"
       "  mkDerivation = {"
       "    src = config.deps.fetchFromGitHub {"
       "      owner = \"reo101\"; repo = config.name; rev = config.version; hash = \"old\";"
       "    };"
       "  };"
       "}"]
      "\n")
    {:repo "nix-update.nvim" :rev "0.1.2"})

  (assert-fetch-values
    "inherited rec attrs"
    (table.concat
      ["let pname = \"lighthouse\"; version = \"1.0\"; in stdenv.mkDerivation rec {"
       "  inherit pname version;"
       "  src = fetchFromGitHub {"
       "    owner = \"gaasedelen\"; repo = pname; rev = \"v${version}\"; hash = \"old\";"
       "  };"
       "}"]
      "\n")
    {:repo "lighthouse" :rev "v1.0"})

  (nix-update.setup
    {:update_actions [:apply]
     :extra_prefetchers
       {:commandFetch
         {:required-cmds ["printf"]
          :prefetcher (fn [_] {:cmd "printf" :args ["command-hash"]})
          :extractor (fn [stdout] {:hash (. stdout 1)})}}})
  (let [bufnr (vim.api.nvim_create_buf false true)
        fetches (require :nix-update.fetches)]
    (tset vim.bo bufnr :filetype :nix)
    (vim.api.nvim_buf_set_lines
      bufnr 0 -1 false
      ["commandFetch { hash = \"old\"; }"])
    (local fetch (. (fetches.find-used-fetches {:bufnr bufnr}) 1))
    (local task (fetches.prefetch-fetch {:bufnr bufnr :fetch fetch}))
    (task:wait 1000)
    (assert-truthy
      (= (. (vim.api.nvim_buf_get_lines bufnr 0 -1 false) 1)
         "commandFetch { hash = \"command-hash\"; }")
      "command prefetch did not update the buffer"))

  (fn assert-lua-prefetch [label runner expected]
    (nix-update.setup
      {:update_actions [:apply]
       :extra_prefetchers {:luaFetch runner}})

    (local bufnr (vim.api.nvim_create_buf false true))
    (tset vim.bo bufnr :filetype :nix)
    (vim.api.nvim_buf_set_lines
      bufnr 0 -1 false
      ["luaFetch { url = \"https://example.com\"; hash = \"old\"; }"])

    (local fetches (require :nix-update.fetches))
    (local fetch (. (fetches.find-used-fetches {:bufnr bufnr}) 1))
    (assert-truthy fetch (.. label ": fetch was not found"))

    (local task (fetches.prefetch-fetch {:bufnr bufnr :fetch fetch}))
    (task:wait 1000)

    (local cache (require :nix-update._cache))
    (assert-truthy (= (?. cache.cache fetch._fwhole :data :hash)
                      expected)
                   (.. label ": wrong hash"))
    (assert-truthy
      (= (. (vim.api.nvim_buf_get_lines bufnr 0 -1 false) 1)
         (string.format "luaFetch { url = \"https://example.com\"; hash = \"%s\"; }" expected))
      (.. label ": buffer was not updated")))

  (assert-lua-prefetch
    "synchronous Lua prefetcher"
    (fn [args]
      (assert-truthy (= args.url "https://example.com")
                     "synchronous Lua prefetcher: wrong args")
      {:hash "sync-hash"})
    "sync-hash")

  (assert-lua-prefetch
    "asynchronous Lua prefetcher"
    (fn [args done]
      (assert-truthy (= args.url "https://example.com")
                     "asynchronous Lua prefetcher: wrong args")
      (vim.schedule #(done {:hash "async-hash"})))
    "async-hash")

  (assert-lua-prefetch
    "fast-event Lua prefetcher"
    (fn [_args done]
      (local timer (vim.uv.new_timer))
      (timer:start 0 0
        (fn []
          (timer:close)
          (done {:hash "timer-hash"})))
      nil)
    "timer-hash"))

(local health (require :nix-update.health))
(health.check)
