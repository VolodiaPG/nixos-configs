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

    xdg.configFile."opencode/oh-my-opencode-slim.json".text = ''
      {
        "preset": "custom",
        "presets": {
          "custom": {
            "orchestrator": { "model": "openrouter/moonshotai/kimi-k2.5", "skills": ["*"], "mcps": ["websearch"] },
            "oracle": { "model": "openrouter/z-ai/glm-4.7", "skills": [], "mcps": [] },
            "librarian": { "model": "openrouter/google/gemini-3-flash-preview", "skills": [], "mcps": ["websearch", "context7", "grep_app"] },
            "explorer": { "model": "openrouter/google/gemini-3-flash-preview",  "skills": [], "mcps": [] },
            "designer": { "model": "openrouter/google/gemini-3-flash-preview",  "skills": ["agent-browser"], "mcps": [] },
            "fixer": { "model": "openrouter/z-ai/glm-4.7-flash", "skills": [], "mcps": [] }
          }
        }
      }
    '';

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
