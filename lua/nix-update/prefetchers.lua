 local _local_1_ = require("nix-update.util") local map = _local_1_["map"]
 local filter = _local_1_["filter"]
 local has_keys = _local_1_["has-keys"]
 local concat_two = _local_1_["concat-two"]






























 local gen_prefetcher_cmd






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











 return {cmd = cmd, args = args} end gen_prefetcher_cmd = {fetchFromGitHub = {keys = {"owner", "repo", "rev"}, prefetch = _4_}, buildRustPackage = {["required-keys"] = {}, prefetch = _11_}, fetchgit = {["required-keys"] = {"owner", "repo", "rev"}, prefetch = _14_}}



 local get_prefetcher_extractor


 local function _19_(stdout)
 return {sha256 = stdout[1]} end



 local function _20_(stdout)
 return {rev = stdout[1]} end get_prefetcher_extractor = {fetchFromGitHub = _19_, fetchTest = _20_}


 do local mt
 local function _21_(self, args)
 if not has_keys(args, self["required-keys"]) then





 local function _22_(_241) return not vim.list_contains(vim.tbl_keys(args), _241) end vim.notify(string.format("Missing keys: %s", vim.inspect(filter(_22_, self["required-keys"]))))



 return else end

 return self.prefetch(args) end mt = {__call = _21_}
 for _, prefetcher in pairs(gen_prefetcher_cmd) do
 setmetatable(prefetcher, mt) end end

 return {["gen-prefetcher-cmd"] = gen_prefetcher_cmd, ["get-prefetcher-extractor"] = get_prefetcher_extractor}