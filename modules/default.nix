{
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _pkg: true;
  };

  programs = {
    # fish.interactiveShellInit = ''
    #   function __fish_command_not_found_handler --on-event="fish_command_not_found"
    #     ${
    #     if config.programs.fish.useBabelfish
    #     then ''
    #       command_not_found_handle $argv
    #     ''
    #     else ''
    #       ${pkgs.bashInteractive}/bin/bash -c \
    #         "source ${config.programs.nix-index.package}/etc/profile.d/command-not-found.sh; command_not_found_handle $argv"
    #     ''
    #   }
    #   end
    # '';
    nix-index = {
      enable = true;
    };
  };
  nix = {
    # package = pkgs.nixVersions.latest;
    #package = pkgs.nixVersions.unstable;
    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };
    optimise.automatic = true;

    # package = pkgs.nix;
    settings = {
      # experimental-features = "nix-command flakes";
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
