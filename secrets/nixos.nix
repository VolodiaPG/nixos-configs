{
  imports = [./common.nix];
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      dellmac = {};
      syncthing-password = {};
      syncthing-cert = {};
      syncthing-key = {};
    };
  };
}
