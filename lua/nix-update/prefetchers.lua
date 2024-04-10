 local _local_1_ = require("nix-update.utils") local prefetcher_mt = _local_1_["prefetcher-mt"]






















 local nurl_json_hash_extractor
 local function _2_(stdout)
 local hash = vim.json.decode(table.concat(stdout)).args.hash



 return {hash = hash} end nurl_json_hash_extractor = _2_

 local nix_json_hash_extractor
 local function _3_(stdout)
 local hash = vim.json.decode(table.concat(stdout)).hash



 return {hash = hash} end nix_json_hash_extractor = _3_

 local nix_json_sha256_extractor
 local function _4_(stdout)
 local sha256 = vim.json.decode(table.concat(stdout)).hash



 return {sha256 = sha256} end nix_json_sha256_extractor = _4_








 local prefetchers








 local function _7_(_5_) local _arg_6_ = _5_ local owner = _arg_6_["owner"]
 local repo = _arg_6_["repo"]
 local rev = _arg_6_["rev"]
 local _3ffetchSubmodules = _arg_6_["?fetchSubmodules"] local cmd = "nurl"


 local args




 local function _8_() if _3ffetchSubmodules then return "true" else return "false" end end args = {"--json", string.format("--submodules=%s", _8_()), string.format("https://www.github.com/%s/%s", owner, repo), rev}








 return {cmd = cmd, args = args} end












 local function _11_(_9_) local _arg_10_ = _9_ local owner = _arg_10_["owner"]
 local repo = _arg_10_["repo"]
 local rev = _arg_10_["rev"]
 local _3ffetchSubmodules = _arg_10_["?fetchSubmodules"] local cmd = "nurl"


 local args



 local function _12_() if _3ffetchSubmodules then return "true" else return "false" end end args = {"--json", string.format("--submodules=%s", _12_()), string.format("https://www.gitlab.com/%s/%s", owner, repo), rev}








 return {cmd = cmd, args = args} end









 local function _15_(_13_) local _arg_14_ = _13_ local url = _arg_14_["url"] local cmd = "nix" local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}








 return {cmd = cmd, args = args} end








 local function _18_(_16_) local _arg_17_ = _16_ local url = _arg_17_["url"] local cmd = "nix" local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}








 return {cmd = cmd, args = args} end









 local function _21_(_19_) local _arg_20_ = _19_ local url = _arg_20_["url"]
 local rev = _arg_20_["rev"]
 local _3ffetchSubmodules = _arg_20_["?fetchSubmodules"] local cmd = "nurl"


 local args



 local function _22_() if _3ffetchSubmodules then return "true" else return "false" end end args = {"--json", "--fetcher", "builtins.fetchGit", string.format("--submodules=%s", _22_()), url, rev}





 return {cmd = cmd, args = args} end prefetchers = {fetchFromGitHub = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _7_, extractor = nurl_json_hash_extractor}, fetchFromGitLab = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _11_, extractor = nurl_json_hash_extractor}, fetchurl = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _15_, extractor = nix_json_sha256_extractor}, fetchpatch = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _18_, extractor = nix_json_hash_extractor}, fetchgit = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"url", "rev"}, prefetcher = _21_, extractor = nurl_json_hash_extractor}}




 for _, prefetcher in pairs(prefetchers) do
 setmetatable(prefetcher, prefetcher_mt) end

 return {prefetchers = prefetchers}
