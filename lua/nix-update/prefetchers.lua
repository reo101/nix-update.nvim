 local _local_1_ = require("nix-update.utils") local prefetcher_mt = _local_1_["prefetcher-mt"]






















 local nurl_json_hash_extractor
 local function _2_(stdout)
 local hash = vim.json.decode(table.concat(stdout)).args.hash



 return {hash = hash} end nurl_json_hash_extractor = _2_

 local nix_json_hash_extractor
 local function _3_(stdout)
 local hash = vim.json.decode(table.concat(stdout)).hash



 return {hash = hash} end nix_json_hash_extractor = _3_








 local prefetchers








 local function _5_(_4_) local owner = _4_["owner"]
 local repo = _4_["repo"]
 local rev = _4_["rev"]
 local _3ffetchSubmodules = _4_["?fetchSubmodules"] local cmd = "nurl"


 local args




 local function _6_() if _3ffetchSubmodules then return "true" else return "false" end end args = {"--json", string.format("--submodules=%s", _6_()), string.format("https://www.github.com/%s/%s", owner, repo), rev}








 return {cmd = cmd, args = args} end












 local function _8_(_7_) local owner = _7_["owner"]
 local repo = _7_["repo"]
 local rev = _7_["rev"]
 local _3ffetchSubmodules = _7_["?fetchSubmodules"] local cmd = "nurl"


 local args



 local function _9_() if _3ffetchSubmodules then return "true" else return "false" end end args = {"--json", string.format("--submodules=%s", _9_()), string.format("https://www.gitlab.com/%s/%s", owner, repo), rev}








 return {cmd = cmd, args = args} end









 local function _11_(_10_) local url = _10_["url"] local cmd = "nix" local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}








 return {cmd = cmd, args = args} end








 local function _13_(_12_) local url = _12_["url"] local cmd = "nix" local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}








 return {cmd = cmd, args = args} end









 local function _15_(_14_) local url = _14_["url"]
 local rev = _14_["rev"]
 local _3ffetchSubmodules = _14_["?fetchSubmodules"] local cmd = "nurl"


 local args



 local function _16_() if _3ffetchSubmodules then return "true" else return "false" end end args = {"--json", "--fetcher", "builtins.fetchGit", string.format("--submodules=%s", _16_()), url, rev}





 return {cmd = cmd, args = args} end prefetchers = {fetchFromGitHub = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _5_, extractor = nurl_json_hash_extractor}, fetchFromGitLab = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _8_, extractor = nurl_json_hash_extractor}, fetchurl = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _11_, extractor = nix_json_hash_extractor}, fetchpatch = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _13_, extractor = nix_json_hash_extractor}, fetchgit = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"url", "rev"}, prefetcher = _15_, extractor = nurl_json_hash_extractor}}




 for _, prefetcher in pairs(prefetchers) do
 setmetatable(prefetcher, prefetcher_mt) end

 return {prefetchers = prefetchers}
