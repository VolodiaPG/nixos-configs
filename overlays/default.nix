{ flake, pkgs-unstable, ... }:
final: prev:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  packages = import (self + "/packages/default.nix") { pkgs = final; };
  high-tide = pkgs-unstable.callPackage (self + "/packages/high-tide/default.nix") {
    src = inputs.high-tide;
  };
in
{
  inherit (pkgs-unstable)
    neovim
    neovim-remote
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

  inherit (packages)
    theme-switcher
    tmux-session-color
    openrouter-credits
    xinstall
    xmount
    mpv-rife
    ;

  inherit high-tide;

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
