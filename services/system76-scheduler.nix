{ config, pkgs, lib, ... }:


{
  options = {
    services.system76Scheduler = with lib; with types; {
      enable = mkEnableOption "system76Scheduler";

      package = mkOption {
        description = "system76Scheduler package";
        defaultText = "pkgs.system76Scheduler";
        type = package;
        default = pkgs.callPackage ../pkgs/system76-scheduler { };
      };
    };
  };

  ### Implementation ###

  config =
    let
      cfg = config.services.zrepl;

      configFile = pkgs.runCommand "zrepl.yml"
        {
          inherit configuration;
          passAsFile = [ "configuration" ];
        } ''
        ${pkgs.jq}/bin/jq < "$configurationPath" > "$out"
      '';

      configuration = builtins.toJSON ({
        global.logging = [{
          format = "human";
          type = "stdout";
          level = cfg.logging.level;
        }];
        jobs = (lib.mapAttrsToList mkSinkJob cfg.sink)
          ++ (lib.mapAttrsToList mkPushJob cfg.push)
          ++ (lib.mapAttrsToList mkLocalPush cfg.local)
          ++ (lib.mapAttrsToList mkLocalSink cfg.local);
      } // (if cfg.monitoring.port != null then {
        global.monitoring = [{
          type = "prometheus";
          listen = ":${builtins.toString cfg.monitoring.port}";
        }];
      } else { }));

      mkSinkJob = name: sink: {
        name = "${name}_sink";
        type = "sink";
        root_fs = sink.targetFS;
        serve = {
          type = "tls";
          listen = ":${builtins.toString sink.port}";
          client_cns = sink.clients;
          ca = "/var/spool/zrepl/ca.crt";
          cert = "/var/spool/zrepl/${config.networking.hostName}.crt";
          key = "/var/spool/zrepl/${config.networking.hostName}.key";
        };
      };

      mkPushJob = name: push: {
        name = "${name}_push";
        type = "push";
        connect = {
          type = "tls";
          address = "${push.targetHost}:${builtins.toString push.targetPort}";
          ca = "/var/spool/zrepl/ca.crt";
          cert = "/var/spool/zrepl/${config.networking.hostName}.crt";
          key = "/var/spool/zrepl/${config.networking.hostName}.key";
          server_cn = push.serverCN;
        };
        filesystems = filesystemsConfig push;
        snapshotting = snapshotConfig push;
        pruning = pruningConfig push;
      };

      mkLocalSink = name: sink: {
        name = "${name}_local_sink";
        type = "sink";
        root_fs = sink.targetFS;
        serve = {
          type = "local";
          listener_name = "${name}_local_listener";
        };
      };

      mkLocalPush = name: push: {
        name = "${name}_local_push";
        type = "push";
        connect = {
          type = "local";
          listener_name = "${name}_local_listener";
          client_identity = name;
        };
        filesystems = filesystemsConfig push;
        snapshotting = snapshotConfig push;
        pruning = pruningConfig push;
      };

      filesystemsConfig = push: {
        "${push.sourceFS}<" = true;
      } // (pkgs.lib.genAttrs push.exclude (fs: false));

      snapshotConfig = push: {
        type = "periodic";
        prefix = push.snapshotting.prefix;
        interval = "${builtins.toString push.snapshotting.interval}m";
      };

      pruningConfig = push: {
        # TODO: Add some configurability here.
        keep_sender = [{
          type = "not_replicated";
        }
          {
            type = "grid";
            grid = "1x3h(keep=all) | 24x1h | 7x1d";
            regex = "^${push.snapshotting.prefix}";
          }];
        keep_receiver = [{
          type = "grid";
          grid = "24x1h | 30x1d | 6x14d";
          regex = "^${push.snapshotting.prefix}";
        }];
      };

      byRootFs = { command, set, attribute }: lib.concatStringsSep "\n" (lib.mapAttrsToList
        (name: value: ''
          ${command} "${value.${attribute}}"
        '')
        set);
    in

    lib.mkIf cfg.enable {
      environment.etc."zrepl.yml".source = configFile;

      networking.firewall.allowedTCPPorts = builtins.filter (p: p != null) (
        lib.mapAttrsToList (name: sink: if sink.openFirewall then sink.port else null)
          cfg.sink);

      systemd.services.zrepl = {
        enable = cfg.enable;

        description = "ZFS Replication";
        documentation = [ "https://zrepl.github.io/" ];

        requires = [ "local-fs.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          #User = "zrepl";
        };

        path = [ cfg.package pkgs.zfs pkgs.super ];
        script = ''
          set -e

          HOME=/var/spool/zrepl

          # Create the directories, if needed.
          mkdir -pm 0770 $HOME /var/run/zrepl
          chown zrepl $HOME /var/run/zrepl

          cd $HOME

          if [[ ! -e ca.crt ]]; then
            echo 'You must manually create the certificate authority and host keys.'
            echo 'Look at https://zrepl.github.io/configuration/transports.html#transport-tcp-tlsclientauth-2machineopenssl'
            echo 'for instructions, and name them according to /etc/zrepl.yml.'
            echo 'We recommend the easyrsa package.'
            exit 1
          fi

          # Setup datasets & permissions
          setupSink() {
            if ! zfs list -H "$1"; then
              zfs create "$1" -o mountpoint=none
            fi
            # We do not intend to mount filesystems, and non-root users
            # anyway can't, but due to limitations in zfs-on-linux the user
            # still needs the permission.
            #
            # The mountpoint permission is needed because zrepl sets
            # mountpoint=none. It's a little bizarre, but there you go.
            zfs unallow -ldu zrepl "$1"
            zfs allow -ldu zrepl mount,clone,create,destroy,hold,promote,receive,release,rename,rollback,snapshot,bookmark,userprop,mountpoint "$1"
          }

          setupPush() {
            zfs unallow -ldu zrepl "$1"
            zfs allow -ldu zrepl mount,destroy,hold,promote,send,release,snapshot,bookmark,userprop "$1"
          }
        '' + byRootFs { command = "setupSink"; set = cfg.sink; attribute = "targetFS"; }
        + byRootFs { command = "setupPush"; set = cfg.push; attribute = "sourceFS"; }
        + byRootFs { command = "setupSink"; set = cfg.local; attribute = "targetFS"; }
        + byRootFs { command = "setupPush"; set = cfg.local; attribute = "sourceFS"; }
        + ''
           
        # Ensure ownership and permissions
        chown -R zrepl:root $HOME
        chmod -R o= $HOME

        # Set environment variable to allow certs without a SAN
        export GODEBUG=x509ignoreCN=0

        # Start the daemon.
        exec setuid zrepl zrepl --config=/etc/zrepl.yml daemon
      '';
      };

      users.users.zrepl = {
        uid = 316;
        isSystemUser = true;
        home = "/var/spool/zrepl";
        extraGroups = [ "wheel" ];
      };

      environment.systemPackages = [
        (cfg.package)
      ];

      security.wrappers.zrepl-status.source = pkgs.stdenv.mkDerivation {
        name = "zrepl-status";
        unpackPhase = "true";
        installPhase = ''
          cat > zrepl-status.c <<'EOF'
            #include <unistd.h>
            #include <stdlib.h>
            #include <string.h>

            int main() {
              char *term = strdup(getenv("TERM"));
              clearenv();
              setenv("TERM", term, 1);

              return execl("${cfg.package}/bin/zrepl",
                "zrepl-status",
                "--config=/etc/zrepl.yml", "status", (char*)NULL);
            }
          EOF

          gcc zrepl-status.c -Os -o $out
        '';
      };
    };
}
