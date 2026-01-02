{
  user,
  inputs,
  ...
}:
let
  port = "3687";
in
{
  imports = [ inputs.nix-cache-proxy.nixosModules.default ];
  services.nix-cache-proxy = {
    enable = true;
    listenAddress = "127.0.0.1:${port}";
    upstreams = user.trusted-substituters;
  };
}
