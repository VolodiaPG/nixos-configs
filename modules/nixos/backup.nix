{
  pkgs,
  flake,
  config,
  lib,
  ...
}:
let
  inherit (flake.config.me) hetzner-storagebox;
  cfg = config.services.backup;
in
{
  options = {
    services.backup = {
      enable = lib.mkEnableOption "Backup with restic";

      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "What to backup";
      };

      user = lib.mkOption {
        type = lib.types.str;
      };

      password = lib.mkOption {
        type = lib.types.path;
      };

      subuser = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    services.restic.backups = {
      remotebackup = {
        initialize = true;
        inherit (cfg) paths;

        repository = "sftp:${cfg.user}-${cfg.subuser}${cfg.user}.your-storagebox.de:/backup";
        # data encryption key
        passwordFile = config.age.secrets.hetzner-data-encryption-key.path;

        # Tell restic to use your decrypted agenix private key instead of a password
        extraOptions = [
          "sftp.command='${pkgs.sshpass}/bin/sshpass -f ${config.age.secrets.hetzner-token.path} -- ssh -4 -o StrictHostKeyChecking=no ${cfg.user}.your-storagebox.de -P 23 -l ${cfg.user}-${cfg.subuser} -s sftp'"
        ];

        timerConfig = {
          # when to backup
          OnCalendar = "00:05";
          RandomizedDelaySec = "5h";
        };
      };
    };
  };
}
