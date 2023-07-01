 local _local_1_ = require("nix-update.util") local concat_two = _local_1_["concat-two"]
 local prefetcher_cmd_mt = _local_1_["prefetcher-cmd-mt"]






































 local prefetchers








 local function _4_(_2_) local _arg_3_ = _2_ local owner = _arg_3_["owner"]
 local repo = _arg_3_["repo"]
 local rev = _arg_3_["rev"]
 local _3ffetchSubmodules = _arg_3_["?fetchSubmodules"] local cmd = "nix-prefetch"


 local args





 local function _5_() if (_3ffetchSubmodules == "true") then
 return {"--fetch-submodules"} else
 return {} end end args = concat_two(concat_two(concat_two(concat_two({}, {"--quiet"}), {"--url", string.format("https://www.github.com/%s/%s", owner, repo)}), {"--rev", rev}), _5_())

 return {cmd = cmd, args = args} end



 local function _6_(stdout)
 return {sha256 = vim.json.decode(table.concat(stdout)).sha256} end










 local function _9_(_7_) local _arg_8_ = _7_
 local cmd = nil

 local args = nil



 return {cmd = cmd, args = args} end


 local function _10_(stdout)
 return {} end








 local function _13_(_11_) local _arg_12_ = _11_ local owner = _arg_12_["owner"]
 local repo = _arg_12_["repo"]
 local rev = _arg_12_["rev"]
 local _3ffetchSubmodules = _arg_12_["?fetchSubmodules"] local cmd = "nix-prefetch-git"


 local args
 local function _17_() local _15_ do local t_14_ = _3ffetchSubmodules if (nil ~= t_14_) then t_14_ = (t_14_).value else end _15_ = t_14_ end if (_15_ == "true") then
 return {"--fetch-submodules"} else
 return {} end end args = concat_two(concat_two(concat_two({}, {"--no-deepClone"}), _17_()), {"--quiet", string.format("https://github.com/%s/%s.git", owner, repo), rev})







 return {cmd = cmd, args = args} end


 local function _18_(stdout)
 return {} end prefetchers = {fetchFromGitHub = {["required-cmds"] = {"nix-prefetch-git"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _4_, extractor = _6_}, buildRustPackage = {["required-cmds"] = {}, ["required-keys"] = {}, prefetcher = _9_, extractor = _10_}, fetchgit = {["required-cmds"] = {}, ["required-keys"] = {"owner", "repo", "rev"}, prefetcher = _13_, extractor = _18_}}


 for _, prefetcher in pairs(prefetchers) do
 setmetatable(prefetcher, prefetcher_cmd_mt) end

 return {prefetchers = prefetchers}