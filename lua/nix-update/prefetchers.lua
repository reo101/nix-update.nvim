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
 local fetchSubmodules = _4_["fetchSubmodules"] local cmd = "nurl" local args = {"--json", string.format("--submodules=%s", (fetchSubmodules or "false")), string.format("https://www.github.com/%s/%s", owner, repo), rev}














 return {cmd = cmd, args = args} end












 local function _7_(_6_) local owner = _6_["owner"]
 local repo = _6_["repo"]
 local rev = _6_["rev"]
 local fetchSubmodules = _6_["fetchSubmodules"] local cmd = "nurl" local args = {"--json", string.format("--submodules=%s", (fetchSubmodules or "false")), string.format("https://www.gitlab.com/%s/%s", owner, repo), rev}













 return {cmd = cmd, args = args} end









 local function _9_(_8_) local url = _8_["url"] local cmd = "nix" local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}








 return {cmd = cmd, args = args} end








 local function _11_(_10_) local url = _10_["url"] local cmd = "nix" local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}








 return {cmd = cmd, args = args} end









 local function _13_(_12_) local url = _12_["url"]
 local rev = _12_["rev"]
 local fetchSubmodules = _12_["fetchSubmodules"] local cmd = "nurl" local args = {"--json", "--fetcher", "builtins.fetchGit", string.format("--submodules=%s", (fetchSubmodules or "false")), url, rev}










 return {cmd = cmd, args = args} end prefetchers = {fetchFromGitHub = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _5_, extractor = nurl_json_hash_extractor}, fetchFromGitLab = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _7_, extractor = nurl_json_hash_extractor}, fetchurl = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _9_, extractor = nix_json_hash_extractor}, fetchpatch = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _11_, extractor = nix_json_hash_extractor}, fetchgit = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"url", "rev"}, prefetcher = _13_, extractor = nurl_json_hash_extractor}}




 for _, prefetcher in pairs(prefetchers) do
 setmetatable(prefetcher, prefetcher_mt) end

 return {prefetchers = prefetchers}
