let
  # Define the primary user for owning user-specific secrets.
  # Adjust if your username is different or managed more dynamically.
  userReadable = {
    mode = "0500";
    owner = "volodia";
    group = "volodia";
  };
  rootReadable = {
    owner = "root";
    mode = "0500";
  };
in
{
  # Paths to public keys that can decrypt the secrets.
  age.identityPaths = [
    "/persistent/home/volodia/.ssh/id_ed25519"
    "/home/volodia/.ssh/id_ed25519"
    "/Users/volodia/.ssh/id_ed25519"
  ];

  age.secrets = {
    tailscale-authkey = {
      file = ./tailscale-authkey.age;
    }
    // rootReadable;

    rss-password = {
      file = ./rss-password.age;
    }
    // rootReadable;

    "ssh-remote-builder" = {
      file = ./ssh-remote-builder.age;
    }
    // rootReadable;

    "ssh-remote-builder-pub" = {
      file = ./ssh-remote-builder-pub.age;
    }
    // rootReadable;

    samba-user-password = {
      file = ./samba-user-password.age;
    }
    // rootReadable;

    cachix-token = {
      file = ./cachix-token.age;
    }
    // userReadable;

    fizzy-env = {
      file = ./fizzy-env.age;
    }
    // rootReadable;

    pythong5k = {
      file = ./pythong5k.age;
      path = "/run/agenix/pythong5k";
    }
    // userReadable;

    envvars = {
      file = ./envvars.age;
      path = "/run/agenix/envvars";
    }
    // userReadable;

    mail_inria_password = {
      file = ./mail.inria.password.age;
      path = "/run/agenix/mail_inria_password";
    }
    // userReadable;
  };
}
