{ flake, ... }:
let
  inherit (flake) inputs;
in
_final: prev:
let
  # ponytail: fast-moving tools from unstable; everything else stays on stable nixpkgs.
  # Add packages to this list as needed — they override the stable defaults.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.system};
in
{
  nix = unstable.nixVersions.latest;

  inherit (unstable)
    neovim
    opencode
    noctalia
    hyprland
    # --- LSP servers (vim.lsp.config targets in lua config) ---
    lua-language-server
    gopls
    nixd
    bash-language-server
    texlab
    tinymist
    # --- formatters (conform.nvim) ---
    stylua
    ruff
    shfmt
    shellcheck
    shellharden
    rustfmt
    nixfmt
    typstyle
    ;

  inherit (inputs.high-tide.packages.${prev.stdenv.hostPlatform.system})
    high-tide
    ;

  inherit (inputs.self.packages.${prev.stdenv.hostPlatform.system})
    theme-switcher
    tmux-session-color
    openrouter-credits
    xinstall
    xmount
    mpv-rife
    ;

  mosh = prev.mosh.overrideAttrs (
    old:
    let
      patches = inputs.nixpkgs.lib.lists.remove (prev.fetchpatch {
        url = "https://github.com/mobile-shell/mosh/commit/eee1a8cf413051c2a9104e8158e699028ff56b26.patch";
        hash = "sha256-CouLHWSsyfcgK3k7CvTK3FP/xjdb1pfsSXYYQj3NmCQ=";
      }) old.patches;
    in
    {
      inherit patches;
      src = inputs.mosh;
      # remove perl diag to fix build on determinate nix builder
      preBuild = ''
        sed -i 's/perl -Mdiagnostics -c /perl -c /g' scripts/Makefile.am
      '';
    }
  );
}
