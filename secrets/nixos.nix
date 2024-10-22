{
  imports = [./common.nix];
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      dellmac = {};
      ssh-remote-builder = {};
      ssh-remote-builder-pub = {};
      syncthing-password = {};
      syncthing-m1-cert = {};
      syncthing-m1-key = {};
      syncthing-dell-cert = {};
      syncthing-dell-key = {};
      syncthing-msi-cert = {};
      syncthing-msi-key = {};
      syncthing-home-server-cert = {};
      syncthing-home-server-key = {};
    };
  };
}
