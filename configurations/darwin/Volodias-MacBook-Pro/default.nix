{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  # Define user inline - can be moved to flake.specialArgs if needed
  user = "volodia";
in
{
  imports = [
    self.darwinModules.default
  ];

  # Darwin-specific configuration
  system = {
    stateVersion = 5;
    primaryUser = user;
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  # Home Manager configuration
  home-manager = {
    users.${user} =
      {
        lib,
        config,
        pkgs,
        ...
      }:
      {
        imports = lib.flatten [
          (with self.homeModules; [
            (common-home {
              inherit pkgs lib config;
              inherit user;
            })
            (git {
              inherit pkgs;
              inherit user;
            })
            (zsh {
              inherit
                pkgs
                lib
                config
                inputs
                ;
            })
            (ssh {
              inherit pkgs;
              inherit user;
            })
            syncthing
            mail
            packages-personal
          ])
        ];
      };
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = flake.specialArgs;
    sharedModules = [
      ../../../secrets/home-manager.nix
      inputs.agenix.homeManagerModules.default
      inputs.catppuccin.homeModules.catppuccin
      inputs.nix-index-database.homeModules.nix-index
    ];
  };
}
