{
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        #    enableCryptodisk = true;
      };
    };
    blacklistedKernelModules = [
      "nouveau"
      "iTCO_wdt" # iTCO_wdt module sometimes block kernel.nmi_watchdog = 0
    ];
  };

  zramSwap.enable = true;

  networking = {
    hostId = "30249679";
    hostName = "m1";
    networkmanager.enable = true; # Easiest to use and most distros use this by default.
  };

  hardware = {
    asahi = {
      enable = true;
      setupAsahiSound = true;
      peripheralFirmwareDirectory = ./firmware;
    };
    apple.touchBar = {
      enable = true;
      settings = {
        MediaLayerDefault = true;
        ShowButtonOutlines = false;
        AdaptiveBrightness = true;
        ActiveBrightness = 128;
        MediaLayerKeys = [
          {
            Icon = "brightness_low";
            Action = "BrightnessDown";
          }
          {
            Icon = "brightness_high";
            Action = "BrightnessUp";
          }
          {
            Icon = "mic_off";
            Action = "MicMute";
          }
          # {
          #   icon = "search";
          #   action = "Search";
          # }
          {
            Icon = "backlight_low";
            Action = "IllumDown";
          }
          {
            Icon = "backlight_high";
            Action = "IllumUp";
          }
          {
            Icon = "fast_rewind";
            Action = "PreviousSong";
          }
          {
            Icon = "play_pause";
            Action = "PlayPause";
          }
          {
            Icon = "fast_forward";
            Action = "NextSong";
          }
          {
            Icon = "volume_off";
            Action = "Mute";
          }
          {
            Icon = "volume_down";
            Action = "VolumeDown";
          }
          {
            Icon = "volume_up";
            Action = "VolumeUp";
          }
        ];
      };
    };
  };

  services = {
    openssh.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
