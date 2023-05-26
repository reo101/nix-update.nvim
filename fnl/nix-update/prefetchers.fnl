(local {: map
        : filter
        : has-keys
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
     (local required-keys
            [:owner
             :repo
             :rev])

     (when (not (has-keys args required-keys))
       (vim.notify
         (string.format
           "Missing keys: %s"
           (vim.inspect
             (filter #(not (vim.list_contains (map #$1 args) $))
                     required-keys))))
       (lua "return"))

     ;; Construct command
     (local {: owner
             : repo
             : rev
             : ?fetchSubmodules}
            args)

     (local cmd "nix-prefetch")

     (local args (concat ["fetchFromGitHub"]
                         ["--owner" owner]
                         ["--repo"  repo]
                         ["--rev"   rev]
                         (if (= (?. ?fetchSubmodules :value) :true)
                             ["--fetchSubmodules"]
                             [])))

     {: cmd
      : args})

   ;; Fetch Cargo
   :buildRustPackage
   (fn [args]
     (local required-keys
            [])
     (when (has-keys args required-keys)
       (local cmd nil)
       (local args nil)

       ;; nix-prefetch '{ sha256 }: i3status-rust.cargoDeps.overrideAttrs (_: { cargoSha256 = sha256; })'

       {: cmd
        : args}))

   ;; Fetch GIT
   :fetchgit
   (fn [args]
     (local required-keys
            [:owner
             :repo
             :rev])
     (when (not (has-keys args required-keys))
        (local {: owner
                : repo
                : rev
                : ?fetchSubmodules}
               args)

        (local cmd "nix-prefetch-git")

        (local args (concat ["--no-deepClone"]
                            (if (= (?. ?fetchSubmodules :value) :true)
                              ["--fetch-submodules"]
                              [])
                            ["--quiet"
                             (string.format
                               "https://github.com/%s/%s.git"
                               owner
                               repo)
                             rev]))

        ;; (local res (-> (concat [cmd] args)
        ;;                (vim.fn.system)
        ;;                (vim.json.decode)))))})

        {: cmd
         : args}))})

;;; Define the pre-fetchers' response extractors (cmd result -> new fields)
(local get-prefetcher-extractor
  {;; Github
   :fetchFromGitHub
   (fn [stdout]
     {:sha256 (. stdout 1)})})

{: gen-prefetcher-cmd
 : get-prefetcher-extractor}
