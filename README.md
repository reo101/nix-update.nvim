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
- **[Optional]** [`nix-prefetch`](https://github.com/msteen/nix-prefetch) (and possibly more, checkout the included prefetchers [here](./fnl/nix-update/prefetchers.fnl))

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
            extra_prefetcher_cmds = {},
            extra_prefetcher_extractors = {},
        })
    end,
}
```

## Configuration

Lua init file:
```lua
require("nix-update").setup()
```

This `setup` function accepts the following table:

```lua
local opts = {
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
```

**NOTES:**
- The table is empty by default
- `required-cmds` and `required-keys` are optional
- You can override the builtin definitions by using the same name in `extra`

## Usage

Bind `prefetch-fetch` to a keymap:

```lua
-- <leader> -> Nix update -> under Cursor
vim.keymap.set("n", "<leader>nc", require("nix-update.fetches")["prefetch-fetch"])
```

Run it in a `Nix` file whilst in a *fetch*:

```nix
let
  date = "12.34.56";
  revision = "v${date}";
in
rec {
  src = fetchTest {
    a = "1234";
    rev = revision;
  };
}
```

## Development

The `lua` folder is the compilation output of all files from the `fnl` directory. Currently, this compilation is done using the [`make.fnl`](./make.fnl) script, which is meant to be run from within Neovim, using [hotpot](https://github.com/rktjmp/hotpot.nvim).
Currently, there aren't any strict style guidelines being followed, except the ones derived from using [Parinfer](https://shaunlebron.github.io/parinfer) (through [parinfer-rust](https://github.com/eraserhd/parinfer-rust))

## TODO

- `kebab-case` -> `snake_case` for exported functions (maybe re-export from main module?)
- Diagnostics or extmarks?
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
