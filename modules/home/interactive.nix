{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  cfg = config.my.interactive;
  inherit (flake) inputs;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOverride
    ;
in
{

  options = {
    my.interactive = {
      enable = mkEnableOption "Interactive configuration for users";
    };
  };

  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.nix-index-database.homeModules.nix-index
  ];

  config = mkMerge [
    {
      # The nix-index-database module flips `programs.nix-index.enable` on just
      # by being imported, which ships the full (several hundred MB) index to
      # hosts that never get an interactive shell. Tie it back to this module;
      # 900 beats its mkDefault while still losing to an explicit host setting.
      programs.nix-index.enable = mkOverride 900 cfg.enable;
    }

    (mkIf cfg.enable {
      # Upstream catppuccin module (inputs.catppuccin)
      catppuccin = {
        enable = true;
        # Lock autoEnable explicitly to silence future-behavior warning
        autoEnable = true;
      };

      my = {
        # Our own theme-switching layer on top of it (modules/home/catppuccin-theme.nix)
        catppuccin = {
          autoThemeSwitch = true;
          darkFlavor = "mocha"; # Your preferred dark theme
          lightFlavor = "latte"; # Your preferred light theme
          # TODO: make use of light and dark flavors in the script itself, hard coded for now
        };

        # Enable the theme daemon for automatic switching
        themeDaemon.enable = true;
      };

      programs = {
        opencode.enable = true;
        fzf.enable = true;
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
        nix-index-database.comma.enable = true;
        direnv = {
          enable = true;
          silent = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
          stdlib = ''
            export DIRENV_LOG_FORMAT=""
          '';
        };
      };

      home = {
        packages = [
          pkgs.direnv
          pkgs.git-crypt
          pkgs.python3
          pkgs.difftastic
          pkgs.cachix
          pkgs.vim
          pkgs.devenv
          pkgs.just
        ];
      };
    })
  ];
}
