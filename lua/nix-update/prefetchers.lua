-- [nfnl] fnl/nix-update/prefetchers.fnl
 local _local_1_ = require("nix-update.utils") local prefetcher_mt = _local_1_["prefetcher-mt"]























 local nurl_json_hash_extractor
 local function fn_2_(stdout)
 local hash = vim.json.decode(table.concat(stdout)).args.hash



 return {hash = hash} end nurl_json_hash_extractor = fn_2_

 local nix_json_hash_extractor
 local function fn_3_(stdout)
 local hash = vim.json.decode(table.concat(stdout)).hash



 return {hash = hash} end nix_json_hash_extractor = fn_3_








 local prefetchers








 local function fn_5_(arg_4_) local owner = arg_4_.owner
 local repo = arg_4_.repo
 local rev = arg_4_.rev
 local tag = arg_4_.tag
 local fetchSubmodules = arg_4_.fetchSubmodules local cmd = "nurl"


 local ref = (rev or tag)

 local args = {"--json", string.format("--submodules=%s", (fetchSubmodules or "false")), string.format("https://www.github.com/%s/%s", owner, repo), ref}











 return {cmd = cmd, args = args} end












 local function fn_7_(arg_6_) local owner = arg_6_.owner
 local repo = arg_6_.repo
 local rev = arg_6_.rev
 local tag = arg_6_.tag
 local fetchSubmodules = arg_6_.fetchSubmodules local cmd = "nurl"


 local ref = (rev or tag)

 local args = {"--json", string.format("--submodules=%s", (fetchSubmodules or "false")), string.format("https://www.gitlab.com/%s/%s", owner, repo), ref}










 return {cmd = cmd, args = args} end









 local function fn_9_(arg_8_) local url = arg_8_.url
 local name = arg_8_.name local cmd = "nix"


 local args



 local if_tgt_10_ if name then
 if_tgt_10_ = {"--name", name} else
 if_tgt_10_ = {} end args = vim.iter({{"store"}, {"prefetch-file"}, {"--json"}, {"--hash-type", "sha256"}, if_tgt_10_, {url}}):flatten():totable()


 return {cmd = cmd, args = args} end








 local function fn_13_(arg_12_) local url = arg_12_.url local cmd = "nix"


 local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}





 return {cmd = cmd, args = args} end









 local function fn_15_(arg_14_) local url = arg_14_.url
 local rev = arg_14_.rev
 local fetchSubmodules = arg_14_.fetchSubmodules local cmd = "nurl"


 local args = {"--json", "--fetcher", "builtins.fetchGit", string.format("--submodules=%s", (fetchSubmodules or "false")), url, rev}







 return {cmd = cmd, args = args} end prefetchers = {fetchFromGitHub = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", {"tag", "rev"}}, prefetcher = fn_5_, extractor = nurl_json_hash_extractor}, fetchFromGitLab = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", {"tag", "rev"}}, prefetcher = fn_7_, extractor = nurl_json_hash_extractor}, fetchurl = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = fn_9_, extractor = nix_json_hash_extractor}, fetchpatch = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = fn_13_, extractor = nix_json_hash_extractor}, fetchgit = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"url", "rev"}, prefetcher = fn_15_, extractor = nurl_json_hash_extractor}}




 for _, prefetcher in pairs(prefetchers) do
 setmetatable(prefetcher, prefetcher_mt) end

 return {prefetchers = prefetchers}
