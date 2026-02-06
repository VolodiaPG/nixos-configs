{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib;
let
  cfg = config.commonHome;
in
{
  options = {
    commonHome = with types; {
      enable = mkEnableOption "Common home configuration";
    };
  };

  config = mkIf cfg.enable {
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
      starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          add_newline = false;
          format = lib.concatStrings [
            "$directory"
            "$git_branch"
            "$git_status"
            "$cmd_duration"
            "$character"
          ];

          directory = {
            format = "[$path]($style) ";
          };

          character = {
            success_symbol = "[➜](green)";
            error_symbol = "[➜](red)";
          };

          scan_timeout = 10;
        };
      };
      keychain = {
        enable = true;
        enableZshIntegration = true;
        keys = [
          "id_ed25519"
        ];
      };
    };

    services.gpg-agent = {
      enable = pkgs.stdenv.isLinux;
      grabKeyboardAndMouse = false;
      pinentry.package = pkgs.pinentry-tty;
      extraConfig = ''
        allow-loopback-pinentry
      '';
      enableSshSupport = true;
      enableExtraSocket = true;
      enableScDaemon = false;
    };

    home = {
      inherit (flake.config.me) username;
      homeDirectory = flake.config.me.homeDirectory pkgs.stdenv;
      file = {
        ".ssh/config" = {
          target = ".ssh/config_source";
          onChange = "cat ~/.ssh/config_source > ~/.ssh/config && chmod 400 ~/.ssh/config";
          source = pkgs.replaceVars (flake.inputs.self + "/static/config.ssh") {
            g5k_login = "volparolguarino";
            keychain = if pkgs.stdenv.isLinux then "" else "UseKeychain yes";
          };

        };
        ".ssh/authorized_keys".text = lib.concatStringsSep "\n" flake.config.me.keys;
      };

      packages = with pkgs; [
        mosh
        ripgrep
        findutils
        parallel
        zip
        unzip
        gdu
        htop
        nmap
        wget
        fzf
        grc
        bottom
        libgtop
        lsof
      ];

      sessionVariables = {
        EDITOR = "nvim";
      };
    };
    home.stateVersion = "22.05";
  };
}
