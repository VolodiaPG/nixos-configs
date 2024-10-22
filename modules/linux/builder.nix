{config, ...}: {
  nix = {
    distributedBuilds = true;
    settings.trusted-users = ["nix-remote-builder"];
    buildMachines = [
      {
        hostName = "dell-builder";
        sshUser = "nix-remote-builder";
        protocol = "ssh-ng";
        sshKey = config.sops.secrets.ssh-remote-builder.path;
        systems = [
          "x86_64-linux"
        ];
        maxJobs = 64;
        speedFactor = 2;
        supportedFeatures = [
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
      {
        hostName = "m1-builder";
        sshUser = "nix-remote-builder";
        protocol = "ssh-ng";
        sshKey = config.sops.secrets.ssh-remote-builder.path;
        system = "aarch64-linux";
        maxJobs = 16;
        supportedFeatures = [
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
      {
        hostName = "msi-builder";
        sshUser = "nix-remote-builder";
        protocol = "ssh-ng";
        sshKey = config.sops.secrets.ssh-remote-builder.path;
        system = "x86_64-linux";
        maxJobs = 16;
        speedFactor = 1;
        supportedFeatures = [
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
    ];
  };

  users.users.nix-remote-builder = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHIZaWKa2Y/gotOjZugykS0xFpoxwV/lWlshoEVRXJ04 volodia@msi"
    ];
    isNormalUser = true;
    group = "nogroup";
  };

  # Allow more nix-daemon sessions to connect at the same time.
  services.openssh.settings.MaxStartups = 100;

  programs.ssh.extraConfig = ''
    Host dell-builder
      User nix-remote-builder
      HostName dell
      IdentityFile ${config.sops.secrets.ssh-remote-builder.path}
    Host m1-builder
      User nix-remote-builder
      HostName m1
      IdentityFile ${config.sops.secrets.ssh-remote-builder.path}
    Host msi-builder
      User nix-remote-builder
      HostName msi
      IdentityFile ${config.sops.secrets.ssh-remote-builder.path}

  '';
}
