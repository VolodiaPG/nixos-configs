{homeDirectory, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";

    age = {
      generateKey = true;
      sshKeyPaths = ["/persistent${homeDirectory}/.ssh/id_ed25519" "${homeDirectory}/.ssh/id_ed25519"];
    };
  };
}
