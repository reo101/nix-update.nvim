{
  description = "nix-update.nvim development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

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
          in
          {
            devShells.default = pkgs.mkShell {
              packages = [
                pkgs.neovim
                pkgs.git
              ];
            };

            devShells.ci = pkgs.mkShell {
              packages = [
                pkgs.neovim
                pkgs.git
              ];
            };
          };
      });
}
