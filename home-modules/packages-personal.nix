{
  pkgs,
  # config,
  # lib,
  ...
}:
{
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
      provider = {
        cliproxy = {
          npm = "@ai-sdk/openai-compatible";
          name = "CliProxy";
          options = {
            baseURL = "http://127.0.0.1:8317/v1";
            apiKey = "your-api-key-1";
          };
          models = {
            gemini-3-pro-high = {
              name = "Gemini 3 Pro High";
              thinking = true;
              attachment = true;
              limit = {
                context = 1048576;
                output = 65535;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
            };
            gemini-3-flash-preview = {
              name = "Gemini 3 Flash";
              attachment = true;
              limit = {
                context = 1048576;
                output = 65536;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
            };
            gemini-claude-opus-4-5-thinking = {
              name = "Claude Opus 4.5 Thinking";
              attachment = true;
              limit = {
                context = 200000;
                output = 32000;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
            };
            gemini-claude-sonnet-4-5-thinking = {
              name = "Claude Sonnet 4.5 Thinking";
              attachment = true;
              limit = {
                context = 200000;
                output = 32000;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
            };
          };
        };
      };
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

  # # Clean up the cache since opencode does not update automatically
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
}
