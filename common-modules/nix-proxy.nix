{
  pkgs,
  lib,
  user,
  ...
}:
let
  upstreamArgs = lib.concatMapStringsSep " " (u: "--upstream ${u}") user.trusted-substituters;
  port = "3687";
in
{
  nix.settings.substituters = lib.mkForce [ "http://127.0.0.1:${port}?priority=1" ];

  launchd.daemons.nix-cache-proxy = {
    script = "${pkgs.nix-cache-proxy}/bin/nix-cache-proxy --bind 127.0.0.1:${port} ${upstreamArgs}";

    serviceConfig = {
      Label = "org.nixos.nix-cache-proxy";
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/nix-cache-proxy.log";
      StandardErrorPath = "/var/log/nix-cache-proxy.log";
      ThrottleInterval = 3;
    };
  };
}
