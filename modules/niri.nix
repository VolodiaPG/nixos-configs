_: {
  config.nixos.niri =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    {
      options.services.wm.niri.package = mkOption {
        type = types.package;
        default = pkgs.niri;
        description = "The niri package to use";
      };

      config = {
        programs = {
          niri = {
            enable = true;
            useNautilus = true;
            package = config.services.wm.niri.package;
          };
          xwayland.enable = true;
          dconf.enable = true;
        };

        services = {
          greetd = {
            enable = true;
            settings = {
              default_session = {
                command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
                user = "greeter";
              };
            };
          };
          displayManager.sessionPackages = [ config.services.wm.niri.package ];
          gvfs.enable = true;
          gnome.gnome-keyring.enable = true;
          upower.enable = true;
          geoclue2.enable = true;
        };

        hardware.graphics.enable = true;
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
        };

        environment.systemPackages = with pkgs; [
          grim
          slurp
          wl-clipboard
          polkit_gnome
          xdg-utils
          swayidle
          cliphist
        ];

        security.polkit.enable = true;
        networking.networkmanager.enable = true;
      };
    };

  config.home.niri =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    {
      options.wm.niri.package = mkOption {
        type = types.package;
        default = pkgs.niri;
        description = "The niri package to use";
      };

      options.nirius.scratchpads = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              appId = mkOption {
                type = types.str;
                description = "The app-id to match for this scratchpad";
              };
              spawn = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Command to spawn if the app isn't running";
              };
            };
          }
        );
        default = [ ];
        description = "List of scratchpad configurations";
      };

      config = {
        home.packages = with pkgs; [
          config.wm.niri.package
          fuzzel
          grim
          slurp
          satty
          wl-clipboard
          cliphist
          swaybg
          wpaperd
          wlogout
          wlr-randr
          polkit_gnome
          kdePackages.qttools
          wl-mirror
          brightnessctl
          nirius
        ];

        xdg = {
          portal = {
            enable = true;
            config = {
              common = {
                default = [
                  "gtk"
                  "gnome"
                ];
              };
              niri = {
                default = [
                  "gtk"
                  "gnome"
                ];
              };
            };
            extraPortals = with pkgs; [
              xdg-desktop-portal-gtk
              xdg-desktop-portal-gnome
            ];
            xdgOpenUsePortal = true;
          };
          configFile."electron-flags.conf".text = ''
            --enable-features=UseOzonePlatform
            --ozone-platform=wayland
          '';
        };

        gtk.enable = true;

        programs.fuzzel = {
          enable = true;
          settings = {
            main = {
              font = "Noto Sans:size=11";
              prompt = "❯ ";
              width = 50;
              lines = 15;
              horizontal-pad = 20;
              vertical-pad = 10;
              inner-pad = 8;
              line-height = 24;
            };
            colors = {
              background = "1e1e2eff";
              text = "cdd6f4ff";
              match = "f38ba8ff";
              selection = "585b70ff";
              selection-text = "cdd6f4ff";
              selection-match = "f38ba8ff";
              border = "f38ba8ff";
            };
            border = {
              width = 2;
              radius = 12;
            };
          };
        };

        services.kdeconnect.enable = true;

        systemd.user.services.niriusd = {
          Unit = {
            Description = "Nirius daemon for niri scratchpad functionality";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.nirius}/bin/niriusd";
            Restart = "on-failure";
            RestartSec = 3;
          };
        };
      };
    };
}
