{
  config,
  inputs,
  ...
}:
let
  inherit (config) me;
in
{
  config.darwin.mac =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    with types;
    {
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

      users.users."${me.username}" = {
        name = me.username;
        home = me.homeDirectory pkgs.stdenv;
        shell = pkgs.zsh;
      };

      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = me.username;
      };

      homebrew = {
        enable = true;
        brews = [
          "ollama"
          "mpv"
          "vmnet-helper"
        ];
        casks = [
          "hiddenbar"
          "karabiner-elements"
          "tg-pro"
          "bettermouse"
          "alt-tab"
          "tidal"
          "parsec"
          "signal"
          "vlc"
          "calibre"
          "steam"
          "betterdisplay"
        ];
        taps = [
          "nirs/vmnet-helper"
        ];
      };

      environment.systemPackages = with pkgs; [
        terminal-notifier
        kitty
        fswatch
        qbittorrent
        zotero
        podman
        podman-compose
      ];

      services = {
        yabai = {
          enable = lib.mkForce false;
          package = pkgs.yabai;
          enableScriptingAddition = true;
        };
      };

      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };

      environment.shellInit = ''
        ulimit -n 524288
      '';

      launchd = {
        daemons = {
          limit-maxfiles = {
            script = ''
              /bin/launchctl limit maxfiles 524288 524288
            '';
            serviceConfig = {
              RunAtLoad = true;
              KeepAlive = false;
              Label = "org.nixos.limit-maxfiles";
              StandardOutPath = "/var/log/limit-maxfiles.log";
              StandardErrorPath = "/var/log/limit-maxfiles.log";
            };
          };
        };
      };

      system = {
        defaults = {
          NSGlobalDomain.NSWindowResizeTime = 0.001;
        };
        activationScripts.extraActivation.text = ''
          /usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license
        '';
        stateVersion = 5;
      };
    };
}
