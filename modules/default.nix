{
  config,
  pkgs,
  ...
}: {
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _pkg: true;
  };

  nix = {
    # package = pkgs.nixFlakes;
    package = pkgs.nixVersions.unstable;
    gc = {
      automatic = true;
      # dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # package = pkgs.nix;
    settings = {
      # experimental-features = "nix-command flakes";
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
