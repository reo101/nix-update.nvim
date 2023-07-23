(import-macros
  {: mdo}
  :nix-update.utils.fp.mdo-macro)

(local Result {})

;;; Validation
(fn Result.ok? [mx]
  (match mx
    [:ok & _] true
    _ false))
(fn Result.err? [mx]
  (match mx
    [:err & _] true
    _ false))
(fn Result.result? [mx]
  (or (Result.ok?  mx)
      (Result.err? mx)))

;;; Construction
(fn Result.ok [...]
  [:ok ...])
(fn Result.err [...]
  [:err ...])
(fn Result.new [...]
  (match ...
    (where r (Result.result? r)) r
    (nil err)                    (Result.err err)
    _                            (Result.ok ...)))

;;; Functor
(fn Result.map [mx f]
  (match mx
    [:ok & ok] (Result.ok (f (unpack ok)))
    _ mx))
(fn Result.maperr [mx f]
  (match mx
    [:err & err] (Result.err (f (unpack err)))
    _ mx))
(fn Result.bimap [mx of ef]
  (match mx
    [:ok  & ok]  (Result.ok  (of (unpack ok)))
    [:err & err] (Result.err (ef (unpack err)))))

;;; Monad
(fn Result.pure [...]
  (match ...
    (nil) [:none]
    _     [:some ...]))
(fn Result.join [mx]
  (match mx
    [:some [:some & x]] (values (unpack x))))
(fn Result.>>= [mx f]
  (match mx
    [:ok & ok] (f (unpack ok))
    _ mx))

;;; Miscellaneous
(fn Result.validate [v p e]
  (mdo Result
    (<- x v)
    (if (p x)
        (Result.new x)
        (Restut.err e))))
(fn Result.unwrap [mx]
  (match mx
    [:ok & ok] (values (unpack ok))
    _ nil))
(fn Result.unwrap! [mx]
  (match mx
    [:ok  & ok] (values (unpack ok))
    [:err & err] (error err)))

Result
