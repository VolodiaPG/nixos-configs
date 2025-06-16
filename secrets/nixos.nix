let
  # Define the primary user for owning user-specific secrets.
  # Adjust if your username is different or managed more dynamically.
  # secretsUser = "volodia";
  # userReadable = {
  #   mode = "0500";
  #   owner = secretsUser;
  # };
  #
  rootReadable = {
    owner = "root";
    mode = "0500";
  };
in {
  # Paths to public keys that can decrypt the secrets.
  age.identityPaths = [
    "/persistent/home/volodia/.ssh/id_ed25519"
    "/home/volodia/.ssh/id_ed25519"
    "/Users/volodia/.ssh/id_ed25519"
  ];

  age.secrets = {
    dellmac =
      {
        file = ./dellmac.age;
      }
      // rootReadable;

    "ssh-remote-builder" =
      {
        file = ./ssh-remote-builder.age;
      }
      // rootReadable;

    "ssh-remote-builder-pub" =
      {
        file = ./ssh-remote-builder-pub.age;
      }
      // rootReadable;
  };
}
