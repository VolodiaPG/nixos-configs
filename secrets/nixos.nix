{
  imports = [./common.nix];
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      dellmac = {};
      ssh-remote-builder = {};
      ssh-remote-builder-pub = {};
      syncthing-password = {};
      syncthing-Volodias-MacBook-Pro-cert = {};
      syncthing-Volodias-MacBook-Pro-key = {};
      syncthing-dell-cert = {};
      syncthing-dell-key = {};
      syncthing-msi-cert = {};
      syncthing-msi-key = {};
      syncthing-home-server-cert = {};
      syncthing-home-server-key = {};
    };
  };
}
