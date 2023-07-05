(local {: concat-two
        : prefetcher-mt}
       (require :nix-update.utils))

(macro concat [...]
  (fn all [p? tbl]
    (each [k v (pairs tbl)]
      (when (not (p? k v))
        (lua "return false")))
    true)

  (var res [])

  ;;; TODO: compile-time concat all clumped chunks
  (if (all #(table? $2) [...])
      (each [_ xs (ipairs [...])]
        (each [_ x (ipairs xs)]
          (table.insert res x)))
      ;; else
      (each [_ xs (ipairs [...])]
        (set res (list `concat-two res xs))))

  res)

(local nix-prefetch-git-sha256-extractor
       (fn [stdout]
         (let [sha256 (-> stdout
                          (table.concat)
                          (vim.json.decode)
                          (. :sha256)
                          (->> (string.format "nix hash to-sri \"sha256:%s\""))
                          (vim.fn.system)
                          (string.gsub "\n" ""))]
           {: sha256})))

(local nix-prefetch-url-sha256-extractor
       (fn [stdout]
         (let [sha256 (-> stdout
                          (table.concat)
                          (vim.json.decode)
                          (. :hash))]
           {: sha256})))

;;; Define the prefetchers for each supported fetch
;;; {
;;;   :required-cmds ;; Required programs to be on $PATH
;;;   :required-keys ;; Required keys to be passed in
;;;   :prefetcher    ;; Generate the prefetch command + arguments
;;;   :extracter     ;; Extract the new value(s) from the prefetch result
;;; }
(local prefetchers
  {;; GitHub
   :fetchFromGitHub
   {:required-cmds [:nix]
    :required-keys [:owner
                    :repo
                    :rev]
    ;; (args -> cmd)
    :prefetcher
     (fn [{: owner
           : repo
           : rev
           : ?fetchSubmodules}]
       (local cmd "nix")

       (local args (concat ["run"]
                           ["nixpkgs#nix-prefetch-git"]
                           ["--"]
                           ["--no-deepClone"]
                           ["--quiet"]
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
    :extractor nix-prefetch-git-sha256-extractor}

   ;; GitLab
   :fetchFromGitLab
   {:required-cmds [:nix]
    :required-keys [:owner
                    :repo
                    :rev]
    ;; (args -> cmd)
    :prefetcher
     (fn [{: owner
           : repo
           : rev
           : ?fetchSubmodules}]
       (local cmd "nix")

       (local args (concat ["run"]
                           ["nixpkgs#nix-prefetch-git"]
                           ["--"]
                           ["--no-deepClone"]
                           ["--quiet"]
                           ["--url" (string.format
                                      "https://www.gitlab.com/%s/%s"
                                      owner
                                      repo)]
                           ["--rev" rev]
                           (if (= ?fetchSubmodules :true)
                             ["--fetch-submodules"]
                             [])))

       {: cmd
        : args})
    ;; (cmd result -> new fields)
    :extractor nix-prefetch-git-sha256-extractor}

   ;; Fetch URL
   :fetchurl
   {:required-cmds [:nix]
    :required-keys [:url]
    :prefetcher
     (fn [{: url}]
       (local cmd "nix")

       (local args (concat ["store"]
                           ["prefetch-file"]
                           ["--json"]
                           ["--hash-type" "sha256"]
                           [url]))

       {: cmd
        : args})
    :extractor nix-prefetch-url-sha256-extractor}

   ;; Fetch patch
   :fetchpatch
   {:required-cmds [:nix]
    :required-keys [:url]
    :prefetcher
     (fn [{: url}]
       (local cmd "nix")

       (local args (concat ["store"]
                           ["prefetch-file"]
                           ["--json"]
                           ["--hash-type" "sha256"]
                           [url]))

       {: cmd
        : args})
    :extractor nix-prefetch-url-sha256-extractor}

   ;; Fetch GIT
   :fetchgit
   {:required-cmds [:nix]
    :required-keys [:url
                    :rev]
    :prefetcher
     (fn [{: url
           : rev
           : ?fetchSubmodules}]
       (local cmd "nix")

       (local args (concat ["run"]
                           ["nixpkgs#nix-prefetch-git"]
                           ["--"]
                           ["--no-deepClone"]
                           ["--quiet"]
                           ["--url" url]
                           ["--rev" rev]
                           (if (= ?fetchSubmodules :true)
                             ["--fetch-submodules"]
                             [])))

       {: cmd
        : args})
    :extractor nix-prefetch-git-sha256-extractor}})

;;; Make all prefetchers (tables) callable (for common error handling)
(each [_ prefetcher (pairs prefetchers)]
  (setmetatable prefetcher prefetcher-mt))

{: prefetchers}
