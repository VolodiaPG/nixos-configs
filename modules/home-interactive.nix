{
  config,
  inputs,
  ...
}:
let
  inherit (config) me;
in
{
  config.home.base =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
      imports = [
        inputs.catppuccin.homeModules.catppuccin
        inputs.nix-index-database.homeModules.nix-index
      ];

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
        inherit (me) username;
        homeDirectory = me.homeDirectory pkgs.stdenv;
        packages = with pkgs; [
          direnv
          git-crypt
          python3
          difftastic
          cachix
          vim
          devenv
        ];

        stateVersion = "22.05";
      };
    };
}
