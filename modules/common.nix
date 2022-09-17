{ config, pkgs, ... }:

{
  imports = [
    ./elegant-boot.nix
  ];
  environment.systemPackages = with pkgs; [
    # Terminal tools
    coreutils # Basic GNU utilities
    direnv # Load environment variables when cd'ing into a directory
    findutils # GNU find/xargs commands
    gitAndTools.gitFull # Git core installation
    gnupg # GNU Privacy Guard
    man # Documentation for everything
    p7zip # 7zip archive tools
    parallel # Much smarter xargs
    progress # View current progress of coreutils tools
    wireguard-tools # Tools for Wireguard
    zip # ZIP file manipulation
    gdu # Manager files and see sizes quickly
    topgrade # Updates any software that can be updated
    micro # text editor
    zoxide # smart CD that remembers
    gh # Github PRs and stuff
    git-crypt
    python3

    # System monitoring
    htop # Interactive TUI process viewer
    lm_sensors # Read hardware sensors
    nmap # Network scanning and more

    # File transfer
    sshfs-fuse # Mount remote filesystem over SSH with FUSE
    wget # Retrieve files from the web
  ];

  nix = {
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
    '';
    gc.automatic = true;
    gc.dates = "Sat 05:00";
    gc.options = "--delete-older-than 14d";
    package = pkgs.nixFlakes;
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
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];
  };

  # Allow unfree packages to be installed.
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Paris";

  systemd.services.docker.path = with pkgs; [ zfs ];
  virtualisation.docker = {
    enable = true;
    extraOptions = "--storage-driver zfs --exec-opt native.cgroupdriver=systemd --bip=192.168.234.1/24";
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Enable SSH with password authentication disabled.
  services.openssh = {
    enable = true;
    allowSFTP = true;
    passwordAuthentication = false;
  };

  # Add one immutable user.
  users.mutableUsers = false;
  users.users.volodia = {
    isNormalUser = true;
    description = "Volodia P.G.";
    extraGroups = [ "wheel" "video" "audio" "disk" "libvirtd" "usb" "networkManager" "docker" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpDmkY5OctLdxrPUcnRafndhDvvgw/GNYvgo4I9LrPJ341vGzwgqSi90YRvn725DkYHmEi1bN7i3W2x1AQbuvEBzxMG3BlwtEGtz+/5rIMY+5LRzB4ppN+Ju/ySbPKSD2XpVgVOCegc7ZtZ4XpAevVsi/kyg35RPNGmljEyuN1wIxBVARZXZezsGf1MHzxEqiNogeAEncPCk/P44B6xBRt9qSxshIT/23Cq3M/CpFyvbI0vtdLaVFIPox6ACwlmTgdReC7p05EefKEXaxVe61yhBquzRwLZWf6Y8VESLFFPZ+lEF0Shffk15k97zJICVUmNPF0Wfx1Fn5tQyDeGe2nA5d2aAxHqvl2mJk/fccljzi5K6j6nWNf16pcjWjPqCCOTs8oTo1f7gVXQFCzslPnuPIVUbJItE3Ui+mSTv9KF/Q9oH02FF40mSuKtq5WmntV0kACfokRJLZ6slLabo0LgVzGoixdiGwsuJbWAsNNHURoi3lYb8fMOxZ/2o4GZik= volodia@volodia-msi" ];
    hashedPassword = "$6$bK0PDtsca0mKnwX9$uZ2p6ovO9qyTI9vuutKS.X93zHYK.yp2Iw658CkWsBCBHqG4Eq9AUZlVQ4GG1d02D9Sw7i0VdqGxJDFWUS82O1";
    shell = pkgs.fish;
  };
  users.users.root = {
    shell = pkgs.fish;
  };
}
