{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    mkMerge
    foldl
    recursiveUpdate
    ;
  inherit (lib.types)
    str
    bool
    int
    listOf
    attrs
    enum
    ;
  cfg = config.services.impermanence;

  persistServiceNames =
    let
      ensureValidServiceName = name: if lib.hasSuffix ".service" name then name else name + ".service";
    in
    map ensureValidServiceName (
      lib.attrNames (lib.filterAttrs (name: _: lib.hasPrefix "persist-" name) config.systemd.services)
    );
in
{
  imports = [ flake.inputs.impermanence.nixosModules.impermanence ];

  options = {
    services.impermanence = {
      enable = mkEnableOption "impermanence";

      fsType = mkOption {
        description = ''
          Filesystem type of the root volume.
          - btrfs: rotates the root via subvolumes (moves the old `root` subvolume into `old_roots/`).
          - ext4/xfs: no subvolumes; the old root contents are moved into an `old_roots/` directory at the volume root.
          ext4/xfs require separate partitions for /nix and /persistent (e.g. via disko LVM), since only the root volume is rotated.
        '';
        type = enum [
          "btrfs"
          "ext4"
          "xfs"
        ];
        default = "btrfs";
      };

      rootVolume = mkOption {
        description = "Full stable device path of the root volume (e.g. /dev/disk/by-id/... or /dev/disk/by-label/...)";
        type = str;
        default = "/dev/root_vg";
      };

      disko = mkOption {
        description = "Is disko enabled";
        type = bool;
        default = false;
      };

      cleanReset = mkOption {
        description = ''
          For ext4/xfs: instead of archiving the previous root contents into an
          `old_roots/` directory, wipe and reformat the root partition on every
          boot in the initrd. This is a destructive reset: `/` will be empty
          after the initrd step. Only valid for fsType `ext4` or `xfs` (btrfs
          already rotates via subvolumes).
        '';
        type = bool;
        default = false;
      };

      deleteAfterDays = mkOption {
        description = "delete older roots after number of days";
        type = int;
        default = 7;
      };

      btrfsOptions = mkOption {
        description = "optimization options for the subvolume";
        type = listOf str;
        default = [
          "ssd"
          "compress-force=zstd:2"
          "noatime"
          "discard=async"
          "space_cache=v2"
          "autodefrag"
        ]; # compress: 1 for nvme, 2 for sata ssd, "3/4 for hdd";
      };

      persistent = mkOption {
        description = "The persistent volume configuration";
        type = attrs;
        default = { };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/dev/" cfg.rootVolume;
        message = "services.impermanence.rootVolume must be a full device path starting with /dev/ (got: ${cfg.rootVolume})";
      }
      {
        assertion = !(cfg.cleanReset && cfg.fsType == "btrfs");
        message = "services.impermanence.cleanReset has no effect with fsType = \"btrfs\" (the rotating subvolume is wiped each boot anyway). Set fsType to \"ext4\" or \"xfs\" or unset cleanReset.";
      }
    ];

    boot = {
      supportedFilesystems = [ cfg.fsType ];

      initrd.systemd = {
        enable = mkIf (cfg.fsType == "btrfs" || cfg.cleanReset) true;

        services.impermanence-btrfs-rolling-root = mkIf (cfg.fsType == "btrfs") {
          description = "Archiving existing BTRFS root subvolume and creating a fresh one";
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            StandardOutput = "journal+console";
            StandardError = "journal+console";
          };
          requiredBy = [ "initrd.target" ];
          before = [ "sysroot.mount" ];
          requires = [ "initrd-root-device.target" ];
          after = [
            "initrd-root-device.target"
            "local-fs-pre.target"
            "systemd-cryptsetup@crypted.service"
          ];
          script = ''
            mkdir -p /btrfs_tmp
            mount ${cfg.rootVolume} /btrfs_tmp
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

            for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +${toString cfg.deleteAfterDays}); do
                delete_subvolume_recursively "$i"
            done

            btrfs subvolume create /btrfs_tmp/root
            umount /btrfs_tmp
          '';
        };

        extraBin = mkMerge [
          (mkIf (cfg.fsType == "btrfs") {
            "mkdir" = "${pkgs.coreutils}/bin/mkdir";
            "date" = "${pkgs.coreutils}/bin/date";
            "stat" = "${pkgs.coreutils}/bin/stat";
            "mv" = "${pkgs.coreutils}/bin/mv";
            "find" = "${pkgs.findutils}/bin/find";
            "btrfs" = "${pkgs.btrfs-progs}/bin/btrfs";
          })
          (mkIf (cfg.cleanReset && cfg.fsType == "ext4") {
            "mkfs.ext4" = "${pkgs.e2fsprogs}/bin/mkfs.ext4";
          })
          (mkIf (cfg.cleanReset && cfg.fsType == "xfs") {
            "mkfs.xfs" = "${pkgs.xfsprogs}/bin/mkfs.xfs";
          })
        ];

        services.impermanence-clean-reset = mkIf (cfg.cleanReset && cfg.fsType != "btrfs") {
          description = "Wiping and reformatting the root partition before sysroot mount";
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            StandardOutput = "journal+console";
            StandardError = "journal+console";
          };
          requiredBy = [ "initrd.target" ];
          before = [ "sysroot.mount" ];
          requires = [ "initrd-root-device.target" ];
          after = [
            "initrd-root-device.target"
            "local-fs-pre.target"
            "systemd-cryptsetup@crypted.service"
          ];
          script =
            if cfg.fsType == "ext4" then
              ''
                mkfs.ext4 -F -L root ${cfg.rootVolume}
              ''
            else if cfg.fsType == "xfs" then
              ''
                mkfs.xfs -f -L root ${cfg.rootVolume}
              ''
            else
              "";
        };
      };
    };

    systemd.services.impermanence-setup = mkIf (cfg.fsType != "btrfs" && !cfg.cleanReset) {
      description = "Set up impermanent root";
      wantedBy = [ "local-fs-pre.target" ];
      before = [
        "local-fs-pre.target"
        "local-fs.target"
      ]
      ++ persistServiceNames;
      after = [ "systemd-fsck-root.service" ];
      path = [
        pkgs.coreutils
        pkgs.findutils
        pkgs.util-linux
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
      script = ''
        mkdir -p /fs_tmp
        mount ${cfg.rootVolume} /fs_tmp

        mkdir -p /fs_tmp/old_roots
        timestamp=$(date "+%Y-%m-%-d_%H:%M:%S")
        mkdir -p "/fs_tmp/old_roots/$timestamp"
        shopt -s dotglob nullglob
        for item in /fs_tmp/*; do
            case "$item" in
                /fs_tmp/old_roots|/fs_tmp/lost+found|/dev|/boot|/nix|/persistent|/proc) continue ;;
            esac
            mv "$item" "/fs_tmp/old_roots/$timestamp/"
        done
        shopt -u dotglob nullglob

        find /fs_tmp/old_roots/ -mindepth 1 -maxdepth 1 -mtime +${toString cfg.deleteAfterDays} -exec rm -rf {} +

        mkdir -p /fs_tmp/boot
        mkdir -p /fs_tmp/nix
        mkdir -p /fs_tmp/persistent

        umount /fs_tmp
      '';
    };

    fileSystems = mkMerge [
      { "/persistent".neededForBoot = true; }
      (mkIf (!cfg.disko && cfg.fsType == "btrfs") {
        "/" = {
          device = cfg.rootVolume;
          fsType = "btrfs";
          options = [ "subvol=root" ] ++ cfg.btrfsOptions;
        };

        "/persistent" = {
          device = cfg.rootVolume;
          neededForBoot = true;
          fsType = "btrfs";
          options = [ "subvol=persistent" ] ++ cfg.btrfsOptions;
        };

        "/nix" = {
          device = cfg.rootVolume;
          fsType = "btrfs";
          options = [ "subvol=nix" ] ++ cfg.btrfsOptions;
        };
      })
    ];

    environment.persistence."/persistent" = foldl recursiveUpdate { } [
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
          # NOTE: do NOT persist /etc/ssh as a directory: it would shadow the
          # NixOS-managed /etc/ssh symlink farm (sshd_config, ssh_config,
          # moduli) and break sshd. Only the host keys need to survive reboots.
          "/etc/NetworkManager/system-connections"
          "/var/lib/flatpak"
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
          # Host keys are persisted as files so /etc/ssh itself stays
          # NixOS-managed; sshd-keygen.service (ConditionFileNotEmpty)
          # regenerates empty ones, e.g. on fresh installs.
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
        ];
        users.${flake.config.me.username} = {
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
            ".local"
            ".var/app"
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
            # ".local/share/direnv"
            # ".local/share/zoxide"
            # ".local/share/nvim/harpoon"
            ".docker"
            ".tmux/resurrect"
            ".mozilla"
            ".zen"
            ".supermaven"
            ".hyperhdr"
            ".tmux"
            ".zotero"
            ".cache/flatpak"
            ".local/share/flatpak"
            ".cache/nvim"
          ];
          files = [
            ".bash_history"
            ".zsh_history"
            # ".local/state/noctalia/settings.toml"
            # ".local/share/fish/fish_history"
            # ".local/share/nvim/harpoon.json"
          ];
        };
      }
    ];
  };
}
