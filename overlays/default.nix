{ flake, ... }:
let
  inherit (flake) inputs;
in
_final: prev:
let
  lixPackageSets = prev.lixPackageSets.override {
    inherit (prev)
      nix-direnv
      nix-fast-build
      ;
  };
in
{
  inherit (lixPackageSets.stable)
    lix
    nix-direnv
    nix-eval-jobs
    nix-fast-build
    nix-serve-ng
    ;

  inherit (inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.system})
    devenv
    ;

  inherit (inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system})
    opencode
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
