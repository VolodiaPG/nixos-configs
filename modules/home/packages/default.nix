{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.homePackages;
  inherit (lib) mkEnableOption mkIf;
in
{
  imports = [
    ./mpv.nix
  ];

  options = {
    services.homePackages = {
      enable = mkEnableOption "Home packages configuration";
    };
  };

  config = mkIf cfg.enable {
    # Common apps
    home.packages = [
      pkgs.direnv # Load environment variables when cd'ing into a directory
      pkgs.findutils # GNU find/xargs commands
      pkgs.parallel # Much smarter xargs
      pkgs.zip # ZIP file manipulation
      pkgs.unzip
      pkgs.gdu # Manager files and see sizes quickly
      pkgs.zoxide # smart CD that remembers
      pkgs.git-crypt
      pkgs.cocogitto
      pkgs.python3

      # System monitoring
      pkgs.htop # Interactive TUI process viewer
      pkgs.nmap # Network scanning and more

      # File transfer
      pkgs.wget # Retrieve files from the web

      # Fish deps
      pkgs.fzf # Required by jethrokuan/fzf.
      pkgs.grc
      pkgs.libnotify
      pkgs.notify-desktop
      pkgs.tmux

      pkgs.bottom # call btm
      pkgs.libgtop
    ];
  };
}
