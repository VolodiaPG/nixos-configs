{
  homeDirectory,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./common.nix
  ];
  sops.age.keyFile = "${homeDirectory}/.config/.sops-nix-key.txt";
  sops.secrets.pythong5k = {
    mode = "0600";
    path = "${homeDirectory}/.python-grid5000.yaml";
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
