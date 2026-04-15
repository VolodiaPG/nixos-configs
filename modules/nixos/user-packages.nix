{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
with lib;
let
  cfg = config.userPackages;
in
{
  options = {
    userPackages = {
      enable = mkEnableOption "User packages module";

      common = {
        enable = mkEnableOption "Common packages (git, zsh, tmux, basic tools)" // {
          default = true;
        };
      };

      interactive = {
        enable = mkEnableOption "Interactive packages (fzf, lazygit, nvim, etc.)" // {
          default = true;
        };
      };

      gui = {
        enable = mkEnableOption "GUI packages (browsers, apps, niri tools)" // {
          default = false;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Common packages - basic shell tools and utilities
    environment.systemPackages =
      with pkgs;
      (mkIf cfg.common.enable [
        git
        zsh
        tmux
        keychain
        zoxide
        openssh
        mosh
        ripgrep
        findutils
        parallel
        zip
        unzip
        gdu
        htop
        nmap
        wget
        grc
        bottom
        libgtop
        lsof
        chezmoi
        starship
        cocogitto
      ])
      ++ (mkIf cfg.interactive.enable [
        fzf
        lazygit
        nix-index
        direnv
        fontconfig
        git-crypt
        python3
        difftastic
        cachix
        devenv
        nvim
      ])
      ++ (mkIf cfg.gui.enable (
        [
          brave
          signal-desktop
          legcord
          vlc
          zathura
          mpv
          play-with-mpv
          kitty
          kitty-themes
          fuzzel
          grim
          slurp
          cliphist
          kdePackages.qttools
          distrobox
          distrobox-tui
          strawberry
          qbittorrent
          easyeffects
          zotero
          drawio
          libreoffice-qt-fresh
          freerdp
          libnotify
          notify-desktop
          satty
          wl-clipboard
          swaybg
          wpaperd
          wlogout
          wlr-randr
          polkit_gnome
          wl-mirror
          brightnessctl
        ]
        ++ [
          pkgs-unstable.mpv
        ]
      ));
  };
}
