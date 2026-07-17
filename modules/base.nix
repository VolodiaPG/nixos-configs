{
  config,
  ...
}:
let
  inherit (config) me;
in
{
  config.nixos.base =
    {
      pkgs,
      lib,
      ...
    }:
    {
      nix.optimise.persistent = true;

      console.keyMap = lib.mkForce "fr";

      systemd = {
        services.NetworkManager-wait-online.enable = lib.mkForce false;
        network.wait-online.enable = false;
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
          "fs.file-max" = lib.mkDefault 2097152;
          "vm.max_map_count" = lib.mkOverride 990 6000000;
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
        earlyoom = {
          enable = true;
          freeMemThreshold = 5;
          freeSwapThreshold = 5;
          enableNotifications = true;
          extraArgs = [
            "-g"
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
        openssh = {
          enable = true;
          allowSFTP = true;
          settings.PermitRootLogin = lib.mkForce "prohibit-password";
        };
        fwupd.enable = true;
        pcscd.enable = true;
      };

      programs = {
        mosh.enable = true;
        nix-ld.enable = true;
        command-not-found.enable = false;
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
        };
        zsh.enable = true;
      };

      time.timeZone = "Europe/Paris";

      virtualisation.docker = {
        enable = true;
        extraOptions = "--storage-driver btrfs --exec-opt native.cgroupdriver=systemd --bip=192.168.234.1/24";
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      environment.systemPackages = [
        pkgs.docker-compose
        pkgs.lm_sensors
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
