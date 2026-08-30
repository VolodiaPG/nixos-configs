{
  pkgs,
  flake,
  config,
  lib,
  ...
}:
let
  inherit (flake.config) me;
  cfg = config.services.base;
in
{
  options.services.base = {
    enable = lib.mkEnableOption "base system configuration (users, SSH, Docker, basic settings)";
  };

  config = lib.mkIf cfg.enable {
    documentation.enable = false;

    nix = {
      optimise = {
        persistent = true;
      };
    };

    console = {
      keyMap = lib.mkForce "fr";
    };

    systemd = {
      services.NetworkManager-wait-online.enable = lib.mkForce false;
      network.wait-online.enable = false;
      # Disable competing default OOM daemon
      oomd.enable = false;
    };

    powerManagement.enable = lib.mkDefault true;

    boot = {
      loader.grub = {
        configurationLimit = 10;
        useOSProber = true;
        copyKernels = true;
      };
      kernel.sysctl = {
        "kernel.threads-max" = lib.mkDefault 2000000;
        "fs.file-max" = lib.mkDefault 2097152;
        "vm.max_map_count" = lib.mkForce 6000000;
      };
      initrd.systemd.network.wait-online.enable = false;
    };

    i18n = {
      defaultLocale = "fr_FR.UTF-8";
      extraLocaleSettings = {
        LANGUAGE = "fr_FR.UTF-8";
        LC_ALL = "fr_FR.UTF-8";
        LC_MONETARY = "fr_FR.UTF-8";
        LC_PAPER = "fr_FR.UTF-8";
        LC_MEASUREMENT = "fr_FR.UTF-8";
        LC_TIME = "fr_FR.UTF-8";
        LC_NUMERIC = "fr_FR.UTF-8";
        LANG = "fr_FR.UTF-8";
      };
    };

    services = {
      # resolve /bin/sh, /bin/bash, etc. dynamically
      envfs.enable = true;
      upower.enable = lib.mkDefault true;
      power-profiles-daemon.enable = true;
      fail2ban = {
        enable = true;
        maxretry = 5;
        ignoreIP = [
          "127.0.0.0/8"
          "10.0.0.0/8"
          "192.168.1.0/16"
        ];
      };

      # Free memory
      earlyoom = {
        enable = true;
        freeMemThreshold = 5;
        freeSwapThreshold = 5;
        enableNotifications = true;
        extraArgs = [
          "-g" # send SIGTERM first
          "--prefer"
          "^(zotero|high-tide|legcord|signal|brave|nvim)$"
          "--avoid"
          "^(Hyprland|noctalia|kanata)$"
        ];
      };

      journald.extraConfig = ''
        SystemMaxUse=200M
        RuntimeMaxUse=50M
      '';
    };

    programs = {
      mosh.enable = true;
      nix-ld.enable = true;
      command-not-found.enable = false;
    };

    services = {
      openssh = {
        enable = true;
        allowSFTP = true;
        settings.PermitRootLogin = lib.mkForce "prohibit-password";
      };
      fwupd.enable = true;
      pcscd.enable = true;
    };

    time.timeZone = "Europe/Paris";

    virtualisation = {
      docker = {
        enable = true;
        # overlay2 is the default and works on ext4/xfs; btrfs benefits from
        # its native storage driver when the root volume is btrfs.
        extraOptions =
          (lib.optionalString (
            config.services.impermanence.enable && config.services.impermanence.fsType == "btrfs"
          ) "--storage-driver btrfs ")
          + "--exec-opt native.cgroupdriver=systemd --bip=192.168.234.1/24";
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };
    };

    programs = {
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };

    environment.systemPackages = [
      pkgs.docker-compose
      pkgs.lm_sensors
      pkgs.fscrypt-experimental
      pkgs.jq
    ];

    security = {
      # sudo.extraRules = [
      #   {
      #     users = [ me.username ];
      #     commands = [
      #       {
      #         command = "ALL";
      #         options = [ "NOPASSWD" ];
      #       }
      #     ];
      #   }
      # ];
      sudo.execWheelOnly = lib.mkForce false;
    };

    programs.zsh.enable = true;

    users = {
      mutableUsers = false;
      users = {
        "${me.username}" = {
          isNormalUser = true;
          description = me.name;
          linger = true;
          extraGroups = [
            "wheel"
            "video"
            "render"
            "audio"
            "realtime"
            "disk"
            "libvirtd"
            "usb"
            "networkmanager"
            "docker"
            "dialout"
            "plugdev"
          ];
          openssh.authorizedKeys.keys = me.keys;
          hashedPasswordFile = config.age.secrets.hashed-password.path;
          shell = pkgs.zsh;
        };
        root = {
          openssh.authorizedKeys.keys = me.keys;
        };
      };
    };
  };
}
