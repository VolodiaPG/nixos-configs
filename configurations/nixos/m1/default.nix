{ flake, pkgs, ... }:
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
    self.nixosModules.all-modules
    inputs.nixos-apple-silicon.nixosModules.default
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-laptop
    common-pc-laptop-ssd
  ]);
  #hardware.asahi.pkgs = lib.mkForce inputs.nixos-apple-silicon.packages.aarch64-linux;
  #boot.kernelPackages = lib.mkForce (inputs.nixos-apple-silicon.inputs.nixpkgs.legacyPackages.aarch64-linux.linuxPackagesFor inputs.nixos-apple-silicon.packages.aarch64-linux.linux-asahi);
  # Enable services via module options
  services = {
    # Core system services
    base.enable = true;
    commonNixSettings.enable = true;
    nixCacheProxy.enable = true;
    wm = {
      enable = true;
      gnome.enable = false;
      niri = {
        enable = true;
      };
    };

    # Display manager for niri (since GNOME/GDM is disabled)
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
          user = "greeter";
        };
      };
    };

    # Hardware and kernel
    kernel.enable = true;
    myScx = {
      enable = true;
      ac = {
        # scheduler = "scx_flash";
        # args = "-w -C 0 -f";
        # # extraArgs = "--primary-domain 4-7";
        # # extraArgs = "--primary-domain 0xF";
        # extraArgs = "--primary-domain performance";
        # governor = "schedutil";
        scheduler = "scx_lavd";
        args = "--performance";
        extraArgs = "--cpu-pref-order 4-7";
      };
      battery = {
        # scheduler = "scx_flash";
        # args = "-I 10000 -t 10000 -s 10000 -S 1000 -f";
        # # extraArgs = "--primary-domain 0-3";
        # # extraArgs = "--primary-domain 0x78";
        # extraArgs = "--primary-domain powersave";
        # governor = "schedutil";
        scheduler = "scx_lavd";
        args = "--powersave";
        extraArgs = "--cpu-pref-order 0-3";
      };
    };
    virt.enable = true;
    elegantBoot.enable = true;
    hifi.enable = true;
    betterSleep.enable = true;
    # ccache.enable = true;
    caddy.enable = true;
    homeLab.enable = true;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "disk/by-label/root";
    };
    vpn.enable = true;

    # From nixos
    # blueman.enable = true;
  };

  systemd = {
    slices = {
      # "pcore.slice" = {
      #   description = "P-core high performance slice";
      #   sliceConfig = {
      #     AllowedCPUs = "";
      #     CPUWeight = 100;
      #   };
      # };
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
