# Aggregator for the Home Manager modules in this directory. Added to
# `home-manager.sharedModules` by modules/{nixos,darwin}/home-manager.nix, so
# every host's user gets the `my.*` options declared; each module stays inert
# until its `enable` is set.
{
  imports = [
    ./browser.nix
    ./catppuccin-theme.nix
    ./chezmoi.nix
    ./claude.nix
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
}
