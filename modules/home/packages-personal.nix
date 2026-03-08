{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.homePackagesPersonal;
in
{
  options = {
    homePackagesPersonal = with types; {
      enable = mkEnableOption "Personal home packages configuration";
    };
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      settings = {
        "keybinds" = {
          messages_half_page_up = "ctrl+u";
          messages_half_page_down = "ctrl+d";
        };
        "plugin" = [
          # "@plannotator/opencode@latest"
          "@simonwjackson/opencode-direnv@latest"
          "@tarquinen/opencode-dcp@latest"
          "oh-my-opencode-slim@latest"
        ];
      };
    };

    xdg.configFile."opencode/oh-my-opencode-slim.json".text =
      let
        goodModel = "openrouter/moonshotai/kimi-k2.5";
        expensiveModel = goodModel;
        cheapModel = "openrouter/google/gemini-2.5-flash-lite";
      in
      builtins.toJSON {
        preset = "custom";
        presets = {
          custom = {
            orchestrator = {
              model = goodModel;
              skills = [ "*" ];
              mcps = [ "websearch" ];
            };
            oracle = {
              model = expensiveModel;
              skills = [ ];
              mcps = [ ];
            };
            librarian = {
              model = goodModel;
              skills = [ ];
              mcps = [
                "websearch"
                "context7"
                "grep_app"
              ];
            };
            explorer = {
              model = goodModel;
              skills = [ ];
              mcps = [ ];
            };
            designer = {
              model = goodModel;
              skills = [ "agent-browser" ];
              mcps = [ ];
            };
            fixer = {
              model = cheapModel;
              skills = [ ];
              mcps = [ ];
            };
          };
        };
      };

    # Clean up the cache since opencode does not update automatically
    # home.activation.opencode-delete-plugin-cache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #   # rm -rf ${config.xdg.configHome}/opencode/node_modules
    #   # rm -rf ${config.xdg.configHome}/opencode/bun.lock
    #   # rm -rf ${config.xdg.configHome}/opencode/package.json
    #   rm -rf ~/.cache/opencode/node_modules/
    # '';

    home.packages = [
      pkgs.cachix
      pkgs.nvim
      pkgs.devenv
    ];
  };
}
