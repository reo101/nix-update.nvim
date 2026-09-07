;; nfnl configuration
;; See https://github.com/Olical/nfnl for details
(local config (require :nfnl.config))
(local defaults (config.default))

(tset defaults :compiler-options :correlate true)

defaults

