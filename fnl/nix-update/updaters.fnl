(fn any [tbl p?]
  (each [k v (pairs tbl)]
    (when (p? k v)
      (lua "return true")))
  false)

(fn all [tbl p?]
  (each [k v (pairs tbl)]
    (when (not (p? k v))
      (lua "return false")))
  true)

(fn has-keys [tbl keys]
  (all keys
       (fn [_ key]
         (any tbl
              (fn [k _]
                (= k key))))))

(fn concat-two [xss yss]
  (each [_ ys (ipairs yss)]
    (table.insert xss ys))
  xss)

(macro concat [...]
  (var res [])
  (each [_ l (ipairs [...])]
    (set res (list `concat-two res l)))
  res)

;;; Define the fetchers' updaters
(local updaters
  {;; Github
   :fetchFromGitHub
   (fn [args]
     (when (has-keys args
                     [:owner
                      :repo
                      :rev])
        (local {: owner
                : repo
                : rev
                : ?submodules}
               args)

        (local cmd "nix-prefetch-git")

        (local args (concat ["--no-deepClone"]
                            (if (= (?. ?submodules :value) :true)
                                ["--fetch-submodules"]
                                ;; else
                                [])
                            ["--quiet"
                             (string.format
                               "https://github.com/%s/%s.git"
                               owner.value
                               repo.value)
                             rev.value]))

        (local res (vim.fn.system (concat [cmd] args)))

        res))
   ;; GitLab
   :fetchFromGitLab
   (fn [args]
     :todo)

   ;; Fetch GIT
   :fetchgit
   (fn [args]
     :todo)

   ;; Fetch URL
   :fetchurl
   (fn [args]
     :todo)

   ;; Fetch ZIP
   :fetchzip
   (fn [args]
     :todo)

   ;; EmacsWiki
   :compileEmacsWikiFile
   (fn [args]
     :todo)

   ;; PyPi
   :fetchPypi
   (fn [args]
     :todo)})

updaters
