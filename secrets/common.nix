{homeDirectory, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";

    age = {
      generateKey = true;
      sshKeyPaths = ["${homeDirectory}/.ssh/id_ed25519"];
    };
  };
}
