{homeDirectory, ...}: {
  # age.secrets = {
  #   pythong5k.file = ./pythong5k.age;
  #   ssh-remote-builder.file = ./ssh-remote-builder.private.age;
  #   "ssh-remote-builder.pub".file = ./ssh-remote-builder.pub.age;
  #   "syncthing.dell.cert".file = ./syncthing.dell.cert.age;
  #   "syncthing.dell.key".file = ./syncthing.dell.key.age;
  #   "syncthing.msi.cert".file = ./syncthing.msi.cert.age;
  #   "syncthing.msi.key".file = ./syncthing.msi.key.age;
  #   "syncthing.home-server.cert".file = ./syncthing.home-server.cert.age;
  #   "syncthing.home-server.key".file = ./syncthing.home-server.key.age;
  #   "syncthing.m1.cert".file = ./syncthing.m1.cert.age;
  #   "syncthing.m1.key".file = ./syncthing.m1.key.age;
  #   "syncthing.pass".file = ./syncthing.pass.age;
  # };
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";

    age = {
      generateKey = true;
      sshKeyPaths = ["/persistent${homeDirectory}/.ssh/id_ed25519" "${homeDirectory}/.ssh/id_ed25519"];
    };
  };
}
