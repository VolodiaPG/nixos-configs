_: {
  config.nixos.desktop =
    {
      pkgs,
      lib,
      ...
    }:
    {
      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
        extraTypes = [
          {
            name = "audio";
            nice = 0;
            ioclass = "best-effort";
            ionice = 4;
          }
          {
            name = "build";
            nice = 12;
            ioclass = "best-effort";
            ionice = 6;
          }
          {
            name = "comms";
            nice = -6;
            ioclass = "best-effort";
            ionice = 3;
          }
          {
            name = "compositor";
            nice = -5;
            ioclass = "best-effort";
            ionice = 4;
          }
          {
            name = "desktop";
            nice = -4;
            ioclass = "best-effort";
            ionice = 4;
          }
          {
            name = "editor";
            nice = 0;
            ioclass = "best-effort";
            ionice = 3;
          }
          {
            name = "indexer";
            nice = 10;
            ioclass = "idle";
          }
          {
            name = "maintenance";
            nice = 12;
            ioclass = "idle";
          }
          {
            name = "network";
            nice = 0;
            ioclass = "best-effort";
            ionice = 4;
          }
          {
            name = "service";
            nice = 5;
            ioclass = "best-effort";
            ionice = 6;
          }
          {
            name = "terminal";
            nice = 0;
            ioclass = "best-effort";
            ionice = 3;
          }
          {
            name = "tool";
            nice = 0;
            ioclass = "best-effort";
            ionice = 4;
          }
          {
            name = "video";
            nice = 0;
            ioclass = "best-effort";
            ionice = 5;
          }
        ];
        extraRules = [
          {
            name = "code";
            type = "editor";
          }
          {
            name = "zed";
            type = "editor";
          }
          {
            name = "nvim";
            type = "editor";
          }
          {
            name = "lazygit";
            type = "terminal";
          }
          {
            name = "opencode";
            type = "terminal";
          }
          {
            name = "kitty";
            type = "editor";
          }
          {
            name = "signal-desktop";
            type = "comms";
          }
          {
            name = "zoom";
            type = "comms";
          }
          {
            name = "zoom-us";
            type = "comms";
          }
          {
            name = "niri";
            type = "compositor";
          }
          {
            name = "fuzzel";
            type = "desktop";
          }
          {
            name = "noctalia-shell";
            type = "desktop";
          }
          {
            name = "quickshell";
            type = "desktop";
          }
          {
            name = "greetd";
            type = "desktop";
          }
          {
            name = "swayidle";
            type = "service";
          }
          {
            name = "lix";
            type = "build";
          }
          {
            name = "nix";
            type = "build";
          }
          {
            name = "nix-daemon";
            type = "build";
          }
          {
            name = "nix-store";
            type = "build";
          }
          {
            name = "rustc";
            type = "build";
          }
          {
            name = "cc1";
            type = "build";
          }
          {
            name = "cc1plus";
            type = "build";
          }
          {
            name = "clang";
            type = "build";
          }
          {
            name = "gcc";
            type = "build";
          }
          {
            name = "ld";
            type = "build";
          }
          {
            name = "ld.lld";
            type = "build";
          }
          {
            name = "collect2";
            type = "build";
          }
          {
            name = "ninja";
            type = "build";
          }
          {
            name = "make";
            type = "build";
          }
          {
            name = "cmake";
            type = "build";
          }
          {
            name = "meson";
            type = "build";
          }
          {
            name = "zstd";
            type = "build";
          }
          {
            name = "xz";
            type = "build";
          }
          {
            name = "gzip";
            type = "build";
          }
          {
            name = "bzip2";
            type = "build";
          }
          {
            name = "latexmk";
            type = "build";
          }
          {
            name = "xelatex";
            type = "build";
          }
          {
            name = "dockerd";
            type = "build";
          }
          {
            name = "containerd";
            type = "build";
          }
          {
            name = "buildkitd";
            type = "build";
          }
          {
            name = "podman";
            type = "build";
          }
          {
            name = "kubectl";
            type = "tool";
          }
          {
            name = "kind";
            type = "tool";
          }
          {
            name = "nix-index";
            type = "indexer";
          }
          {
            name = "nix-index-daemon";
            type = "indexer";
          }
          {
            name = "nix-locate";
            type = "indexer";
          }
          {
            name = "nixd";
            type = "indexer";
          }
          {
            name = "texlab";
            type = "indexer";
          }
          {
            name = "lua-language-server";
            type = "indexer";
          }
          {
            name = "expert";
            type = "indexer";
          }
          {
            name = "harper-ls";
            type = "indexer";
          }
          {
            name = "updatedb";
            type = "maintenance";
          }
          {
            name = "fwupd";
            type = "maintenance";
          }
          {
            name = "fwupd-efi";
            type = "maintenance";
          }
          {
            name = "cupsd";
            type = "service";
          }
          {
            name = "tailscaled";
            type = "network";
          }
          {
            name = "networkmanager";
            type = "network";
          }
          {
            name = "pipewire";
            type = "audio";
          }
          {
            name = "pipewire-pulse";
            type = "audio";
          }
          {
            name = "wireplumber";
            type = "audio";
          }
          {
            name = "cosmic-player";
            type = "audio";
          }
          {
            name = "cheese";
            type = "video";
          }
          {
            name = "simple-scan";
            type = "video";
          }
        ];
      };

      boot.kernel.sysctl = {
        "kernel.sched_autogroup_enabled" = lib.mkDefault 1;
        "kernel.sched_child_runs_first" = lib.mkDefault 0;
      };

      systemd.services.ananicy-cpp.serviceConfig = {
        Delegate = "yes";
        ProtectControlGroups = false;
        ProtectKernelTunables = false;
        ReadWritePaths = [ "/sys/fs/cgroup" ];
      };
    };
}
