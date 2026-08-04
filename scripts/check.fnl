(fn fail [msg]
  (error (.. "[check] " msg)))

(fn assert-truthy [value msg]
  (when (not value)
    (fail msg)))

(assert-truthy (and vim.pack vim.pack.add)
               "vim.pack.add is required for checks")

(vim.pack.add ["https://github.com/nvim-lua/plenary.nvim"])

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

  (fn assert-lua-prefetch [label runner expected]
    (nix-update.setup
      {:update_actions []
       :extra_prefetchers {:luaFetch runner}})

    (local bufnr (vim.api.nvim_create_buf false true))
    (tset vim.bo bufnr :filetype :nix)
    (vim.api.nvim_buf_set_lines
      bufnr 0 -1 false
      ["luaFetch { url = \"https://example.com\"; hash = \"old\"; }"])

    (local fetches (require :nix-update.fetches))
    (local fetch (. (fetches.find-used-fetches {:bufnr bufnr}) 1))
    (assert-truthy fetch (.. label ": fetch was not found"))

    (fetches.prefetch-fetch {:bufnr bufnr :fetch fetch})

    (local cache (require :nix-update._cache))
    (assert-truthy
      (vim.wait 1000
                (fn []
                  (not= (. cache.cache fetch._fwhole) nil)))
      (.. label ": prefetch did not finish"))
    (assert-truthy (= (. cache.cache fetch._fwhole :data :hash)
                      expected)
                   (.. label ": wrong hash")))

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
      (vim.schedule (fn []
                      (done {:hash "async-hash"}))))
    "async-hash"))

(local health (require :nix-update.health))
(health.check)
