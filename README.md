<div align="center">

# nix-update.nvim

Dynamically and asynchronously update attributes of *fetch-like* constructions in Nix

![License](https://img.shields.io/github/license/reo101/nix-update.nvim)
![Neovim version](https://img.shields.io/badge/Neovim-0.13%2B-57A143?logo=neovim)

</div>

<!-- panvimdoc-ignore-start -->

[![demo](https://asciinema.org/a/597049.svg)](https://asciinema.org/a/597049?autoplay=1)

<!-- panvimdoc-ignore-end -->

## Installation

### Requirements

- nvim 0.13+ (uses `vim.async`)
- **[Optional]** [`nix-prefetch-url`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/fetchgit/nix-prefetch-git) (and possibly more, checkout the included prefetchers [here](./fnl/nix-update/prefetchers.fnl))

#### Lazy.nvim

```lua
{
    "reo101/nix-update.nvim",
    -- setup() is optional; call it only when overriding defaults
    opts = {
      update_actions = { "apply", "flash", "notify" },
    },
    config = function(_, opts)
      require("nix-update").setup(opts)
    end,
}
```

## Configuration

`setup()` is optional and only configures options.
Commands and `<Plug>` mappings are auto-registered on startup.

Recommended global config (source of truth):
```lua
vim.g.nix_update = {
  update_actions = { "apply", "notify" },
  extra_prefetchers = {
    -- ...
  },
}
```

Lua init file (only needed when customizing options):
```lua
require("nix-update").setup(opts)
```

`setup(opts)` merges your overrides into `vim.g.nix_update` and reapplies config.

This `setup` function accepts the following table:

### Update Actions

| Action    | Description                                                  |
|-----------|--------------------------------------------------------------|
| `apply`   | Apply the update to the buffer (modifies the text)           |
| `flash`   | Briefly highlight the changed region using `vim.hl.range`    |
| `notify`  | Show a `vim.notify` message with update details              |
| `preview` | Show the update as virtual text overlay (without applying)   |

```lua
require("nix-update").setup({
  -- Actions to run on each update (in order)
  -- Default: { "apply", "notify" }
  update_actions = { "apply", "flash", "notify" },

  -- Extra prefetchers
  extra_prefetchers = {
    -- fun(args: table<string, string>): vim.async.Task<table<string, string>>
    -- Create a new task for each request
    myLuaFetch = function(args)
      return vim.async.run(function()
        assert(args.url, "url is required")
        -- Await work with vim.async.await(...) here
        return { hash = "sha256-..." }
      end)
    end,

    -- Callable after setup:
    -- fun(args: table<string, string>): vim.async.Task<table<string, string>>
    ["myCommandFetch"] = {
      -- string[]? Required system commands
      ["required-cmds"] = { "cmd1", "cmd2" },
      -- (string|string[])[]? Required fetch keys; nested lists mean any-of
      ["required-keys"] = { "repo", "user" },
      -- fun(opts: table<string, string>): { cmd: string, args: string[] }
      -- Generate the command
      ["prefetcher"] = function(opts)
        -- guaranteed to be non-nil
        local repo = opts.repo
        local user = opts.user
        -- extra (nonrequired/optional) keys, could be nil
        local submodules = opts.submodules

        -- Return a table with `cmd` and `args`
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
      -- fun(stdout: string[]): table<string, string>
      -- Extract replacement fields from the command output
      ["extractor"] = function(stdout)
        -- Array of lines from the command output
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

### Prefetcher tasks

A task factory is a function that creates a task per request.
Lua prefetchers receive resolved fetch fields and must return a new
`vim.async.Task`. Inside the task, use `vim.async.await()` to wait for other
work. Return a table of replacement fields with string values.
To report a failure, raise an error inside the task.

Command tables are task factories too. During setup, the plugin makes each
command table callable. Calling the table creates a task that validates its
requirements, runs the command, and returns the extracted fields.
Both `prefetcher` and `extractor` functions are required.
Nonzero command exit codes fail the task, even when the command writes output.

The plugin awaits each task before it applies the returned fields.
Do not detach the task. Cancelling a request cancels its attached tasks.

Wrap existing synchronous prefetcher bodies in `vim.async.run(function() ... end)`.

> [!WARNING]
> Direct field returns and the `done` callback API are no longer supported.
> For callback-based work, use `vim.async.await()` inside the task instead.

- `extra_prefetchers` is empty by default.
- `required-cmds` and `required-keys` are optional for command tables.
- Use a builtin name to override its prefetcher.
- `extra_prefetcher_cmds` remains an alias for `extra_prefetchers`.
- Invalid configuration is reported with `vim.notify(..., ERROR)`.

## Usage

Run updates with the scoped command:

```vim
:NixUpdate prefetch   " update fetch under cursor
:NixUpdate buffer     " update all fetches in current buffer
:NixUpdate health     " open checkhealth output
:NixUpdate help       " open :h nix-update
```

Legacy alias (kept for compatibility):

```vim
:NixPrefetch          " same as :NixUpdate buffer
```

Bind the provided `<Plug>` mappings:

```lua
vim.keymap.set("n", "<leader>nc", "<Plug>(NixUpdatePrefetch)")
vim.keymap.set("n", "<leader>nC", "<Plug>(NixUpdatePrefetchBuffer)")
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

### Function-style derivations

`finalAttrs` in function-style `mkDerivation` calls and dream2nix's `config`
references resolve like recursive attribute sets:

```nix
stdenv.mkDerivation (finalAttrs: {
  pname = "nix-update.nvim";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "reo101";
    repo = finalAttrs.pname;
    rev = finalAttrs.version;
    hash = "sha256-SOMEOUTDATEDHASH";
  };
})
```

## Development

The `lua` folder is the compilation output of all files from the `fnl` directory.

### Using nfnl (recommended)

The project uses [nfnl](https://github.com/Olical/nfnl) for Fennel compilation. When you have nfnl installed in Neovim, saving any `.fnl` file will automatically compile it to `lua/`.

### Nix Development Shell (recommended)

The repository ships a pinned `flake.nix` (using `flake-parts`) so local checks and CI run against the same Neovim build from pinned `nixpkgs`.

Enter the shell:

```bash
nix develop .#default
```

Run checks in the CI-equivalent shell:

```bash
nix develop .#ci -c make check
```

Regenerate `doc/nix-update.txt` locally:

```bash
nix develop .#default -c make docs
```

To compile all files at once:

```vim
:NfnlCompileAllFiles
```

Or via the Makefile (requires `nvim` with nfnl in `$PATH`):

```bash
make
```

### Using standalone Fennel

Alternatively, you can compile using the standalone Fennel compiler:

```bash
make fennel
```

> [!NOTE]
> Requires `fennel` (version `1.2.0`) in your `$PATH`

### Cleaning

Clear the compilation output (the `lua` folder):

```bash
make clean
```

### Checks

Run project checks (compilation + runtime smoke checks):

```bash
make check
```

For reproducible checks with pinned tooling:

```bash
nix develop .#ci -c make check
```

Use `:checkhealth nix-update` to inspect runtime/config/dependency health.

## Credits
- Original inspiration: [https://github.com/jwiegley/nix-update-el](https://github.com/jwiegley/nix-update-el)
- The Fennel language: [https://fennel-lang.org](https://fennel-lang.org)

<!-- vim: set shiftwidth=2: -->
