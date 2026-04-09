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
        configurationLimit = 20;
        useOSProber = true;
        copyKernels = true;
      };
      kernel.sysctl = {
        "kernel.threads-max" = lib.mkDefault 2000000;
        # "kernel.pid-max" = lib.mkDefault 2000000;
        "fs.file-max" = lib.mkDefault 2097152;
        "vm.max_map_count" = lib.mkOverride 990 6000000;
        # "net.core.default_qdisc" = lib.mkForce "cake";
        # "net.ipv4.tcp_ecn" = 1;
        # "net.ipv4.tcp_sack" = 1;
        # "net.ipv4.tcp_dsack" = 1;
        # "net.ipv4.tcp_congestion_control" = lib.mkForce "bbr";
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
          "'^(zotero|signal|brave|nvim)$'"
          "--avoid"
          "'^(niri|noctalia-shell|kanata)$'"
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
        extraOptions = "--storage-driver btrfs --exec-opt native.cgroupdriver=systemd --bip=192.168.234.1/24";
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
      pkgs.ecryptfs
      pkgs.fscrypt-experimental
      pkgs.jq
    ];

    security = {
      sudo.extraRules = [
        {
          users = [ me.username ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
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
            "audio"
            "realtime"
            "disk"
            "libvirtd"
            "usb"
            "networkmanager"
            "docker"
          ];
          openssh.authorizedKeys.keys = me.keys;
          inherit (me) hashedPassword;
          shell = pkgs.zsh;
        };
        root = {
          openssh.authorizedKeys.keys = me.keys;
        };
      };
    };
  };
}
