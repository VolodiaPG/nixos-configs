{ flake, ... }:
let
  inherit (flake) inputs;
in
_final: prev:
# let
#   lixPackageSets = prev.lixPackageSets.override {
#     inherit (prev)
#       nix-direnv
#       nix-fast-build
#       ;
#   };
# in
{
  # inherit (prev.lixPackageSets.git)
  #   nix-direnv
  #   nix-eval-jobs
  #   nix-fast-build
  #   nix-serve-ng
  #   ;

  inherit (inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.system})
    devenv
    difftastic
    zotero
    nvfetcher
    kanata
    yabai
    ollama
    ;

  nix = inputs.nixpkgs.legacyPackages.${prev.stdenv.system}.nixVersions.latest;

  inherit (inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system})
    opencode
    ;

  inherit (inputs.vim.packages.${prev.stdenv.hostPlatform.system}) nvim;

  inherit (inputs.self.packages.${prev.stdenv.hostPlatform.system})
    theme-switcher
    tmux-session-color
    openrouter-credits
    ;

  noctalia-shell = inputs.noctalia.packages.${prev.stdenv.hostPlatform.system}.default;

  nix-cache-proxy = inputs.nix-cache-proxy.packages.${prev.stdenv.hostPlatform.system}.default;

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
  signal-desktop = prev.symlinkJoin {
    name = "signal-desktop";
    paths = [ prev.signal-desktop ];
    buildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/signal-desktop\
         --add-flags '--password-store=gnome-libsecret'\
         --add-flags '--enable-features=UseOzonePlatform'\
         --add-flags '--ozone-platform=wayland'
    '';
  };
  strawberry = prev.symlinkJoin {
    name = "strawberry";
    paths = [
      prev.strawberry
    ];
    buildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/strawberry \
      --run "systemctl --user restart pipewire pipewire-pulse wireplumber tidal-to-strawberry"
    '';
  };
  brave = prev.symlinkJoin {
    name = "brave";
    paths = [ prev.brave ];
    buildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/brave \
         --add-flags '--enable-features=UseOzonePlatform'\
         --add-flags '--ozone-platform=wayland'
    '';
  };
}
