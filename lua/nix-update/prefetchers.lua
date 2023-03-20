 local _local_1_ = require("nix-update.util") local has_keys = _local_1_["has-keys"]
 local concat_two = _local_1_["concat-two"]






























 local gen_prefetcher_cmd


 local function _2_(args)
 if not has_keys(args, {"owner", "repo", "rev"}) then



 vim.notify(string.format("Missing keys: %s", vim.inspect(args)))



 return else end

 local _local_4_ = args local owner = _local_4_["owner"]
 local repo = _local_4_["repo"]
 local rev = _local_4_["rev"]
 local _3ffetchSubmodules = _local_4_["?fetchSubmodules"] local cmd = "nix-prefetch"




 local args0



 local function _8_() local _6_ do local t_5_ = _3ffetchSubmodules if (nil ~= t_5_) then t_5_ = (t_5_).value else end _6_ = t_5_ end if (_6_ == "true") then return "--fetchSubmodules" else return "" end end args0 = {"fetchFromGitHub", "--owner", owner.value, "--repo", repo.value, "--rev", rev.value, _8_()}



 return {cmd = cmd, args = args0} end




 local function _9_(args)
 if has_keys(args, {}) then

 local cmd = nil
 local args0 = nil



 return {cmd = cmd, args = args0} else return nil end end




 local function _11_(args)
 if has_keys(args, {"owner", "repo", "rev"}) then



 local _local_12_ = args local owner = _local_12_["owner"]
 local repo = _local_12_["repo"]
 local rev = _local_12_["rev"]
 local _3ffetchSubmodules = _local_12_["?fetchSubmodules"] local cmd = "nix-prefetch-git"




 local args0
 local _13_ local _15_ do local t_14_ = _3ffetchSubmodules if (nil ~= t_14_) then t_14_ = (t_14_).value else end _15_ = t_14_ end if (_15_ == "true") then _13_ = "--fetch-submodules" else _13_ = "" end args0 = {"--no-deepClone", _13_, "--quiet", string.format("https://github.com/%s/%s.git", owner.value, repo.value), rev.value}













 return {cmd = cmd, args = args0} else return nil end end gen_prefetcher_cmd = {fetchFromGitHub = _2_, buildRustPackage = _9_, fetchgit = _11_}



 local get_prefetcher_extractor


 local function _19_(res)
 return {sha256 = res[1]} end get_prefetcher_extractor = {fetchFromGitHub = _19_}

 return {["gen-prefetcher-cmd"] = gen_prefetcher_cmd, ["get-prefetcher-extractor"] = get_prefetcher_extractor}