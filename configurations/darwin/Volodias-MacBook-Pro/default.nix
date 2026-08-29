{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  inherit (flake.config) me;
in
{
  imports = [
    self.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    flake.inputs.agenix.darwinModules.age
    (flake.self + "/secrets/nixos.nix")
  ];

  # Enable Darwin-specific services
  services = {
    commonDarwin.enable = true;
    # nixCacheProxyDarwin.enable = false;
    commonNixSettings.enable = true;
  };

  # darwinLinuxBuilder.enable = false;

  home-manager = {
    users.${me.username} = {
      imports = [
        self.homeModules.default
      ];

      # Enable home modules
      services = {
        syncthing.enable = true;
        theme-daemon.enable = true;
      };

      # Enable home modules
      commonHome.enable = true;
      interactive.enable = true;
      chezmoi.enable = true;
      gui.enable = true;
      myneovim.enable = true;

      home.stateVersion = "22.05";
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
