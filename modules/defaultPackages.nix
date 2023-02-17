{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Terminal tools
    coreutils # Basic GNU utilities
    direnv # Load environment variables when cd'ing into a directory
    findutils # GNU find/xargs commands
    gitAndTools.gitFull # Git core installation
    gnupg # GNU Privacy Guard
    man # Documentation for everything
    p7zip # 7zip archive tools
    lrzip # Advanced and storage efficient zip
    parallel # Much smarter xargs
    progress # View current progress of coreutils tools
    zip # ZIP file manipulation
    gdu # Manager files and see sizes quickly
    micro # text editor
    zoxide # smart CD that remembers
    gh # Github PRs and stuff
    git-crypt
    cocogitto
    python3
    ecryptfs

    # System monitoring
    htop # Interactive TUI process viewer
    lm_sensors # Read hardware sensors
    nmap # Network scanning and more

    # File transfer
    sshfs-fuse # Mount remote filesystem over SSH with FUSE
    wget # Retrieve files from the web
  ];
}
