{
  imports = [./common.nix];
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      dellmac = {};
      ssh-remote-builder = {};
      ssh-remote-builder-pub = {};
    };
  };
}
