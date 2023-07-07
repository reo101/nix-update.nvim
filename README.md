<div align="center">

# nix-update.nvim

Dynamically and asynchronously update attributes of *fetch-like* constructions in Nix

![License](https://img.shields.io/github/license/reo101/nix-update.nvim)
![Neovim version](https://img.shields.io/badge/Neovim-0.9-57A143?logo=neovim)

</div>

<!-- panvimdoc-ignore-start -->

![demo image](https://raw.githubusercontent.com/reo101/nix-update.nvim/images/images/multiple_fetches.png)

<!-- panvimdoc-ignore-end -->

## Installation

### Requirements

- nvim `v0.9`
- **[Optional]** [`nix-prefetch-url`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/fetchgit/nix-prefetch-git) (and possibly more, checkout the included prefetchers [here](./fnl/nix-update/prefetchers.fnl))

#### Lazy.nvim

```lua
{
    "reo101/nix-update.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    }
    config = function()
        require("nix-update").setup({
            extra_prefetchers = {},
        })
    end,
}
```

## Configuration

Lua init file:
```lua
require("nix-update").setup(opts)
```

This `setup` function accepts the following table:

```lua
require("nix-update").setup({
  -- Extra prefetcher commands
  -- table of tables, where each one looks like this:
  extra_prefetcher_cmds = {
    ["myFetch"] = {
      -- (array of strings) Array of required system commands
      ["required-cmds"] = { "cmd1", "cmd2" },
      -- (array of strings) Array of required "fetch" keys
      ["required-keys"] = { "repo", "user" },
      -- (function) Function to run to generate a command
      ["prefetcher"] = function(opts)
        -- guaranteed to be non-nil
        local repo = opts.repo
        local user = opts.user
        -- extra (nonrequired/optional) keys, could be nil
        local submodules = opts.submodules

        -- has to return a table of `cmd` and `opts`
        return {
          cmd = "cmd1",
          args = {
            "wrapped_run",
            "--",
            "cmd2",
            repo .. "/" .. user,
          },
        }
      end,
      -- (function) Function to run to extract the new data
      ["extractor"] = function(stdout)
        -- array of lines from funning the corresponding command
        local first_line = stdout[1]

        -- has to return a table with new value for the keys
        return {
          version = "v." .. first_line
        }
      end,
    },
  },
})
```

**NOTES:**
- The table is empty by default
- `required-cmds` and `required-keys` are optional
- You can override the builtin definitions by using the same name in `extra`

## Usage

Bind `prefetch_fetch` to a keymap:

```lua
-- <leader> -> Nix update -> under Cursor
vim.keymap.set("n", "<leader>nc", require("nix-update").prefetch_fetch)
```

Run it in a `Nix` file with the cursor inside a fetch:

```nix
let
  pname = "vim-fmi-cli";
  version = "0.2.0";
in {
  src = fetchFromGitHub {
    owner = "AndrewRadev";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-SOMEOUTDATEDHASH";
  };
}
```

And `nix-update` will statically evaluate all string arguments to the fetch (string literals and interpolations), precalculate the correct hash and substitute it in the right place.

```nix
let
  pname = "vim-fmi-cli";
  version = "0.2.0";
in {
  src = fetchFromGitHub {
    owner = "AndrewRadev";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-RAlvDiNvDVRNtex0aD8WESc4R/mAr7FjWtgzHWa4ZSI=";
  };
}
```

This updating mechanism allows for some pretty wild stuff, like this:

```nix
let
  pname = "vim-fmi-cli";
  version = "0.2.0";
  type = "256";
in rec {
  hash = "SOMEOUTDATEDHASH";

  src = fetchFromGitHub {
    owner = "AndrewRadev";
    repo = pname;
    rev = "v${version}";
    inherit sha256;
  };

  sha256 = "sha${type}-${hash}";
}
```

Running `prefetch_fetch` on this will figure out how to construct the current value of `sha256` AND skip the common prefix when updating it, i.e. the `sha256-` part (consisting of the string `sha`, the value of `type`, a `-` and finally the value of `hash`, which are all scattered around `let`s and `rec`s) and only update the `hash` variable to the correct suffix of the new `sha256`:

```nix
let
  pname = "vim-fmi-cli";
  version = "0.2.0";
  type = "256";
in rec {
  hash = "RAlvDiNvDVRNtex0aD8WESc4R/mAr7FjWtgzHWa4ZSI=";

  src = fetchFromGitHub {
    owner = "AndrewRadev";
    repo = pname;
    rev = "v${version}";
    inherit sha256;
  };

  sha256 = "sha${type}-${hash}";
}
```

I'm not really sure how often would this be of help but it's cool to have it nonetheless. 😄

## Development

The `lua` folder is the compilation output of all files from the `fnl` directory. Currently, this compilation is done using the [`make.fnl`](./make.fnl) script, which is meant to be run from within Neovim, like this (from the root of the repository):

```vim
:Fnlfile make.fnl
```

While using this [hotpot](https://github.com/rktjmp/hotpot.nvim) configuration:

```lua
require("hotpot").setup({
  compiler = {
    modules = {
      correlate = true,
    },
  },
})
```

Currently, there aren't any strict style guidelines being followed, except the ones derived from using [Parinfer](https://shaunlebron.github.io/parinfer) (through [parinfer-rust](https://github.com/eraserhd/parinfer-rust))

## TODO

- Provide a plain bash script that runs `fennel` manually and produces the same `lua` output
- More commands
- More prefetchers
- Simpler prefetch commands (not just system ones, maybe lua functions)
- Style guidelines (with optional enforcement)
- Telescope pickers for selective updating
- Use `plenary.nvim` for running async commands instead of hand-rolled solution

## Credits
- Original inspiration: [https://github.com/jwiegley/nix-update-el](https://github.com/jwiegley/nix-update-el)
- The Fennel language: [https://fennel-lang.org](https://fennel-lang.org)

<!-- vim: set shiftwidth=2: -->
