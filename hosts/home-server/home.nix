{
  inputs,
  outputs,
  user,
  pkgs,
  ...
}:
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
          (with outputs.homeManagerModules; [
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
      { nix.registry.nixpkgs.flake = inputs.nixpkgs; }
    ];
  };
}
