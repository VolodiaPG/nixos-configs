# home-server — headless laptop acting as NAS / k3s node / backup target.
{ flake, config, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  inherit (flake.config) me;
in
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./disk.nix
    ./home.nix
    (self + "/secrets/nixos.nix")
    inputs.agenix.nixosModules.default
    self.nixosModules.default
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.srvos.nixosModules.server
    inputs.disko.nixosModules.disko
    inputs.determinate.nixosModules.default
  ];

  # Options defined by this repo (modules/nixos/*.nix).
  my = {
    # Core system
    base.enable = true;
    nixSettings.enable = true;

    # Hardware and kernel
    kernel = {
      enable = true;
      serverNetworking = true;
      cachyServer = false;
    };
    laptopServer.enable = true;
    backlightOff.enable = true;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "/dev/sda3";
      disko = true;
    };
    networking.enable = true;
    vpn.enable = true;

    # Services
    kubernetes.enable = true;
    arr.enable = false;
    homeLab.enable = false;

    backup = {
      enable = true;
      paths = [
        "/data/syncthing"
        "/data/immich"
        "/home/${me.username}/Documents"
      ];
      user = me.hetzner-user;
      passwordFile = config.age.secrets.hetzner-token.path;
      subuser = "sub1";
    };
  };

  # Upstream NixOS options. `samba`, `caddy` and `immich` are also extended by
  # modules/nixos/{samba,caddy,immich}.nix, which key off these `enable` flags.
  services = {
    samba.enable = true;
    caddy.enable = false;
    immich.enable = false;
  };
}
