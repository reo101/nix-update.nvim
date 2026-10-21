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
(var called? false)
(let [prefetcher (setmetatable
                   {:required-cmds ["nix-update-nonexistent-prefetch-command"]
                    :prefetcher (fn [_] (set called? true))}
                   prefetcher-mt)
      task (prefetcher {})]
  (assert-truthy (= (type task) :table) "command prefetcher did not return a task")
  (let [(ok err) (task:pwait 1000)]
    (assert-truthy (not ok) "missing command task did not fail")
    (assert-truthy (not called?) "prefetcher ran without its required command")
    (assert-truthy
      (string.find err "Missing commands: nix-update-nonexistent-prefetch-command" 1 true)
      "missing command diagnostic is incorrect")))

(let [prefetcher (setmetatable
                   {:required-cmds ["printf"]
                    :prefetcher (fn [_] {:cmd "printf" :args ["command-hash"]})
                    :extractor (fn [stdout] {:hash (. stdout 1)})}
                   prefetcher-mt)
      task (prefetcher {})]
  (assert-truthy (= (. (task:wait 1000) :hash) "command-hash")
                 "command task did not extract its result"))

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

  (fn start-prefetch [prefetcher]
    (tset vim.g :nix_update nil)
    (nix-update.setup
      {:update_actions [:apply]
       :extra_prefetchers {:taskFetch prefetcher}})
    (local bufnr (vim.api.nvim_create_buf false true))
    (tset vim.bo bufnr :filetype :nix)
    (vim.api.nvim_buf_set_lines
      bufnr 0 -1 false
      ["taskFetch { url = \"https://example.com\"; hash = \"old\"; }"])
    (local fetches (require :nix-update.fetches))
    (local fetch (. (fetches.find-used-fetches {:bufnr bufnr}) 1))
    (assert-truthy fetch "task prefetch: fetch was not found")
    {: bufnr : fetch
     :task (fetches.prefetch-fetch {: bufnr : fetch})})

  (fn assert-task-prefetch [label prefetcher expected]
    (let [{: bufnr : fetch : task} (start-prefetch prefetcher)
          {: cache} (require :nix-update._cache)]
      (task:wait 1000)
      (assert-truthy (= (?. cache fetch._fwhole :data :hash) expected)
                     (.. label ": wrong hash"))
      (assert-truthy
        (= (. (vim.api.nvim_buf_get_lines bufnr 0 -1 false) 1)
           (string.format "taskFetch { url = \"https://example.com\"; hash = \"%s\"; }" expected))
        (.. label ": buffer was not updated"))))

  (assert-task-prefetch
    "command table"
    {:required-cmds ["printf"]
     :prefetcher (fn [_] {:cmd "printf" :args ["command-hash"]})
     :extractor (fn [stdout] {:hash (. stdout 1)})}
    "command-hash")

  (assert-task-prefetch
    "immediate task"
    (fn [args]
      (vim.async.run
        (fn []
          (assert-truthy (= args.url "https://example.com") "task received wrong args")
          {:hash "task-hash"})))
    "task-hash")

  (assert-task-prefetch
    "awaiting task"
    (fn [_]
      (vim.async.run
        (fn []
          (vim.async.sleep 1)
          (local {: stdout} (call-command {:cmd "printf" :args ["awaited-hash"]}))
          {:hash (. stdout 1)})))
    "awaited-hash")

  (assert-task-prefetch
    "fast-event task"
    (fn [_]
      (vim.async.run
        (fn []
          (vim.async.await
            (fn [done]
              (local timer (vim.uv.new_timer))
              (timer:start 0 0
                (fn []
                  (timer:close)
                  (done)))
              nil))
          (assert-truthy (vim.in_fast_event) "timer did not resume in a fast event")
          {:hash "timer-hash"})))
    "timer-hash")

  (fn assert-prefetch-error [label prefetcher expected]
    (let [{: bufnr : fetch : task} (start-prefetch prefetcher)
          {: cache} (require :nix-update._cache)]
      (task:wait 1000)
      (local err (?. cache fetch._fwhole :err))
      (assert-truthy (and err (string.find err expected 1 true))
                     (.. label ": wrong error"))
      (assert-truthy
        (= (. (vim.api.nvim_buf_get_lines bufnr 0 -1 false) 1)
           "taskFetch { url = \"https://example.com\"; hash = \"old\"; }")
        (.. label ": modified the buffer on failure"))))

  (assert-prefetch-error
    "failed task"
    (fn [_] (vim.async.run #(error "task failure")))
    "task failure")
  (assert-prefetch-error
    "factory failure"
    (fn [_] (error "factory failure"))
    "factory failure")
  (assert-prefetch-error
    "synchronous field return"
    (fn [_] {:hash "not-a-task"})
    "Invalid arguments, expected Task")
  (assert-prefetch-error
    "callback prefetcher"
    (fn [_ done] (done {:hash "not-a-task"}))
    "nil value")
  (assert-prefetch-error
    "invalid task result"
    (fn [_] (vim.async.run #(values nil)))
    "Prefetch task must return a table of fields")
  (assert-prefetch-error
    "invalid field value"
    (fn [_] (vim.async.run #(values {:hash 1})))
    "Prefetch task fields must have string keys and values")
  (assert-prefetch-error
    "missing fetch key"
    {:required-keys [:owner]
     :prefetcher (fn [_] (error "must not run"))
     :extractor (fn [_] {})}
    "Missing keys: owner")
  (assert-prefetch-error
    "command failure"
    {:prefetcher (fn [_] {:cmd "sh" :args ["-c" "printf failure >&2; printf output; exit 7"]})
     :extractor (fn [_] (error "must not extract failed output"))}
    "exited with code 7: failure")
  (assert-prefetch-error
    "extractor failure"
    {:prefetcher (fn [_] {:cmd "printf" :args ["output"]})
     :extractor (fn [_] (error "extractor failure"))}
    "extractor failure")

  (var prefetch-task nil)
  (var finished? false)
  (let [{: fetch : task}
        (start-prefetch
          (fn [_]
            (set prefetch-task
              (vim.async.run
                (fn []
                  (vim.async.sleep 10000)
                  (set finished? true)
                  {:hash "cancelled-hash"})))
            prefetch-task))
        {: cache} (require :nix-update._cache)]
    (task:close)
    (let [(ok err) (task:pwait 1000)]
      (assert-truthy (and (not ok) (= err "closed")) "request did not cancel"))
    (assert-truthy (prefetch-task:completed) "cancelled child task did not finish")
    (assert-truthy (not finished?) "cancelled child task continued")
    (assert-truthy (= (. cache fetch._fwhole) nil)
                   "cancelled request wrote to the cache")))

(local health (require :nix-update.health))
(health.check)
