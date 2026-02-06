{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  inherit (flake.config) me;
in
{
  imports = [
    self.darwinModules.all-modules
    inputs.home-manager.darwinModules.home-manager
    flake.inputs.agenix.darwinModules.age
    (flake.self + "/secrets/nixos.nix")
  ];

  # Enable Darwin-specific services
  services = {
    commonDarwin.enable = true;
    nixCacheProxyDarwin.enable = true;
  };

  home-manager = {
    users.${me.username} = {
      imports = [
        self.homeModules.all-modules
      ];

      # Enable home modules
      services = {
        syncthing.enable = true;
        theme-daemon.enable = true;
      };

      # Enable home modules
      commonHome.enable = true;
      interactive.enable = true;
      homePackagesPersonal.enable = true;
    };
    sharedModules = [
      (self + "/secrets/home-manager.nix")
      inputs.agenix.homeManagerModules.default
    ];
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # Darwin-specific configuration
  system = {
    stateVersion = 5;
    primaryUser = me.username;
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  # Home Manager configuration
}
