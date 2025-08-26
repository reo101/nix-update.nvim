 local _local_1_ = require("nix-update.utils") local prefetcher_mt = _local_1_["prefetcher-mt"]


 local _local_2_ = require("nix-update.utils") local concat_two = _local_2_["concat-two"]






















 local nurl_json_hash_extractor
 local function _3_(stdout)
 local hash = vim.json.decode(table.concat(stdout)).args.hash



 return {hash = hash} end nurl_json_hash_extractor = _3_

 local nix_json_hash_extractor
 local function _4_(stdout)
 local hash = vim.json.decode(table.concat(stdout)).hash



 return {hash = hash} end nix_json_hash_extractor = _4_








 local prefetchers








 local function _6_(_5_) local owner = _5_["owner"]
 local repo = _5_["repo"]
 local rev = _5_["rev"]
 local fetchSubmodules = _5_["fetchSubmodules"] local cmd = "nurl" local args = {"--json", string.format("--submodules=%s", (fetchSubmodules or "false")), string.format("https://www.github.com/%s/%s", owner, repo), rev}














 return {cmd = cmd, args = args} end












 local function _8_(_7_) local owner = _7_["owner"]
 local repo = _7_["repo"]
 local rev = _7_["rev"]
 local fetchSubmodules = _7_["fetchSubmodules"] local cmd = "nurl" local args = {"--json", string.format("--submodules=%s", (fetchSubmodules or "false")), string.format("https://www.gitlab.com/%s/%s", owner, repo), rev}













 return {cmd = cmd, args = args} end









 local function _10_(_9_) local url = _9_["url"]
 local name = _9_["name"] local cmd = "nix"


 local args



 local function _11_() if name then
 return {"--name", name} else
 return {} end end args = concat_two(concat_two(concat_two(concat_two(concat_two(concat_two({}, {"store"}), {"prefetch-file"}), {"--json"}), {"--hash-type", "sha256"}), _11_()), {url})


 return {cmd = cmd, args = args} end








 local function _13_(_12_) local url = _12_["url"] local cmd = "nix" local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}








 return {cmd = cmd, args = args} end









 local function _15_(_14_) local url = _14_["url"]
 local rev = _14_["rev"]
 local fetchSubmodules = _14_["fetchSubmodules"] local cmd = "nurl" local args = {"--json", "--fetcher", "builtins.fetchGit", string.format("--submodules=%s", (fetchSubmodules or "false")), url, rev}










 return {cmd = cmd, args = args} end prefetchers = {fetchFromGitHub = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _6_, extractor = nurl_json_hash_extractor}, fetchFromGitLab = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _8_, extractor = nurl_json_hash_extractor}, fetchurl = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _10_, extractor = nix_json_hash_extractor}, fetchpatch = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _13_, extractor = nix_json_hash_extractor}, fetchgit = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"url", "rev"}, prefetcher = _15_, extractor = nurl_json_hash_extractor}}




 for _, prefetcher in pairs(prefetchers) do
 setmetatable(prefetcher, prefetcher_mt) end

 return {prefetchers = prefetchers}
