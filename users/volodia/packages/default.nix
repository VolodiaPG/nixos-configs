{
  lib,
  pkgs,
  pkgs-unstable,
  apps,
  ...
}: {
  imports =
    [
      ./mpv.nix
    ]
    ++ lib.optional (apps == "personal") ./personal.nix;

  # Common apps
  home.packages =
    (with pkgs; [
      direnv # Load environment variables when cd'ing into a directory
      findutils # GNU find/xargs commands
      man # Documentation for everything
      p7zip # 7zip archive tools
      lrzip # Advanced and storage efficient zip
      parallel # Much smarter xargs
      progress # View current progress of coreutils tools
      zip # ZIP file manipulation
      unzip
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

      # Fish deps
      fzf # Required by jethrokuan/fzf.
      grc
      libnotify
      notify-desktop
      tmux

      bottom # call btm
      libgtop

      remmina
      cloudflare-warp
      veracrypt
      pavucontrol

      distrobox

      powerstat

      # Office
      libreoffice
      xournalpp

      gitui

      # Utils
      # boxes

      spice-vdagent # copy paste for vms
    ])
    ++ (with pkgs-unstable; [
      bottles
      lapce
      powertop
    ]);
}
