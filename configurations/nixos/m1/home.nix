# Home Manager for m1 — the scaffolding lives in modules/nixos/home-manager.nix.
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
      themeDaemon.enable = true;
      wm = {
        gnome.enable = false;
        hyprland.enable = true;
      };
    };

    # Upstream Home Manager options
    services.syncthing.enable = true;
    programs.kitty.font.size = 12;
  };
}
