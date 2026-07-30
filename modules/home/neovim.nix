# ponytail: packages-only — chezmoi owns ~/.config/nvim, so we must NOT use
# programs.neovim (it writes init.lua via xdg.configFile and would clash with
# chezmoi apply --force). home.packages is the minimal non-conflicting surface.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myneovim;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.myneovim.enable = mkEnableOption "neovim + LSP/formatter/runtime tooling (lua config via chezmoi)";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      neovim

      # --- LSP servers (vim.lsp.config/enable targets in lua/myLuaConf/LSPs/init.lua) ---
      lua-language-server
      gopls
      nixd
      bash-language-server # bashls
      texlab
      tinymist

      # --- formatters (conform.nvim in lua/myLuaConf/format.lua) ---
      stylua
      ruff
      shfmt
      shellcheck
      shellharden
      rustfmt
      go # gofmt
      nixfmt
      typstyle

      # --- runtime deps shelled out to by plugins / opts ---
      ripgrep # telescope + opts.grepprg (also in common-home.nix, keep module self-contained)
      lazygit # lazygit.nvim (also in interactive.nix)
      tmux # vim-tmux-navigator (also in common-home.nix)
      git # vim.pack cloning + find_git_root (also in common-home.nix)
      zathura # vimtex viewer on Linux (plugins/init.lua:437)

      # --- build toolchain so vim.pack can compile native plugins at first launch ---
      # ponytail: toolchain-in-PATH is the ceiling; upgrade path = package telescope-fzf-native /
      # blink via nixpkgs/overlay if first-launch builds become a maintenance issue.
      gcc # telescope-fzf-native compiles a tiny C .so via make
      gnumake
      # ponytail: add cmake / cargo ONLY if the first-launch build of telescope-fzf-native (cmake?)
      #   or blink.cmp (:build() — downloads prebuilt by default, needs wget/curl which are present)
      #   fails without them. Don't pre-emptively bloat PATH.
    ];
  };
}
