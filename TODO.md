- [ ] Parse literals (bools and numbers, maybe only under `toString`)
  - [x] Parse bools (as strings)
  - [ ] Parse numbers (as strings)
- [ ] Research `--arg` option for `nurl` (pass all fetcher args)
- [x] Support `mkDerivation` calls with a function

```nix
stdenv.mkDerivation (finalAttrs: {
  pname = "nix-update.nvim";
  version = "0.1.2";

  src = fetchFromGithub {
    owner = "reo101";
    repo = finalAttrs.pname; # <- should act just like if we had a rec attrset
    rev = finalAttrs.version;
  };
})
  - [ ] Document in README.md

- [ ] Support `dream2nix` `config` references (similar to `finalAttrs`)

```nix
{ config
, lib
, dream2nix
, ...
}: {
  imports = [
    dream2nix.modules.dream2nix.mkDerivation
  ];

  deps = { nixpkgs, ... }: {
    # Fetchers
    inherit (nixpkgs)
      fetchFromGitHub
      ;
  };

  name = "nix-update.nvim";
  version = "0.1.2";

  mkDerivation = {
    src = config.deps.fetchFromGithub {
      owner = "reo101";
      repo = config.name; # <- same here, should loop back to `config` from function args
      rev = config.version;
    };
  };
}
```
