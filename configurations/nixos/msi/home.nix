# Home Manager for msi — the scaffolding lives in modules/nixos/home-manager.nix.
{ flake, ... }:
let
  inherit (flake.config) me;
in
{
  imports = [ flake.self.nixosModules.home-manager ];

  home-manager.users.${me.username} = {
    my = {
      commonHome.enable = true;
      interactive.enable = true;
      gui.enable = true;
      chezmoi.enable = true;
      browser.enable = true;
      neovim.enable = true;
      mpv.enable = true;
      themeDaemon.enable = true;
      wm = {
        gnome.enable = false;
        hyprland.enable = true;
      };
      claude.enable = true;
    };

    # Upstream Home Manager options
    services.syncthing.enable = true;
  };
}
