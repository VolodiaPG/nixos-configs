{ flake, pkgs-unstable, ... }:
final: prev:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  packages = import (self + "/packages/default.nix") { pkgs = final; };
  high-tide = pkgs-unstable.callPackage (self + "/packages/high-tide/default.nix") {
    src = inputs.high-tide;
  };
  # headroom's Python dependencies (litellm, mcp, ast-grep-cli) are only new
  # enough in unstable, so it and the Claude Code wrapper built on top of it are
  # taken from that package set rather than from `packages/default.nix`.
  headroom = pkgs-unstable.callPackage (self + "/packages/headroom/default.nix") { };
  claude-code-headroom =
    pkgs-unstable.callPackage (self + "/packages/claude-code-headroom/default.nix")
      {
        inherit headroom;
      };
in
{
  # Pulled forward from nixpkgs-unstable: newer than the pinned stable channel,
  # or (avd-fw) simply not present in it yet.
  inherit (pkgs-unstable)
    neovim
    neovim-remote
    neovim-unwrapped
    opencode
    claude-code
    rtk
    codegraph
    noctalia
    hyprland
    tailscale
    immich
    immich-machine-learning
    brave-origin
    bambu-studio
    orca-slicer
    # Apple Video Decoder firmware, required by
    # inputs.nixos-apple-silicon's video module on the m1 host. Only exists in
    # unstable; without this the m1 config fails to evaluate.
    avd-fw
    t3code
    ;

  # In-repo packages (packages/default.nix), also exposed as flake `packages`.
  inherit (packages)
    theme-switcher
    tmux-session-color
    openrouter-credits
    xinstall
    xmount
    mpv-rife
    ;

  inherit high-tide headroom claude-code-headroom;

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
