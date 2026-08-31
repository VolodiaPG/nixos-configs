{ flake, pkgs-unstable, ... }:
let
  inherit (flake) inputs;
in
_final: prev: {
  inherit (pkgs-unstable)
    neovim
    neovim-unwrapped
    opencode
    noctalia
    hyprland
    tailscale
    immich
    immich-machine-learning
    brave-origin
    bambu-studio
    orca-slicer
    ;

  inherit (inputs.self.packages.${prev.stdenv.hostPlatform.system})
    high-tide
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
