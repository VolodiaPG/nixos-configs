{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (flake.config) me;
  inherit (inputs) self;
in
{
  imports = [
    self.darwinModules.all-modules
    inputs.home-manager.darwinModules.home-manager
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
