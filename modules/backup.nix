_: {
  config.nixos.backup =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.services.backup = {
        paths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "What to backup";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "";
        };

        password = lib.mkOption {
          type = lib.types.path;
          default = "/dev/null";
        };

        subuser = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
      };

      # ponytail: only configure restic when backup paths are set
      config = lib.mkIf (config.services.backup.paths != [ ]) {
        services.restic.backups = {
          remotebackup = {
            initialize = true;
            inherit (config.services.backup) paths;

            repository = "sftp:${config.services.backup.user}-${config.services.backup.subuser}@${config.services.backup.user}.your-storagebox.de:/backup";
            # data encryption key
            passwordFile = config.age.secrets.hetzner-data-encryption-key.path;

            # Tell restic to use your decrypted agenix private key instead of a password
            extraOptions = [
              "sftp.command='${pkgs.sshpass}/bin/sshpass -f ${config.age.secrets.hetzner-token.path} -- ssh -4 -o StrictHostKeyChecking=no ${config.services.backup.user}.your-storagebox.de -P 23 -l ${config.services.backup.user}-${config.services.backup.subuser} -s sftp'"
            ];

            timerConfig = {
              # when to backup
              OnCalendar = "00:05";
              RandomizedDelaySec = "5h";
            };
          };
        };
      };
    };
}
