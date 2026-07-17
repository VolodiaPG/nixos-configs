{ lib, ... }:
let
  dm = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
  };
  mkNames = names: lib.genAttrs names (_: dm);
in
{
  options = {
    nixos = lib.mkOption {
      type = lib.types.submodule {
        options = mkNames [
          "base"
          "desktop"
          "server"
          "gnome"
          "niri"
          "intel"
          "nvidia"
          "virt"
          "asahi"
          "caddy"
          "homeLab"
          "immich"
          "immich-ml"
          "backup"
          "samba"
          "networking"
          "dns"
          "arr"
          "recyclarr"
          "microvms"
          "builder"
          "nix-cache-proxy"
          "folding-at-home"
          "scx"
          "gaming"
          "ananicy"
          "peerix"
          "ccache"
          "auto-upgrade"
          "hyperhdr"
          "change-mac"
          "dell"
          "msi"
          "m1"
          "home-server"
        ];
      };
    };

    home = lib.mkOption {
      type = lib.types.submodule {
        options = mkNames [
          "base"
          "desktop"
          "server"
          "gnome"
          "niri"
          "dell"
          "msi"
          "m1"
          "home-server"
          "Volodias-MacBook-Pro"
        ];
      };
    };

    darwin = lib.mkOption {
      type = lib.types.submodule {
        options = mkNames [
          "mac"
          "Volodias-MacBook-Pro"
        ];
      };
    };
  };
}
