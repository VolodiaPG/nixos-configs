{ config, ... }:
{
  # Paths to public keys that can decrypt the secrets.
  age.identityPaths = [
    "/persistent/home/volodia/.ssh/id_ed25519"
    "/home/volodia/.ssh/id_ed25519"
    "/Users/volodia/.ssh/id_ed25519"
  ];

  age.secrets = {
    pythong5k = {
      file = ./pythong5k.age;
      mode = "400";
      path = "${config.home.homeDirectory}/.python-grid5000.yaml";
    };
    envvars = {
      file = ./envvars.age;
      mode = "400";
      path = "${config.home.homeDirectory}/.envvars.sh";
    };
    mail_inria_password = {
      file = ./mail.inria.password.age;
      mode = "0400";
      path = "${config.home.homeDirectory}/.mail.inria.password.txt";
    };
  };
}
