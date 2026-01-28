-- [nfnl] fnl/nix-update/prefetchers.fnl
local _local_1_ = require("nix-update.utils")
local prefetcher_mt = _local_1_["prefetcher-mt"]
local nurl_json_hash_extractor
local function _2_(stdout)
  local hash = vim.json.decode(table.concat(stdout)).args.hash
  return {hash = hash}
end
nurl_json_hash_extractor = _2_
local nix_json_hash_extractor
local function _3_(stdout)
  local hash = vim.json.decode(table.concat(stdout)).hash
  return {hash = hash}
end
nix_json_hash_extractor = _3_
local prefetchers
local function _5_(_4_)
  local owner = _4_.owner
  local repo = _4_.repo
  local rev = _4_.rev
  local tag = _4_.tag
  local fetchSubmodules = _4_.fetchSubmodules
  local cmd = "nurl"
  local ref = (rev or tag)
  local args = {"--json", string.format("--submodules=%s", (fetchSubmodules or "false")), string.format("https://www.github.com/%s/%s", owner, repo), ref}
  return {cmd = cmd, args = args}
end
local function _7_(_6_)
  local owner = _6_.owner
  local repo = _6_.repo
  local rev = _6_.rev
  local tag = _6_.tag
  local fetchSubmodules = _6_.fetchSubmodules
  local cmd = "nurl"
  local ref = (rev or tag)
  local args = {"--json", string.format("--submodules=%s", (fetchSubmodules or "false")), string.format("https://www.gitlab.com/%s/%s", owner, repo), ref}
  return {cmd = cmd, args = args}
end
local function _9_(_8_)
  local url = _8_.url
  local name = _8_.name
  local cmd = "nix"
  local args
  local _10_
  if name then
    _10_ = {"--name", name}
  else
    _10_ = {}
  end
  args = vim.iter({{"store"}, {"prefetch-file"}, {"--json"}, {"--hash-type", "sha256"}, _10_, {url}}):flatten():totable()
  return {cmd = cmd, args = args}
end
local function _13_(_12_)
  local url = _12_.url
  local cmd = "nix"
  local args = {"store", "prefetch-file", "--json", "--hash-type", "sha256", url}
  return {cmd = cmd, args = args}
end
local function _15_(_14_)
  local url = _14_.url
  local rev = _14_.rev
  local fetchSubmodules = _14_.fetchSubmodules
  local cmd = "nurl"
  local args = {"--json", "--fetcher", "builtins.fetchGit", string.format("--submodules=%s", (fetchSubmodules or "false")), url, rev}
  return {cmd = cmd, args = args}
end
prefetchers = {fetchFromGitHub = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", {"tag", "rev"}}, prefetcher = _5_, extractor = nurl_json_hash_extractor}, fetchFromGitLab = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"owner", "repo", {"tag", "rev"}}, prefetcher = _7_, extractor = nurl_json_hash_extractor}, fetchurl = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _9_, extractor = nix_json_hash_extractor}, fetchpatch = {["required-cmds"] = {"nix"}, ["required-keys"] = {"url"}, prefetcher = _13_, extractor = nix_json_hash_extractor}, fetchgit = {["required-cmds"] = {"nurl"}, ["required-keys"] = {"url", "rev"}, prefetcher = _15_, extractor = nurl_json_hash_extractor}}
for _, prefetcher in pairs(prefetchers) do
  setmetatable(prefetcher, prefetcher_mt)
end
return {prefetchers = prefetchers}
