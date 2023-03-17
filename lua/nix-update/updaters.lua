 local function any(tbl, p_3f)
 for k, v in pairs(tbl) do
 if p_3f(k, v) then
 return true else end end return false end


 local function all(tbl, p_3f)
 for k, v in pairs(tbl) do
 if not p_3f(k, v) then
 return false else end end return true end


 local function has_keys(tbl, keys)

 local function _3_(_, key)

 local function _4_(k, _0)
 return (k == key) end return any(tbl, _4_) end return all(keys, _3_) end

 local function concat_two(xss, yss)
 for _, ys in ipairs(yss) do
 table.insert(xss, ys) end
 return xss end








 local updaters


 local function _5_(args)
 if has_keys(args, {"owner", "repo", "rev"}) then



 local _local_6_ = args local owner = _local_6_["owner"]
 local repo = _local_6_["repo"]
 local rev = _local_6_["rev"]
 local _3fsubmodules = _local_6_["?submodules"] local cmd = "nix-prefetch-git"




 local args0
 local function _10_() local _8_ do local t_7_ = _3fsubmodules if (nil ~= t_7_) then t_7_ = (t_7_).value else end _8_ = t_7_ end if (_8_ == "true") then
 return {"--fetch-submodules"} else

 return {} end end args0 = concat_two(concat_two(concat_two({}, {"--no-deepClone"}), _10_()), {"--quiet", string.format("https://github.com/%s/%s.git", owner.value, repo.value), rev.value})







 local res = vim.fn.system(concat_two(concat_two({}, {cmd}), args0))

 return res else return nil end end


 local function _12_(args) return "todo" end




 local function _13_(args) return "todo" end




 local function _14_(args) return "todo" end




 local function _15_(args) return "todo" end




 local function _16_(args) return "todo" end




 local function _17_(args) return "todo" end updaters = {fetchFromGitHub = _5_, fetchFromGitLab = _12_, fetchgit = _13_, fetchurl = _14_, fetchzip = _15_, compileEmacsWikiFile = _16_, fetchPypi = _17_}


 return updaters