{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  cfg = config.commonHome;
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    commonHome = {
      enable = mkEnableOption "Common home configuration";
    };
  };

  config = mkIf cfg.enable {
    xdg.enable = true;

    programs = {
      home-manager.enable = true;
      git.enable = true;
      zsh.enable = true;
      zoxide = {
        enable = true;
        enableZshIntegration = true;
        options = [
          "--cmd cd"
        ];
      };
      ssh.enable = true;
      tmux.enable = true;
      # starship = {
      #   enable = true;
      #   enableZshIntegration = true;
      #   settings = {
      #     add_newline = false;
      #     format = lib.concatStrings [
      #       "$directory"
      #       "$git_branch"
      #       "$git_status"
      #       "$cmd_duration"
      #       "$character"
      #     ];
      #
      #     directory = {
      #       format = "[$path]($style) ";
      #     };
      #
      #     character = {
      #       success_symbol = "[➜](green)";
      #       error_symbol = "[➜](red)";
      #     };
      #
      #     scan_timeout = 10;
      #   };
      # };
      keychain = {
        enable = true;
        enableZshIntegration = true;
        keys = [
          "id_ed25519"
        ];
      };
    };

    services = {
      # gpg-agent = {
      #   enable = pkgs.stdenv.isLinux;
      #   grabKeyboardAndMouse = false;
      #   pinentry.package = pkgs.pinentry-tty;
      #   extraConfig = ''
      #     allow-loopback-pinentry
      #   '';
      #   enableSshSupport = true;
      #   enableExtraSocket = true;
      #   enableScDaemon = false;
      # };
      ssh-agent.enable = true;
    };

    home = {
      inherit (flake.config.me) username;
      homeDirectory = flake.config.me.homeDirectory pkgs.stdenv;
      file = {
        ".ssh/config" = {
          text = builtins.readFile (flake.self + "/static/config.ssh");
          force = true;
        };
        ".ssh/authorized_keys" = {
          text = lib.concatStringsSep "\n" flake.config.me.keys;
          force = true;
        };
      };

      packages = [
        pkgs.mosh
        pkgs.ripgrep
        pkgs.findutils
        pkgs.parallel
        pkgs.zip
        pkgs.unzip
        pkgs.gdu
        pkgs.htop
        pkgs.nmap
        pkgs.wget
        pkgs.grc
        pkgs.bottom
        pkgs.libgtop
        pkgs.lsof
        pkgs.chezmoi
        pkgs.starship
      ];

      sessionVariables = {
        EDITOR = "vim";
        NIXOS_OZONE_WL = 1;
        MOZ_ENABLE_WAYLAND = 1;
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };
    };
    home.stateVersion = "22.05";
  };
}
