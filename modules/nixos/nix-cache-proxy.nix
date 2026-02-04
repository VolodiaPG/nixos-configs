{
  flake,
  ...
}:
let
  port = "3687";
  inherit (flake.config) me;
  inherit (flake) inputs;
in
{
  imports = [ inputs.nix-cache-proxy.nixosModules.nix-cache-proxy ];
  services.nix-cache-proxy = {
    enable = true;
    listenAddress = "127.0.0.1:${port}";
    upstreams = me.trusted-substituters;
  };
}
