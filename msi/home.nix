{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  inherit (flake.config) me;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    users."${me.username}" = {
      imports = [
        self.homeModules.all-modules
      ];

      # Enable home modules
      services = {
        commonHome.enable = true;
        syncthing.enable = true;
      };
      programs = {
        git.enable = true;
        ssh.enable = true;
      };
    };

    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      (self + "/secrets/home-manager.nix")
      inputs.agenix.homeManagerModules.default
      inputs.catppuccin.homeModules.catppuccin
      inputs.nix-index-database.homeModules.nix-index
    ];
  };
}
