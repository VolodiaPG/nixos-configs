{
  flake,
  ...
}:
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
        theme-daemon.enable = true;
      };
      # Enable home modules
      commonHome.enable = true;
      interactive.enable = true;
      homePackagesPersonal.enable = true;
      gui.enable = true;
      wm.gnome.enable = false;
      wm.niri.enable = true;

      home.stateVersion = "22.05";
    };

    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      (self + "/secrets/home-manager.nix")
      inputs.agenix.homeManagerModules.default
    ];

  };
}
