(local {: has-keys
        : concat-two}
       (require :nix-update.util))

(macro concat [...]
  (fn all [p? tbl]
    (each [k v (pairs tbl)]
      (when (not (p? k v))
        (lua "return false")))
    true)

  (var res [])

  (if (all #(table? $2) [...])
      (each [_ xs (ipairs [...])]
        (each [_ x (ipairs xs)]
          (table.insert res x)))
      ;; else
      (each [_ xs (ipairs [...])]
        (set res (list `concat-two res xs))))

  res)

;; TODO:
;; fetchFromGitLab
;; fetchgit
;; fetchurl
;; fetchzip
;; compileEmacsWikiFile
;; fetchPypi

;;; Define the fetchers' updaters (args -> cmd)
(local gen-prefetcher-cmd
  {;; Github
   :fetchFromGitHub
   (fn [args]
     (when (not (has-keys args
                         [:owner
                          :repo
                          :rev]))
       (vim.notify
         (string.format
           "Missing keys: %s"
           (vim.inspect args)))
       (lua "return"))
     ;; Construct command
     (local {: owner
             : repo
             : rev
             : ?fetchSubmodules}
            args)

     (local cmd "nix-prefetch")

     (local args (concat ["fetchFromGitHub"]
                         ["--owner" owner.value]
                         ["--repo"  repo.value]
                         ["--rev"   rev.value]
                         [(if (= (?. ?fetchSubmodules :value) :true)
                           "--fetchSubmodules"
                           "")]))

     {: cmd
      : args})

   ;; Fetch Cargo
   :buildRustPackage
   (fn [args]
     (when (has-keys args
                     [])
       (local cmd nil)
       (local args nil)

       ;; nix-prefetch '{ sha256 }: i3status-rust.cargoDeps.overrideAttrs (_: { cargoSha256 = sha256; })'

       {: cmd
        : args}))

   ;; Fetch GIT
   :fetchgit
   (fn [args]
     (when (has-keys args
                     [:owner
                      :repo
                      :rev])
        (local {: owner
                : repo
                : rev
                : ?fetchSubmodules}
               args)

        (local cmd "nix-prefetch-git")

        (local args (concat ["--no-deepClone"]
                            [(if (= (?. ?fetchSubmodules :value) :true)
                               "--fetch-submodules"
                               "")]
                            ["--quiet"
                             (string.format
                               "https://github.com/%s/%s.git"
                               owner.value
                               repo.value)
                             rev.value]))

        ;; (local res (-> (concat [cmd] args)
        ;;                (vim.fn.system)
        ;;                (vim.json.decode)))))})

        {: cmd
         : args}))})

;;; Define the pre-fetchers' response extractors (cmd result -> new fields)
(local get-prefetcher-extractor
  {;; Github
   :fetchFromGitHub
   (fn [res]
     {:sha256 (. res 1)})})

{: gen-prefetcher-cmd
 : get-prefetcher-extractor}
