 local _local_1_ = require("nix-update.util") local map = _local_1_["map"]
 local filter = _local_1_["filter"]
 local has_keys = _local_1_["has-keys"]
 local concat_two = _local_1_["concat-two"]






























 local gen_prefetcher_cmd


 local function _2_(args)

 local required_keys = {"owner", "repo", "rev"}


 if not has_keys(args, required_keys) then




 local function _3_(_241) local function _4_(_2410) return _2410 end return not vim.list_contains(map(_4_, args), _241) end vim.notify(string.format("Missing keys: %s", vim.inspect(filter(_3_, required_keys))))

 return else end

 local _local_6_ = args local owner = _local_6_["owner"]
 local repo = _local_6_["repo"]
 local rev = _local_6_["rev"]
 local _3ffetchSubmodules = _local_6_["?fetchSubmodules"] local cmd = "nix-prefetch"




 local args0



 local function _10_() local _8_ do local t_7_ = _3ffetchSubmodules if (nil ~= t_7_) then t_7_ = (t_7_).value else end _8_ = t_7_ end if (_8_ == "true") then
 return {"--fetchSubmodules"} else
 return {} end end args0 = concat_two(concat_two(concat_two(concat_two(concat_two({}, {"fetchFromGitHub"}), {"--owner", owner.value}), {"--repo", repo.value}), {"--rev", rev.value}), _10_())

 return {cmd = cmd, args = args0} end




 local function _11_(args)

 local required_keys = {}
 if has_keys(args, required_keys) then
 local cmd = nil
 local args0 = nil



 return {cmd = cmd, args = args0} else return nil end end




 local function _13_(args)

 local required_keys = {"owner", "repo", "rev"}


 if not has_keys(args, required_keys) then
 local _local_14_ = args local owner = _local_14_["owner"]
 local repo = _local_14_["repo"]
 local rev = _local_14_["rev"]
 local _3ffetchSubmodules = _local_14_["?fetchSubmodules"] local cmd = "nix-prefetch-git"




 local args0
 local function _18_() local _16_ do local t_15_ = _3ffetchSubmodules if (nil ~= t_15_) then t_15_ = (t_15_).value else end _16_ = t_15_ end if (_16_ == "true") then
 return {"--fetch-submodules"} else
 return {} end end args0 = concat_two(concat_two(concat_two({}, {"--no-deepClone"}), _18_()), {"--quiet", string.format("https://github.com/%s/%s.git", owner.value, repo.value), rev.value})











 return {cmd = cmd, args = args0} else return nil end end gen_prefetcher_cmd = {fetchFromGitHub = _2_, buildRustPackage = _11_, fetchgit = _13_}



 local get_prefetcher_extractor


 local function _20_(res)
 return {sha256 = res[1]} end get_prefetcher_extractor = {fetchFromGitHub = _20_}

 return {["gen-prefetcher-cmd"] = gen_prefetcher_cmd, ["get-prefetcher-extractor"] = get_prefetcher_extractor}