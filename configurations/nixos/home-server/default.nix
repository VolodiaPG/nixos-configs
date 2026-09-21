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
      cachyServer = true;
    };
    # Lid stays closed, panel is blanked by `consoleblank=60`; that makes
    # my.backlightOff (a logind poll every minute, which also force-loads i915)
    # redundant here.
    laptopServer.enable = true;

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

  # Upstream NixOS option; modules/nixos/samba.nix keys off this `enable` flag
  # to add the shares, the mDNS/WSD discovery and the Samba user.
  services.samba.enable = true;
}
