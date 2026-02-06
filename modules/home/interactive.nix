{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib;
let
  cfg = config.interactive;
  inherit (flake) inputs;
in
{

  options = {
    interactive = with types; {
      enable = mkEnableOption "Interactive configuration for users";
    };
  };

  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.nix-index-database.homeModules.nix-index
  ];

  config = mkIf cfg.enable {
    # Configure Catppuccin theme switching, extending the default catppuccin module
    catppuccin = {
      enable = true;
      autoThemeSwitch = true;
      darkFlavor = "mocha"; # Your preferred dark theme
      lightFlavor = "latte"; # Your preferred light theme
      # TODO: make use of light and dark flavors in the script itself, hard coded for now
    };

    # Enable the theme daemon for automatic switching
    services.theme-daemon.enable = true;

    programs = {
      opencode.enable = true;
      lazygit = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          git = {
            pagers = [
              { useExternalDiffGitConfig = true; }
            ];
          };
        };
      };
      nix-index.enable = true;
      nix-index-database.comma.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        stdlib = ''
          export DIRENV_LOG_FORMAT=""
        '';
      };
    };

    home = {
      inherit (flake.config.me) username;
      homeDirectory = flake.config.me.homeDirectory pkgs.stdenv;
      packages = with pkgs; [
        fontconfig
        direnv
        git-crypt
        python3
        difftastic
      ];

      stateVersion = "22.05";
    };
  };
}
