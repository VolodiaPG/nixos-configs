{ config, lib, pkgs, ... }:
let
  # Define the primary user for owning user-specific secrets.
  # Adjust if your username is different or managed more dynamically.
  secretsUser = "volodia";
in
{
  # Paths to public keys that can decrypt the secrets.
  # You will create the 'admin_volodia.pub' file in a manual step.
  age.identityPaths = [
    (lib.mkAbsPath ./identities/admin_volodia.pub)
  ];

  age.secrets = {
    # Secrets previously in secrets.yaml
    # The .age files (e.g., pythong5k.age) will be created by you manually
    # and placed in the same directory as this file (secrets/).

    pythong5k = {
      path = ./pythong5k.age; # Relative to this file (secrets/pythong5k.age)
      owner = secretsUser;    # Owned by the user
    };

    envvars = {
      path = ./envvars.age;
      owner = secretsUser;    # Owned by the user
    };

    dellmac = {
      path = ./dellmac.age;
      # owner defaults to root
    };

    "ssh-remote-builder" = {
      path = ./ssh-remote-builder.age;
      # owner defaults to root
    };

    "ssh-remote-builder-pub" = {
      path = ./ssh-remote-builder-pub.age;
      # owner defaults to root
    };
  };

  # Optional: If you need to ensure private keys are loaded from specific files
  # during Nix builds, you can specify them here. Often, keys are picked up
  # from standard user/system locations or SSH agent.
  # age.keyFiles = [
  #   "/path/to/private/keyfile1"
  # ];
}
