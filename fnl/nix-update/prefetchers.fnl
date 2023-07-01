(local {: concat-two
        : prefetcher-cmd-mt}
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

;;; Define the fetchers'
;;;  (args -> cmd)
;;; Define the pre-fetchers' response extractors (cmd result -> new fields)
;;; {
;;;   :required-cmds ;; Required programs to be on $PATH
;;;   :required-keys ;; Required keys to be passed in
;;;   :prefetcher    ;; Generate the prefetch command + arguments
;;;   :extracter     ;; Extract the new value(s) from the prefetch result
;;; }
(local prefetchers
  {;; Github
   :fetchFromGitHub
   {:required-cmds [:nix-prefetch-git]
    :required-keys [:owner
                    :repo
                    :rev]
    ;; (args -> cmd)
    :prefetcher
     (fn [{: owner
           : repo
           : rev
           : ?fetchSubmodules}]
       (local cmd "nix-prefetch")

       (local args (concat ["--quiet"]
                           ["--url" (string.format
                                      "https://www.github.com/%s/%s"
                                      owner
                                      repo)]
                           ["--rev" rev]
                           (if (= ?fetchSubmodules :true)
                               ["--fetch-submodules"]
                               [])))

       {: cmd
        : args})
    ;; (cmd result -> new fields)
    :extractor
     (fn [stdout]
      {:sha256
        (-> stdout
            (table.concat)
            (vim.json.decode)
            (. :sha256))})}

   ;; Fetch Cargo
   :buildRustPackage
   {:required-cmds []
    :required-keys []
    :prefetcher
     (fn [{}]
       (local cmd nil)

       (local args nil)

       ;; nix-prefetch '{ sha256 }: i3status-rust.cargoDeps.overrideAttrs (_: { cargoSha256 = sha256; })'

       {: cmd
        : args})
    :extractor
     (fn [stdout]
       {})}

   ;; Fetch GIT
   :fetchgit
   {:required-cmds []
    :required-keys [:owner
                    :repo
                    :rev]
    :prefetcher
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

       {: cmd
        : args})
    :extractor
     (fn [stdout]
       {})}})

;;; Make all gen-prefetcher-cmd tables callable (for common error handling)
(each [_ prefetcher (pairs prefetchers)]
  (setmetatable prefetcher prefetcher-cmd-mt))

{: prefetchers}
