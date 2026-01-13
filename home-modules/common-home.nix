{
  pkgs,
  user,
  lib,
  ...
}:
{
  fonts.fontconfig.enable = true;

  catppuccin.enable = true;

  programs = {
    home-manager.enable = true;
    lazygit = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        git = {
          pagers = [
            { useExternalDiffGitConfig = true; }
          ];
        };
      };
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
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
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      stdlib = ''
        export DIRENV_LOG_FORMAT=""
      '';
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
    inherit (user) username homeDirectory;
    packages = with pkgs; [
      fontconfig
      tmux
      mosh
      difftastic
      ripgrep
      direnv
      findutils
      parallel
      zip
      unzip
      gdu
      zoxide
      git-crypt
      cocogitto
      python3
      htop
      nmap
      wget
      fzf
      grc
      libnotify
      notify-desktop
      tmux
      bottom
      libgtop
      lsof
    ];

    sessionVariables = {
      EDITOR = "nvim";
    };

    file = {
      ".config/discord/settings.json".text = ''
        {
          "BACKGROUND_COLOR": "#202225",
          "IS_MAXIMIZED": false,
          "IS_MINIMIZED": true,
          "SKIP_HOST_UPDATE": true,
          "WINDOW_BOUNDS": {
            "x": 307,
            "y": 127,
            "width": 1280,
            "height": 725
          }
        }
      '';
      ".ssh/authorized_keys".text = lib.concatStringsSep "\n" user.keys;
      ".config/kitty/kitty.conf".source = ./kitty.conf;
    };

    stateVersion = "22.05";
  };
}
