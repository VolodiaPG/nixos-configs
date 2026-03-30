{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.services.myAnanicy;
in
{
  options.services.myAnanicy = {
    enable = lib.mkEnableOption "ananicy-cpp with custom rules and types";
  };

  config = lib.mkIf cfg.enable {
    # https://wiki.cachyos.org/configuration/sched-ext/
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
          nice = -8;
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
          nice = -8;
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
        #─────────────────────────────
        # High-priority, interactive
        #─────────────────────────────
        # Keep CPU responsive, but don't let these bully disk with ionice=0.
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
          type = "terminal";
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

        #─────────────────────────────
        # Compositor — keep smooth
        #─────────────────────────────
        # Compositor smoothness is mostly CPU scheduling; don't over-tune IO here.
        {
          name = "niri";
          type = "compositor";
        }

        #─────────────────────────────
        # Desktop — additional processes
        #─────────────────────────────
        # Core UX: these are the "if they stutter you notice" set
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

        # Idle manager: this is not something you want competing with your actual work
        {
          name = "swayidle";
          type = "service";
        }

        #─────────────────────────────
        # Build / heavy work — deprioritize the actual hogs
        #─────────────────────────────
        # This is what makes your desktop jank: compilers, linkers, builders, compressors.
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

        # Container infrastructure — deprioritize CPU a bit, but do NOT "ioclass=idle" it.
        # (Idle IO here can make *interactive* container-backed workflows feel randomly terrible.)
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

        # Keep kubectl interactive (remove the penalty)
        {
          name = "kubectl";
          type = "tool";
        }
        {
          name = "kind";
          type = "tool";
        }

        #─────────────────────────────
        # Background services
        #─────────────────────────────

        # nix indexers / search daemons
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

        # LSP can affect editor responsiveness; keep IO normal, just de-prio CPU a bit.
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

        # Don't IO-starve VPN/Network management.
        {
          name = "tailscaled";
          type = "network";
        }
        {
          name = "networkmanager";
          type = "network";
        }

        #─────────────────────────────
        # Audio and video keep stable
        #─────────────────────────────
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
      "kernel.sched_autogroup_enabled" = 1;
      "kernel.sched_child_runs_first" = 0;
    };

    # https://github.com/CachyOS/ananicy-rules/issues/207
    systemd.services.ananicy-cpp.serviceConfig = {
      Delegate = "yes";
      ProtectControlGroups = false;
      ProtectKernelTunables = false;
      ReadWritePaths = [ "/sys/fs/cgroup" ];
    };
  };
}
