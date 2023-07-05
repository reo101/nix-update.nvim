 local _local_1_ = require("nix-update.utils") local concat_two = _local_1_["concat-two"]
 local prefetcher_mt = _local_1_["prefetcher-mt"]






















 local nix_prefetch_git_sha256_extractor
 local function _2_(stdout)
 local sha256 = string.gsub(vim.fn.system(string.format("nix hash to-sri \"sha256:%s\"", vim.json.decode(table.concat(stdout)).sha256)), "\n", "")






 return {sha256 = sha256} end nix_prefetch_git_sha256_extractor = _2_

 local nix_prefetch_url_sha256_extractor
 local function _3_(stdout)
 local sha256 = vim.json.decode(table.concat(stdout)).hash



 return {sha256 = sha256} end nix_prefetch_url_sha256_extractor = _3_








 local prefetchers








 local function _6_(_4_) local _arg_5_ = _4_ local owner = _arg_5_["owner"]
 local repo = _arg_5_["repo"]
 local rev = _arg_5_["rev"]
 local _3ffetchSubmodules = _arg_5_["?fetchSubmodules"] local cmd = "nix"


 local args









 local function _7_() if (_3ffetchSubmodules == "true") then
 return {"--fetch-submodules"} else
 return {} end end args = concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two({}, {"run"}), {"nixpkgs#nix-prefetch-git"}), {"--"}), {"--no-deepClone"}), {"--quiet"}), {"--url", string.format("https://www.github.com/%s/%s", owner, repo)}), {"--rev", rev}), _7_())

 return {cmd = cmd, args = args} end












 local function _10_(_8_) local _arg_9_ = _8_ local owner = _arg_9_["owner"]
 local repo = _arg_9_["repo"]
 local rev = _arg_9_["rev"]
 local _3ffetchSubmodules = _arg_9_["?fetchSubmodules"] local cmd = "nix"


 local args









 local function _11_() if (_3ffetchSubmodules == "true") then
 return {"--fetch-submodules"} else
 return {} end end args = concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two({}, {"run"}), {"nixpkgs#nix-prefetch-git"}), {"--"}), {"--no-deepClone"}), {"--quiet"}), {"--url", string.format("https://www.gitlab.com/%s/%s", owner, repo)}), {"--rev", rev}), _11_())

 return {cmd = cmd, args = args} end









 local function _14_(_12_) local _arg_13_ = _12_ local url = _arg_13_["url"] local cmd = "nix" local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}








 return {cmd = cmd, args = args} end








 local function _17_(_15_) local _arg_16_ = _15_ local url = _arg_16_["url"] local cmd = "nix" local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}








 return {cmd = cmd, args = args} end









 local function _20_(_18_) local _arg_19_ = _18_ local url = _arg_19_["url"]
 local rev = _arg_19_["rev"]
 local _3ffetchSubmodules = _arg_19_["?fetchSubmodules"] local cmd = "nix"


 local args






 local function _21_() if (_3ffetchSubmodules == "true") then
 return {"--fetch-submodules"} else
 return {} end end args = concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two({}, {"run"}), {"nixpkgs#nix-prefetch-git"}), {"--"}), {"--no-deepClone"}), {"--quiet"}), {"--url", url}), {"--rev", rev}), _21_())

 return {cmd = cmd, args = args} end prefetchers = {fetchFromGitHub = {["required-cmds"] = {"nix"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _6_, extractor = nix_prefetch_git_sha256_extractor}, fetchFromGitLab = {["required-cmds"] = {"nix"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _10_, extractor = nix_prefetch_git_sha256_extractor}, fetchurl = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _14_, extractor = nix_prefetch_url_sha256_extractor}, fetchpatch = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _17_, extractor = nix_prefetch_url_sha256_extractor}, fetchgit = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url", "rev"}, prefetcher = _20_, extractor = nix_prefetch_git_sha256_extractor}}




 for _, prefetcher in pairs(prefetchers) do
 setmetatable(prefetcher, prefetcher_mt) end

 return {prefetchers = prefetchers}