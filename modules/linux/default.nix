{
  lib,
  pkgs,
  ...
}: let
  # Path to the current directory
  currentDir = ./.;

  # Read the current directory to get a list of files
  readDir = builtins.readDir currentDir;

  # Filter out non-Nix files and default.nix, then import the rest
  imports =
    builtins.map (name: import (currentDir + "/${name}"))
    (builtins.filter (name: name != "default.nix" && builtins.match ".*\\.nix$" name != null)
      (builtins.attrNames readDir));
in {
  inherit imports;

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  boot = {
    loader.grub.configurationLimit = 20;
    kernel.sysctl = {
      "kernel.threads-max" = 2000000;
      "kernel.pid-max" = 2000000;
      "fs.file-max" = 204708;
      "vm.max_map_count" = 6000000;
      "net.core.default_qdisc" = lib.mkForce "cake"; #fq_codel also works but is older
      "net.ipv4.tcp_ecn" = 1;
      "net.ipv4.tcp_sack" = 1;
      "net.ipv4.tcp_dsack" = 1;
      "net.ipv4.tcp_congestion_control" = lib.mkForce "bbr";
    };
  };

  nix = {
    settings.experimental-features = lib.mkForce "nix-command flakes";
    gc.dates = "weekly";
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };
  i18n = {
    defaultLocale = "fr_FR.UTF-8";
    extraLocaleSettings = {
      LANGUAGE = "en_US.UTF-8";
      LC_ALL = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LANG = "en_US.UTF-8";
    };
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"
      "10.0.0.0/8"
      "192.168.1.0/16"
    ];
  };

  programs = {
    mosh.enable = true;
    nix-ld.enable = true;
    command-not-found.enable = false;
  };

  # Enable SSH with password authentication disabled.
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

  # systemd.services.docker.path = with pkgs; [ zfs ];
  virtualisation = {
    docker = {
      enable = true;
      extraOptions = "--storage-driver btrfs --exec-opt native.cgroupdriver=systemd --bip=192.168.234.1/24";
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
    podman = {
      enable = true;
      autoPrune = {
        dates = "weekly";
      };
    };
  };

  # GnuPG
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    fish.enable = true;
  };

  environment.systemPackages = [
    pkgs.sshx
    pkgs.docker-compose
    pkgs.lm_sensors
  ];
  security = {
    sudo.extraRules = [
      {
        users = ["volodia"];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
    sudo.execWheelOnly = lib.mkForce false;
  };

  # security.polkit.extraConfig = ''
  #     polkit.addRule(function(action, subject) {
  #         if (action.id == "org.freedesktop.login1.suspend" ||
  #             action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
  #             action.id == "org.freedesktop.login1.hibernate" ||
  #             action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
  #         {
  #             return polkit.Result.NO;
  #         }
  #     });
  #   '';

  # Add one immutable user.
  users = {
    mutableUsers = false;
    users = {
      volodia = {
        isNormalUser = true;
        description = "Volodia P.G.";
        extraGroups = ["wheel" "video" "audio" "disk" "libvirtd" "usb" "networkmanager" "docker"]; # Enable ‘sudo’ for the user.
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpDmkY5OctLdxrPUcnRafndhDvvgw/GNYvgo4I9LrPJ341vGzwgqSi90YRvn725DkYHmEi1bN7i3W2x1AQbuvEBzxMG3BlwtEGtz+/5rIMY+5LRzB4ppN+Ju/ySbPKSD2XpVgVOCegc7ZtZ4XpAevVsi/kyg35RPNGmljEyuN1wIxBVARZXZezsGf1MHzxEqiNogeAEncPCk/P44B6xBRt9qSxshIT/23Cq3M/CpFyvbI0vtdLaVFIPox6ACwlmTgdReC7p05EefKEXaxVe61yhBquzRwLZWf6Y8VESLFFPZ+lEF0Shffk15k97zJICVUmNPF0Wfx1Fn5tQyDeGe2nA5d2aAxHqvl2mJk/fccljzi5K6j6nWNf16pcjWjPqCCOTs8oTo1f7gVXQFCzslPnuPIVUbJItE3Ui+mSTv9KF/Q9oH02FF40mSuKtq5WmntV0kACfokRJLZ6slLabo0LgVzGoixdiGwsuJbWAsNNHURoi3lYb8fMOxZ/2o4GZik= volodia@volodia-msi"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT volodia.parol-guarino@proton.me"
        ];
        hashedPassword = "$6$bK0PDtsca0mKnwX9$uZ2p6ovO9qyTI9vuutKS.X93zHYK.yp2Iw658CkWsBCBHqG4Eq9AUZlVQ4GG1d02D9Sw7i0VdqGxJDFWUS82O1";
        shell = pkgs.fish;
      };
      root = {
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpDmkY5OctLdxrPUcnRafndhDvvgw/GNYvgo4I9LrPJ341vGzwgqSi90YRvn725DkYHmEi1bN7i3W2x1AQbuvEBzxMG3BlwtEGtz+/5rIMY+5LRzB4ppN+Ju/ySbPKSD2XpVgVOCegc7ZtZ4XpAevVsi/kyg35RPNGmljEyuN1wIxBVARZXZezsGf1MHzxEqiNogeAEncPCk/P44B6xBRt9qSxshIT/23Cq3M/CpFyvbI0vtdLaVFIPox6ACwlmTgdReC7p05EefKEXaxVe61yhBquzRwLZWf6Y8VESLFFPZ+lEF0Shffk15k97zJICVUmNPF0Wfx1Fn5tQyDeGe2nA5d2aAxHqvl2mJk/fccljzi5K6j6nWNf16pcjWjPqCCOTs8oTo1f7gVXQFCzslPnuPIVUbJItE3Ui+mSTv9KF/Q9oH02FF40mSuKtq5WmntV0kACfokRJLZ6slLabo0LgVzGoixdiGwsuJbWAsNNHURoi3lYb8fMOxZ/2o4GZik= volodia@volodia-msi"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT volodia.parol-guarino@proton.me"
        ];
      };
      #microvm = {
      #  shell = pkgs.fish;
      #  openssh.authorizedKeys.keys = [
      #    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpDmkY5OctLdxrPUcnRafndhDvvgw/GNYvgo4I9LrPJ341vGzwgqSi90YRvn725DkYHmEi1bN7i3W2x1AQbuvEBzxMG3BlwtEGtz+/5rIMY+5LRzB4ppN+Ju/ySbPKSD2XpVgVOCegc7ZtZ4XpAevVsi/kyg35RPNGmljEyuN1wIxBVARZXZezsGf1MHzxEqiNogeAEncPCk/P44B6xBRt9qSxshIT/23Cq3M/CpFyvbI0vtdLaVFIPox6ACwlmTgdReC7p05EefKEXaxVe61yhBquzRwLZWf6Y8VESLFFPZ+lEF0Shffk15k97zJICVUmNPF0Wfx1Fn5tQyDeGe2nA5d2aAxHqvl2mJk/fccljzi5K6j6nWNf16pcjWjPqCCOTs8oTo1f7gVXQFCzslPnuPIVUbJItE3Ui+mSTv9KF/Q9oH02FF40mSuKtq5WmntV0kACfokRJLZ6slLabo0LgVzGoixdiGwsuJbWAsNNHURoi3lYb8fMOxZ/2o4GZik= volodia@volodia-msi"
      #    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT volodia.parol-guarino@proton.me"
      #  ];
      #};
    };
  };
}
