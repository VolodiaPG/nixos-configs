_: {
  services.peerix = {
    enable = true;
    openFirewall = true; # UDP/12304
    privateKeyFile = ../secrets/peerix-private;
    publicKeyFile = ../secrets/peerix-public;
    user = "peerix";
    group = "peerix";
    disableBroadcast = true;
    extraHosts = [ "asus" "msi-nixos" "precision-3571-nixos" ];
  };
  users.users.peerix = {
    isSystemUser = true;
    group = "peerix";
  };
  users.groups.peerix = { };
}
