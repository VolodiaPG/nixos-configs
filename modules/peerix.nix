
{ config, ... }:
{
  services.peerix = {
    enable = true;
    openFirewall = true; # UDP/12304
    privateKeyFile = ../secrets/peerix-ux430ua-private;
    publicKeyFile = ../secrets/peerix-ux430ua-public;
    user = "peerix";
    group = "peerix";
  };
  users.users.peerix = {
    isSystemUser = true;
    group = "peerix";
  };
  users.groups.peerix = { };
}