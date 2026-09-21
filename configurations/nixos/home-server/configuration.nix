{ lib, ... }:
{
  # Host-specific configuration
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        # Single-OS headless box: probing for foreign installs only slows down
        # every rebuild. (my.base turns it on for the dual-boot machines.)
        useOSProber = lib.mkForce false;
      };
    };
    blacklistedKernelModules = [
      "iTCO_wdt"
    ];
  };

  networking = {
    hostId = "30249676";
    hostName = "home-server";
    # Wired-only, and srvos already puts us on systemd-networkd, so plain DHCP
    # from hardware-configuration.nix is enough. No NetworkManager here — it
    # would drag in ModemManager and wpa_supplicant for a box that has neither
    # a modem nor a wireless link in use.
  };

  # Headless: no display pipeline, nothing to pair over bluetooth.
  hardware.graphics.enable = false;

  # Desktop/laptop plumbing that my.base turns on for the workstations and that
  # a headless server has no use for.
  services = {
    fwupd.enable = false; # firmware is flashed by hand, on site
    pcscd.enable = false; # no smartcard reader attached
    power-profiles-daemon.enable = false; # governor is set by hardware-configuration.nix
    upower.enable = false; # nothing renders a battery icon
  };

  system.stateVersion = "22.05";
}
