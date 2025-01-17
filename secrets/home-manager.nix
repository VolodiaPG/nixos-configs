{
  homeDirectory,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./common.nix
  ];

  sops = {
    age.keyFile = "${homeDirectory}/.config/.sops-nix-key.txt";
    secrets.pythong5k = {
      mode = "0600";
      path = "${homeDirectory}/.python-grid5000.yaml";
    };
    secrets = {
      syncthing-Volodias-MacBook-Pro-cert = {};
      syncthing-Volodias-MacBook-Pro-key = {};
      syncthing-dell-cert = {};
      syncthing-dell-key = {};
      syncthing-msi-cert = {};
      syncthing-msi-key = {};
      syncthing-home-server-cert = {};
      syncthing-home-server-key = {};
    };
  };

  systemd.user.services.sops-nix = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Install.WantedBy = ["default.target"];
  };

  home.activation = {
    sops = lib.hm.dag.entryAfter ["writeBoundary"] (
      (lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        systemctl --user start sops-nix
      '')
      + (lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        launchctl start sops-nix
      '')
      + ''''
    );
  };
}
