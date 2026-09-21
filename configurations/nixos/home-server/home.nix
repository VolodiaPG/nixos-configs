# Home Manager for home-server — headless, so only the shell/CLI bits.
# Scaffolding lives in modules/nixos/home-manager.nix.
{ flake, ... }:
let
  inherit (flake.config) me;
in
{
  imports = [ flake.self.nixosModules.home-manager ];

  home-manager.users.${me.username} = {
    my.commonHome.enable = true;

    # Upstream Home Manager options
    services.syncthing.enable = true;
    catppuccin = {
      enable = false;
      autoEnable = false;
    };

    # Headless, and `documentation.enable` is already off system-wide: building
    # the Home Manager option manpage on every rebuild buys nothing here.
    manual.manpages.enable = false;
    programs.man.enable = false;
  };
}
