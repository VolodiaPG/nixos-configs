{ flake, config, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./disk.nix
    ./home.nix
    (self + "/secrets/nixos.nix")
    inputs.agenix.nixosModules.default
    self.nixosModules.all-modules
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.srvos.nixosModules.server
    inputs.disko.nixosModules.disko
  ];

  # Enable services via module options
  services = {
    # Core system services
    base.enable = true;
    commonNixSettings.enable = true;

    # Hardware and kernel
    kernel.enable = true;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "sda";
      disko = true;
    };
    vpn.enable = true;
    laptopServer.enable = true;
    backlightOff.enable = true;
    networking.enable = true;

    # Media server stack
    arr.enable = false;
    caddy.enable = true;
    samba.enable = true;
    homeLab.enable = true;

    immich.enable = true;
    backup = {
      enable = true;
      paths = [
        "/data/syncthing"
        "/data/immich"
        "/home/${flake.config.me.username}/Documents"
      ];
      user = flake.config.me.hetzner-user;
      password = config.age.secrets.hetzner-token.path;
      subuser = "sub1";
    };

  };

  system.stateVersion = "22.05";
}
