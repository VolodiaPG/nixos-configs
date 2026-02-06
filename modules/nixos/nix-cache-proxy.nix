{
  config,
  lib,
  flake,
  ...
}:
with lib;
let
  cfg = config.services.nixCacheProxy;
  inherit (flake.config) me;
  inherit (flake) inputs;
in
{
  imports = [ inputs.nix-cache-proxy.nixosModules.nix-cache-proxy ];

  options = {
    services.nixCacheProxy = with types; {
      enable = mkEnableOption "Nix cache proxy";
    };
  };

  config = mkIf cfg.enable {
    services.nix-cache-proxy = {
      enable = true;
      listenAddress = "127.0.0.1:3687";
      upstreams = me.trusted-substituters;
    };
  };
}
