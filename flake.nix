{
  description = "nix-update.nvim development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    fennel-src = {
      url = "github:reo101/Fennel/feat/discard-rebased";
      flake = false;
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    panvimdoc-src = {
      url = "github:kdheepak/panvimdoc/v4.0.1";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ ... }:
      {
        systems = import inputs.systems;

        perSystem =
          {
            system,
            ...
          }:
          let
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.neovim-nightly-overlay.overlays.default
              ];
            };
            fennel = pkgs.stdenv.mkDerivation {
              pname = "fennel";
              version = "1.7.0-dev-discard";
              src = inputs.fennel-src;
              buildInputs = [ pkgs.luajit ];
              makeFlags = [
                "PREFIX=$(out)"
                "LUA=${pkgs.lib.getExe pkgs.luajit}"
              ];
            };
          in
          {
            devShells.default = pkgs.mkShell {
              packages = [
                pkgs.neovim
                pkgs.git
                pkgs.pandoc
                fennel
              ];

              PANVIMDOC = "${inputs.panvimdoc-src}/panvimdoc.sh";
            };

            devShells.ci = pkgs.mkShell {
              packages = [
                pkgs.neovim
                pkgs.git
                pkgs.pandoc
                pkgs.tree-sitter-grammars.tree-sitter-nix
                fennel
              ];

              PANVIMDOC = "${inputs.panvimdoc-src}/panvimdoc.sh";
              NIX_UPDATE_NIX_PARSER =
                "${pkgs.tree-sitter-grammars.tree-sitter-nix}/parser";
            };
          };
      });
}
