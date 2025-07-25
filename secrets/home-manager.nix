{homeDirectory, ...}: {
  # Paths to public keys that can decrypt the secrets.
  age.identityPaths = [
    "/persistent/home/volodia/.ssh/id_ed25519"
    "/home/volodia/.ssh/id_ed25519"
    "/Users/volodia/.ssh/id_ed25519"
  ];

  age.secrets = {
    pythong5k = {
      file = ./pythong5k.age; # Relative to this file (secrets/pythong5k.age)
      path = "${homeDirectory}/.python-grid5000.yaml";
    };
    envvars = {
      file = ./envvars.age;
      path = "${homeDirectory}/envvars.nu";
    };
  };
}
