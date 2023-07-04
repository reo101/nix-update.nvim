 local _local_1_ = require("nix-update.utils") local concat_two = _local_1_["concat-two"]
 local prefetcher_mt = _local_1_["prefetcher-mt"]






















 local nix_prefetch_git_sha256_extractor
 local function _2_(stdout)
 local sha256 = string.gsub(vim.fn.system(string.format("nix hash to-sri \"sha256:%s\"", vim.json.decode(table.concat(stdout)).sha256)), "\n", "")






 return {sha256 = sha256} end nix_prefetch_git_sha256_extractor = _2_


















 local prefetchers








 local function _5_(_3_) local _arg_4_ = _3_ local owner = _arg_4_["owner"]
 local repo = _arg_4_["repo"]
 local rev = _arg_4_["rev"]
 local _3ffetchSubmodules = _arg_4_["?fetchSubmodules"] local cmd = "nix"


 local args









 local function _6_() if (_3ffetchSubmodules == "true") then
 return {"--fetch-submodules"} else
 return {} end end args = concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two({}, {"run"}), {"nixpkgs#nix-prefetch-git"}), {"--"}), {"--no-deepClone"}), {"--quiet"}), {"--url", string.format("https://www.github.com/%s/%s", owner, repo)}), {"--rev", rev}), _6_())

 return {cmd = cmd, args = args} end










 local function _9_(_7_) local _arg_8_ = _7_ local url = _arg_8_["url"]
 local rev = _arg_8_["rev"]
 local _3ffetchSubmodules = _arg_8_["?fetchSubmodules"] local cmd = "nix-prefetch-git"


 local args






 local function _10_() if (_3ffetchSubmodules == "true") then
 return {"--fetch-submodules"} else
 return {} end end args = concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two(concat_two({}, {"run"}), {"nixpkgs#nix-prefetch-git"}), {"--"}), {"--no-deepClone"}), {"--quiet"}), {"--url", url}), {"--rev", rev}), _10_())

 return {cmd = cmd, args = args} end prefetchers = {fetchFromGitHub = {["required-cmds"] = {"nix"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _5_, extractor = nix_prefetch_git_sha256_extractor}, fetchgit = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url", "rev"}, prefetcher = _9_, extractor = nix_prefetch_git_sha256_extractor}}




 for _, prefetcher in pairs(prefetchers) do
 setmetatable(prefetcher, prefetcher_mt) end

 return {prefetchers = prefetchers}