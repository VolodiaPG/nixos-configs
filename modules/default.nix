{
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _pkg: true;
  };

  # Make sure all user services do actually start
  users.users.volodia.linger = true;

  programs = {
    nix-index = {
      enable = true;
    };
  };
  nix = {
    settings = {
      keep-outputs = true;
      keep-derivations = true;
      warn-dirty = false;
      build-users-group = "nixbld";
      builders-use-substitutes = true;
      max-jobs = "auto";
      cores = 0;
      log-lines = 50;
      fallback = true;

      allowed-users = [
        "root"
        "volodia"
        "@admin"
        "@wheel"
      ];
      trusted-users = [
        "root"
        "volodia"
        "@admin"
        "@wheel"
      ];

      # Ignore global flake registry
      flake-registry = builtins.toFile "empty-registry.json" ''{"flakes": [], "version": 2}'';
    };
  };
}
