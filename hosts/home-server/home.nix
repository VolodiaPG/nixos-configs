{
  flake,
  inputs,
  outputs,
  pkgs,
  ...
}:
let
  inherit (flake.config) me;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    users."${me.username}" =
      {
        lib,
        config,
        ...
      }:
      {
        imports = lib.flatten [
          (with outputs.homeModules; [
            (common-home {
              inherit
                pkgs
                config
                me
                lib
                ;
            })
            (git { inherit pkgs me; })
            (zsh {
              inherit
                pkgs
                lib
                config
                inputs
                ;
            })
            (ssh { inherit pkgs me; })
            syncthing
          ])
        ];
      };

    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      ../../secrets/home-manager.nix
      inputs.agenix.homeManagerModules.default
      inputs.catppuccin.homeModules.catppuccin
      inputs.nix-index-database.homeModules.nix-index
    ];
  };
}
