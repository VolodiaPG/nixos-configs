{ flake, ... }:
{
  imports = [
    ./browser.nix
    ./catppuccin-theme.nix
    ./chezmoi.nix
    ./common-home.nix
    ./git.nix
    ./gnome.nix
    ./gui.nix
    ./hyprland.nix
    ./interactive.nix
    ./mpv.nix
    ./neovim.nix
    ./syncthing.nix
    ./theme-daemon.nix
    ./tmux.nix
    ./zsh.nix
  ];

  _module.args = {
    inherit flake;
  };
}
