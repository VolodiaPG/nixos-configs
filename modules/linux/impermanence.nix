{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.impermanence;
in {
  options = with types; {
    services.impermanence = {
      enable = mkEnableOption "impermanence";

      rootVolume = mkOption {
        description = "root volume name as in /dev";
        type = str;
        default = "root_vg";
      };

      disko = mkOption {
        description = "Is disko enabled";
        type = bool;
        default = false;
      };

      deleteAfterDays = mkOption {
        description = "delete older roots after number of days";
        type = str;
        default = "7";
      };

      btrfsOptions = mkOption {
        description = "optimization options for the subvolume";
        type = listOf str;
        default = ["ssd" "compress-force=zstd:2" "noatime" "discard=async" "space_cache=v2" "autodefrag"]; #compress: 1 for nvme, 2 for sata ssd, "3/4 for hdd";
      };

      persistent = mkOption {
        description = "The persistent volume configuration";
        type = attrs;
        default = {};
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.impermanence-setup = {
      description = "Set up impermanent root";
      wantedBy = ["local-fs-pre.target"];
      before = let
        ensureValidServiceName = name:
          if lib.hasSuffix ".service" name
          then name
          else name + ".service";
        services = map ensureValidServiceName (
          lib.attrNames (
            lib.filterAttrs (
              name: _:
                lib.hasPrefix "persist-" name
            )
            config.systemd.services
          )
        );
      in
        ["local-fs-pre.target" "local-fs.target"]
        ++ services;
      after = ["systemd-fsck-root.service"];
      path = with pkgs; [
        btrfs-progs
        coreutils
        findutils
        util-linux
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      unitConfig = {
        DefaultDependencies = false;
        Conflicts = "shutdown.target";
      };
      restartIfChanged = false;
      script = let
        directoriesList = config.environment.persistence."/persistent".directories;
        directories = builtins.map (set: "\"" + set.directory + "\"") directoriesList;

        dirname = path: let
          components = strings.splitString "/" path;
          length = builtins.length components;
          dirname = builtins.concatStringsSep "/" (lists.take (length - 1) components);
        in
          dirname;
        filesList = map (set: set.file) config.environment.persistence."/persistent".files;
        files = builtins.map dirname filesList;

        directoriesToBind = directories ++ files;
      in ''
        mkdir -p /btrfs_tmp
        mount /dev/${cfg.rootVolume} /btrfs_tmp
        if [[ -e /btrfs_tmp/root ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
        fi

        delete_subvolume_recursively() {
            IFS=$'\n'
            for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
            done
            btrfs subvolume delete "$1"
        }

        for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +${cfg.deleteAfterDays}); do
            delete_subvolume_recursively "$i"
        done

        btrfs subvolume create /btrfs_tmp/root

        mkdir -p /btrfs_tmp/root/boot
        mkdir -p /btrfs_tmp/root/nix
        mkdir -p /btrfs_tmp/root/persistent
        ${builtins.concatStringsSep "\n" (builtins.map (dir: "mkdir -p /btrfs_tmp/root" + dir) directoriesToBind)}
        ${builtins.concatStringsSep "\n" (builtins.map (dir: "mkdir -p /btrfs_tmp/persistent" + dir) directoriesToBind)}
        ${builtins.concatStringsSep "\n" (builtins.map (dir: "touch /btrfs_tmp/persistent" + dir) filesList)}

        umount /btrfs_tmp
      '';
    };
    boot.supportedFilesystems = ["btrfs"];

    fileSystems = mkMerge [
      (
        mkIf cfg.disko
        {"/persistent".neededForBoot = true;}
      )

      (
        mkIf (!cfg.disko) {
          "/" = {
            device = "/dev/${cfg.rootVolume}";
            fsType = "btrfs";
            options = ["subvol=root"] ++ cfg.btrfsOptions;
          };

          "/persistent" = {
            device = "/dev/${cfg.rootVolume}";
            neededForBoot = true;
            fsType = "btrfs";
            options = ["subvol=persistent"] ++ cfg.btrfsOptions;
          };

          "/nix" = {
            device = "/dev/${cfg.rootVolume}";
            fsType = "btrfs";
            options = ["subvol=nix"] ++ cfg.btrfsOptions;
          };
        }
      )
    ];

    environment.persistence."/persistent" =
      foldl recursiveUpdate {}
      [
        cfg.persistent
        {
          hideMounts = true;
          directories = [
            "/var/log"
            "/var/lib/bluetooth"
            "/var/lib/nixos"
            "/var/lib/systemd"
            "/var/lib/containers" # podman caches
            "/run/k3s/containerd" # K3S caches
            "/var/lib/rancher/k3s/agent/containerd"
            "/var/lib/docker"
            "/var/lib/tailscale"
            "/root"
            "/etc/ssh/"
            "/etc/NetworkManager/system-connections"
            #"/run/secrets.d"
            #"/run/secrets"
            {
              directory = "/var/lib/colord";
              user = "colord";
              group = "colord";
              mode = "u=rwx,g=rx,o=";
            }
          ];
          files = [
            "/etc/machine-id"
          ];
          users.volodia = {
            directories = [
              "Downloads"
              "Music"
              "Pictures"
              "Documents"
              "Videos"
              # ".local/state/nix/profiles"
              # ".nix-profile"
              ".vscode-server"
              ".cursor-server"
              ".cursor"
              ".cursor-tutor"
              ".config"
              ".local/share/fonts/ComicCode"
              ".local/state/syncthing"
              {
                directory = ".gnupg";
                mode = "0700";
              }
              {
                directory = ".ssh";
                mode = "0700";
              }
              {
                directory = ".nixops";
                mode = "0700";
              }
              {
                directory = ".local/share/keyrings";
                mode = "0700";
              }
              ".local/share/direnv"
              ".local/share/zoxide"
              ".local/share/nvim/harpoon"
              ".docker"
              ".tmux/resurrect"
              ".mozilla"
              ".zen"
            ];
            files = [
              ".bash_history"
              ".local/share/fish/fish_history"
              ".local/share/nvim/harpoon.json"
            ];
          };
        }
      ];
  };
}
