{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
with lib;
let
  cfg = config.services.homePackages;
in
{
  imports = [
    ./mpv.nix
  ];

  options = {
    services.homePackages = with types; {
      enable = mkEnableOption "Home packages configuration";
    };
  };

  config = mkIf cfg.enable {
    # Common apps
    home.packages =
      (with pkgs; [
        direnv # Load environment variables when cd'ing into a directory
        findutils # GNU find/xargs commands
        parallel # Much smarter xargs
        zip # ZIP file manipulation
        unzip
        gdu # Manager files and see sizes quickly
        zoxide # smart CD that remembers
        git-crypt
        cocogitto
        python3

        # System monitoring
        htop # Interactive TUI process viewer
        nmap # Network scanning and more

        # File transfer
        wget # Retrieve files from the web

        # Fish deps
        fzf # Required by jethrokuan/fzf.
        grc
        libnotify
        notify-desktop
        tmux

        bottom # call btm
        libgtop
      ])
      ++ (with pkgs-unstable; [
      ]);
  };
}
