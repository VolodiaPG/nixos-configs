{ flake, pkgs, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  inherit (flake.config) user;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    users."${user.username}" =
      {
        lib,
        config,
        ...
      }:
      {
        imports = lib.flatten [
          (with self.homeModules; [
            (common-home { inherit pkgs user lib; })
            (git { inherit pkgs user; })
            (zsh {
              inherit
                pkgs
                lib
                config
                inputs
                ;
            })
            (ssh { inherit pkgs user; })
            syncthing
            gnome
            mail
            mpv
            (packages-personal { inherit pkgs inputs; })
          ])
        ];
      };

    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      ../../../secrets/home-manager.nix
      inputs.agenix.homeManagerModules.default
      inputs.catppuccin.homeModules.catppuccin
      inputs.nix-index-database.homeModules.nix-index
    ];
  };
}
