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
        syncthing.enable = true;
      };
      commonHome.enable = true;
      catppuccin.enable = false;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      (self + "/secrets/home-manager.nix")
      inputs.agenix.homeManagerModules.default
    ];
  };
}
