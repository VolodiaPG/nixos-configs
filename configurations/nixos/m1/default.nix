{
  flake,
  pkgs,
  ...
}:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  # sources = pkgs.callPackage (../../../_sources/generated.nix) { };
  # asahisrc =
  #   _:
  #   pkgs.linuxPackagesFor (
  #     inputs.nixos-apple-silicon.packages.${pkgs.stdenv.system}.linux-asahi.overrideAttrs (old: {
  #       inherit (sources.fairydust) src;
  #     })
  #   );
  # asahi2 = pkgs.callPackage asahisrc { };
  # asahi = asahi2.override { _kernelPatches = config.boot.kernelPatches; };
in
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
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

  # boot.kernelPackages = lib.mkForce asahi;

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
      enable = false;
      ac = {
        # scheduler = "scx_flash";
        # args = "-w -C 0 -f";
        # extraArgs = "--primary-domain 4-7";
        # # extraArgs = "--primary-domain 0xF";
        # extraArgs = "--primary-domain performance";
        governor = "schedutil";
        scheduler = "scx_lavd";
        args = "--performance";
        extraArgs = "--cpu-pref-order 4-7";
      };
      battery = {
        # scheduler = "scx_flash";
        # args = "-I 10000 -t 10000 -s 10000 -S 1000 -f";
        # extraArgs = "--primary-domain 0-3";
        # # extraArgs = "--primary-domain 0x78";
        # extraArgs = "--primary-domain powersave";
        governor = "schedutil";
        scheduler = "scx_lavd";
        args = "--powersave";
        extraArgs = "--cpu-pref-order 0-3";
      };
    };
    # myScx = {
    #      enable = true;
    #      ac = {
    #        # scx_lavd: Latency-Aware Virtual Deadline scheduler
    #        # Best for desktop interactivity under heavy load
    #        # --autopower: Automatically adapts to system load and power profile
    #        # --performance: Forces performance mode (all cores, race-to-idle)
    #        scheduler = "scx_lavd";
    #        args = "--performance";
    #        extraArgs = "";
    #        governor = "schedutil";
    #      };
    #      battery = {
    #        # Same scheduler for battery - autopower mode handles the transition
    #        # When on battery, it automatically uses powersave characteristics
    #        scheduler = "scx_lavd";
    #        args = "--powersave";
    #        extraArgs = "";
    #        governor = "schedutil";
    #      };
    #    };
    myAnanicy.enable = true;
    virt.enable = true;
    elegantBoot.enable = true;
    hifi.enable = true;
    betterSleep.enable = true;
    # ccache.enable = true;
    caddy.enable = false;
    homeLab.enable = true;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "disk/by-label/root";
    };
    networking.enable = false;
    vpn.enable = true;

    # From nixos
    # blueman.enable = true;
    blocky.enable = false;
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
