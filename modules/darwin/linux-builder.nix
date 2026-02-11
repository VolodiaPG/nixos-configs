{
  config,
  lib,
  flake,
  ...
}:
with lib;
with types;
let
  inherit (flake) inputs;
  cfg = config.darwinLinuxBuilder;
in
{
  options = {
    darwinLinuxBuilder = {
      enable = mkEnableOption "Darwin Linux Builder, using rosetta";
    };
  };

  imports = [
    inputs.nix-rosetta-builder.darwinModules.default
  ];

  config = mkIf cfg.enable {

    # To bootstrap: https://github.com/nix-darwin/nix-darwin/issues/1081#issuecomment-3367128960
    # To first install a cached version of darwin linux-builder, add this to the flake.nix
    # nixpkgs-linux-builder.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";

    nix.linux-builder = {
      enable = false;
      package = inputs.nixpkgs-linux-builder.legacyPackages.aarch64-darwin.darwin.linux-builder;
      ephemeral = true;
      maxJobs = 4;
      config = {
        virtualisation = {
          darwin-builder = {
            diskSize = 40 * 1024;
            memorySize = 8 * 1024;
          };
          cores = 6;
        };
      };
    };

    nix-rosetta-builder = {
      enable = true;
      onDemand = true;
      onDemandLingerMinutes = 30;
    };
  };
}
