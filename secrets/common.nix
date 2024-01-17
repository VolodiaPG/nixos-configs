{homeDirectory, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";

    gnupg = {
      home = "${homeDirectory}/.gnupg";
      sshKeyPaths = [];
    };
  };
}
