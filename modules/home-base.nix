{
  config,
  self,
  ...
}:
let
  inherit (config) me;
in
{
  config.home.base =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
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
        inherit (me) username;
        homeDirectory = me.homeDirectory pkgs.stdenv;
        file = {
          ".ssh/config" = {
            text = builtins.readFile (self + "/static/config.ssh");
            force = true;
          };
          ".ssh/authorized_keys" = {
            text = lib.concatStringsSep "\n" me.keys;
            force = true;
          };
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
          grc
          bottom
          libgtop
          lsof
          chezmoi
          starship
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
