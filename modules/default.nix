{
  config,
  pkgs,
  ...
}: let
  # Path to the current directory
  currentDir = ./.;

  # Read the current directory to get a list of files
  readDir = builtins.readDir currentDir;

  # Filter out non-Nix files and default.nix, then import the rest
  imports =
    builtins.map (name: import (currentDir + "/${name}"))
    (builtins.filter (name: name != "default.nix" && builtins.match ".*\\.nix$" name != null)
      (builtins.attrNames readDir));
in {
  inherit imports;

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _pkg: true;
  };

  nix = {
    # package = pkgs.nixFlakes;
    package = pkgs.nixVersions.unstable;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # package = pkgs.nix;
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      keep-outputs = true;
      keep-derivations = true;
      warn-dirty = false;
      build-users-group = "nixbld";
      builders-use-substitutes = true;
      max-jobs = "auto";
      cores = 0;
      log-lines = 50;

      allowed-users = ["root" "volodia" "@admin" "@wheel"];
      trusted-users = ["root" "volodia" "@admin" "@wheel"];

      # Ignore global flake registry
      flake-registry = builtins.toFile "empty-registry.json" ''{"flakes": [], "version": 2}'';
    };
  };
}
