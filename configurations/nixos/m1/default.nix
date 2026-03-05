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
    laputil.enable = false;
    virt.enable = true;
    elegantBoot.enable = true;
    hifi.enable = true;
    betterSleep.enable = true;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "disk/by-label/root";
    };
    vpn.enable = true;
  };
}
