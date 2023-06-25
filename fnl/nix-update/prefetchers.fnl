(local {: filter
        : missing-keys
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
   {:required-cmds [:nix-prefetch]
    :required-keys [:owner
                    :repo
                    :rev]
    :prefetch
    (fn [{: owner
          : repo
          : rev
          : ?fetchSubmodules}]
      (local cmd "nix-prefetch")

      (local args (concat ["fetchFromGitHub"]
                          ["--owner" owner]
                          ["--repo"  repo]
                          ["--rev"   rev]
                          (if (= (?. ?fetchSubmodules :value) :true)
                              ["--fetchSubmodules"]
                              [])))

      {: cmd
       : args})}

   ;; Fetch Cargo
   :buildRustPackage
   {:required-cmds []
    :required-keys []
    :prefetch
    (fn [{}]
      (local cmd nil)

      (local args nil)

      ;; nix-prefetch '{ sha256 }: i3status-rust.cargoDeps.overrideAttrs (_: { cargoSha256 = sha256; })'

      {: cmd
       : args})}

   ;; Fetch GIT
   :fetchgit
   {:required-cmds []
    :required-keys [:owner
                    :repo
                    :rev]
    :prefetch
    (fn [{: owner
          : repo
          : rev
          : ?fetchSubmodules}]
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
       : args})}})

;;; Define the pre-fetchers' response extractors (cmd result -> new fields)
(local get-prefetcher-extractor
  {;; Github
   :fetchFromGitHub
   (fn [stdout]
     {:sha256 (. stdout 1)})})

(local mt {:__call
           (fn [self args]
             ;;; Check for missing keys
             (let [missing (missing-keys args self.required-keys)]
               (when (> (length missing) 0)
                 (vim.notify
                   (string.format
                     "Missing keys: %s"
                     (vim.inspect
                       missing)))
                 (lua "return nil")))

             ;;; Check for missing cmds
             (let [missing (filter #(= (vim.fn.executable $.v) 0) self.required-cmds)]
               (when (> (length missing) 0)
                 (vim.notify
                   (string.format
                     "Missing commands: %s"
                     (vim.inspect
                       missing)))
                 (lua "return nil")))

             ;;; Finally, safely call prefetch function
             (self.prefetch args))})

;;; Make all gen-prefetcher-cmd tables callable (for common error handling)
(each [_ prefetcher (pairs gen-prefetcher-cmd)]
  (setmetatable prefetcher mt))

{:prefetcher-cmd-mt mt
 : gen-prefetcher-cmd
 : get-prefetcher-extractor}
