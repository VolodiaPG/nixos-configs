{ pkgs, config, ... }:
{
  services.peerix = {
    enable = true;
    openFirewall = true; # UDP/12304
    privateKeyFile = ../secrets/peerix-private;
    publicKeyFile = ../secrets/peerix-public;
    user = "peerix";
    group = "peerix";
    package = pkgs.writeShellScriptBin "peerix" ''
      exec ${pkgs.peerix}/bin/peerix --timeout 200 "$@"
    '';
  };
  users.users.peerix = {
    isSystemUser = true;
    group = "peerix";
  };
  users.groups.peerix = { };
}
