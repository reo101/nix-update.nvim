(local {: find-child
        : find-children
        : missing-keys
        : coords
        : flatten-fragments}
       (require "nix-update.utils.common"))

(local {: call-command}
       (require "nix-update.utils.command"))

(local {: prefetcher-mt
        : create-proxied}
       (require "nix-update.utils.mt"))

{: find-child
 : find-children
 : missing-keys
 : coords
 : flatten-fragments
 : prefetcher-mt
 : create-proxied
 : call-command}
