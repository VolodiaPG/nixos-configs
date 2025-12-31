{
  pkgs,
  lib,
  config,
  ...
}:
let
  upstreamArgs = lib.concatMapStringsSep " " (u: "--upstream ${u}") (
    [ "https://cache.nixos.org" ] ++ config.nix.settings.trusted-substituters
  );
  port = "3687";
in
{
  nix.settings.substituters = lib.mkForce [ "http://127.0.0.1:${port}" ];

  systemd.services.nix-cache-proxy = {
    description = "Nix Cache Proxy";
    after = [ "network.target" ];
    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "3";
      ExecStart = "${pkgs.nix-cache-proxy}/bin/nix-cache-proxy --bind 127.0.0.1:${port} ${upstreamArgs}";

      User = "nix-cache-proxy";
      Group = "nix-cache-proxy";
    };
  };

  users.users.nix-cache-proxy = {
    group = "nix-cache-proxy";
    isSystemUser = true;
  };
  users.groups.nix-cache-proxy = { };
}
