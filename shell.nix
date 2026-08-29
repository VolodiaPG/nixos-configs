# ponytail: dev shell sourced from npins — no flake, no fetchTarball.
# `npins` is included so `npins update` works inside `nix-shell`/direnv.
# git-hooks imported via nix/default.nix directly (bypasses flake-compat,
# which would fetch its own nixpkgs pin — slow + un-substitutable after GC).
let
  sources = import ./npins;
  system = builtins.currentSystem;
  pkgs = import (sources.git-hooks + "/nix") {
    inherit system;
    # inherit (sources) nixpkgs;
    nixpkgs = sources.nixpkgs-unstable;
    isFlakes = true;
  };
  pre-commit-check = pkgs.run {
    src = ./.;
    hooks = {
      nixfmt.enable = true;
      statix.enable = true;
      deadnix.enable = true;
      actionlint.enable = true;
      shellcheck.enable = true;
      luacheck.enable = true;
      stylua.enable = true;
    };
  };
in
pkgs.mkShell {
  packages =
    with pkgs;
    [
      npins
      just
      git
      ragenix
      deploy-rs
      nh
      nix-output-monitor
      prek
      nvd
      gum
    ]
    ++ pre-commit-check.enabledPackages;
  inherit (pre-commit-check) shellHook;
}
