 local _local_1_ = require("nix-update.util") local concat_two = _local_1_["concat-two"]
 local prefetcher_cmd_mt = _local_1_["prefetcher-cmd-mt"]






























 local prefetcher_cmds







 local function _4_(_2_) local _arg_3_ = _2_ local owner = _arg_3_["owner"]
 local repo = _arg_3_["repo"]
 local rev = _arg_3_["rev"]
 local _3ffetchSubmodules = _arg_3_["?fetchSubmodules"] local cmd = "nix-prefetch"


 local args



 local function _8_() local _6_ do local t_5_ = _3ffetchSubmodules if (nil ~= t_5_) then t_5_ = (t_5_).value else end _6_ = t_5_ end if (_6_ == "true") then
 return {"--fetchSubmodules"} else
 return {} end end args = concat_two(concat_two(concat_two(concat_two(concat_two({}, {"fetchFromGitHub"}), {"--owner", owner}), {"--repo", repo}), {"--rev", rev}), _8_())

 return {cmd = cmd, args = args} end







 local function _11_(_9_) local _arg_10_ = _9_
 local cmd = nil

 local args = nil



 return {cmd = cmd, args = args} end









 local function _14_(_12_) local _arg_13_ = _12_ local owner = _arg_13_["owner"]
 local repo = _arg_13_["repo"]
 local rev = _arg_13_["rev"]
 local _3ffetchSubmodules = _arg_13_["?fetchSubmodules"] local cmd = "nix-prefetch-git"


 local args
 local function _18_() local _16_ do local t_15_ = _3ffetchSubmodules if (nil ~= t_15_) then t_15_ = (t_15_).value else end _16_ = t_15_ end if (_16_ == "true") then
 return {"--fetch-submodules"} else
 return {} end end args = concat_two(concat_two(concat_two({}, {"--no-deepClone"}), _18_()), {"--quiet", string.format("https://github.com/%s/%s.git", owner, repo), rev})











 return {cmd = cmd, args = args} end prefetcher_cmds = {fetchFromGitHub = {["required-cmds"] = {"nix-prefetch"}, ["required-keys"] = {"owner", "repo", "rev"}, prefetch = _4_}, buildRustPackage = {["required-cmds"] = {}, ["required-keys"] = {}, prefetch = _11_}, fetchgit = {["required-cmds"] = {}, ["required-keys"] = {"owner", "repo", "rev"}, prefetch = _14_}}



 local prefetcher_extractors


 local function _19_(stdout)
 return {sha256 = stdout[1]} end prefetcher_extractors = {fetchFromGitHub = _19_}


 for _, prefetcher in pairs(prefetcher_cmds) do
 setmetatable(prefetcher, prefetcher_cmd_mt) end

 return {["prefetcher-cmds"] = prefetcher_cmds, ["prefetcher-extractors"] = prefetcher_extractors}