(local {: prefetcher-mt}
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

(local nurl-json-hash-extractor
       (fn [stdout]
         (let [hash (-> stdout
                        table.concat
                        vim.json.decode
                        (. :args :hash))]
           {: hash})))

(local nix-json-hash-extractor
       (fn [stdout]
         (let [hash (-> stdout
                        table.concat
                        vim.json.decode
                        (. :hash))]
           {: hash})))

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
   {:required-cmds [:nurl]
    :required-keys [:owner
                    :repo
                    :rev]
    ;; (args -> cmd)
    :prefetcher
     (fn [{: owner
           : repo
           : rev
           : ?fetchSubmodules}]
       (local cmd "nurl")

       (local args (concat ["--json"]
                           ;; NOTE: breaks for some reason
                           ;; ["--fetcher" "fetchFromGitHub"]
                           [(string.format
                              "--submodules=%s"
                              (if ?fetchSubmodules
                                  :true
                                  :false))]
                           [(string.format
                              "https://www.github.com/%s/%s"
                              owner
                              repo)]
                           [rev]))

       {: cmd
        : args})
    ;; (cmd result -> new fields)
    :extractor nurl-json-hash-extractor}

   ;; GitLab
   :fetchFromGitLab
   {:required-cmds [:nurl]
    :required-keys [:owner
                    :repo
                    :rev]
    ;; (args -> cmd)
    :prefetcher
     (fn [{: owner
           : repo
           : rev
           : ?fetchSubmodules}]
       (local cmd "nurl")

       (local args (concat ["--json"]
                           ;; ["--fetcher" "fetchFromGitLab"]
                           [(string.format
                              "--submodules=%s"
                              (if ?fetchSubmodules
                                  :true
                                  :false))]
                           [(string.format
                              "https://www.gitlab.com/%s/%s"
                              owner
                              repo)]
                           [rev]))

       {: cmd
        : args})
    ;; (cmd result -> new fields)
    :extractor nurl-json-hash-extractor}

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
    :extractor nix-json-hash-extractor}

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
    :extractor nix-json-hash-extractor}

   ;; Fetch GIT
   :fetchgit
   {:required-cmds [:nurl]
    :required-keys [:url
                    :rev]
    :prefetcher
     (fn [{: url
           : rev
           : ?fetchSubmodules}]
       (local cmd "nurl")

       (local args (concat ["--json"]
                           ["--fetcher" "builtins.fetchGit"]
                           [(string.format
                              "--submodules=%s"
                              (if ?fetchSubmodules
                                  :true
                                  :false))]
                           [url]
                           [rev]))

       {: cmd
        : args})
    :extractor nurl-json-hash-extractor}})

;;; Make all prefetchers (tables) callable (for common error handling)
(each [_ prefetcher (pairs prefetchers)]
  (setmetatable prefetcher prefetcher-mt))

{: prefetchers}
