{
  homeDirectory,
  pkgs,
  lib,
  ...
}:
# let
# script = toString (pkgs.writeShellScript "sops-nix-perms"
#   (
#     (lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
#       while ! pgrep -x "sops-nix" > /dev/null; do
#         sleep 1
#       done
#     '')
#     + ''
#       ${pkgs.toybox}/bin/chmod ${config.sops.secrets.pythong5k.mode} ${config.sops.secrets.pythong5k.path}
#     ''
#   ));
# in
{
  imports = [
    ./common.nix
  ];
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

  # # systemd.user.services.sops-nix-perms = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # #   Unit = {
  # #     Description = "sops-nix activation (perms)";
  # #     After = ["sops-nix.service"];
  # #   };
  # #   Service = {
  # #     Type = "oneshot";
  # #     ExecStart = script;
  # #   };
  # #   Install.WantedBy = ["default.target"];
  # # };

  # launchd.agents.sops-nix-perms = {
  #   enable = true;
  #   config = {
  #     ProgramArguments = [script];
  #     KeepAlive = {
  #       Crashed = false;
  #       SuccessfulExit = false;
  #     };
  #     ProcessType = "Background";
  #     StandardOutPath = "${homeDirectory}/Library/Logs/SopsNix/stdout";
  #     StandardErrorPath = "${homeDirectory}/Library/Logs/SopsNix/stderr";
  #   };
  # };
}
