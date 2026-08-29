{
  flake,
  ...
}:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./home.nix
    (self + "/secrets/nixos.nix")
    inputs.agenix.nixosModules.default
    self.nixosModules.default
    inputs.determinate.nixosModules.default
    inputs.nixos-apple-silicon.nixosModules.default
  ];

  # Enable services via module options
  services = {
    # Core system services
    base.enable = true;
    commonNixSettings.enable = true;
    wm = {
      enable = true;
      gnome.enable = false;
      hyprland = {
        enable = true;
      };
    };

    # Hardware and kernel
    myAnanicy.enable = true;
    virtualization = {
      enable = true;
      libvirt.enable = false;
    };
    elegantBoot.enable = true;
    hifi.enable = true;
    betterSleep.enable = true;
    caddy.enable = false;
    homeLab.enable = true;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "/dev/disk/by-label/root";
    };
    networking.enable = false;
    vpn.enable = true;

    blocky.enable = false;
  };

  systemd = {
    slices = {
      "allcore.slice" = {
        sliceConfig = {
          AllowedCPUs = "0-7";
          CPUWeight = 50; # Not that important
        };
      };
      "system".sliceConfig = {
        AllowedCPUs = "0-3"; # E-cores
      };
    };
    services.nix-daemon.serviceConfig = {
      Slice = "allcore.slice";
    };
  };
}
