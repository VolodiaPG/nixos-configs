{
  imports = [./common.nix];
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets.dellmac = {
  };
}
