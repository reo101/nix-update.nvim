 local _local_1_ = require("nix-update.utils") local create_proxied = _local_1_["create-proxied"]


 local cache = create_proxied()

 return {cache = cache}
