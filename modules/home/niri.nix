{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
with lib;
let
  cfg = config.wm.niri;

  # Generate monitor configuration from settings
  monitors = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: monitor: ''
      output "${name}" {
        ${if monitor.enabled then "" else "off"}
        ${lib.optionalString (monitor.mode != null) "mode \"${monitor.mode}\""}
        ${lib.optionalString (
          monitor.position != null
        ) "position x=${toString monitor.position.x}, y=${toString monitor.position.y}"}
        ${lib.optionalString (monitor.scale != null) "scale ${toString monitor.scale}"}
        ${lib.optionalString (monitor.transform != null) "transform ${monitor.transform}"}
      }
    '') cfg.monitors
  );

  # Generate keybind configuration
  # keybinds = lib.concatStringsSep "\n" (
  #   lib.mapAttrsToList (keys: action: ''
  #     binds {
  #       ${keys} { ${action}; }
  #     }
  #   '') cfg.keybinds
  # );
in
{
  options = {
    wm.niri = with types; {
      enable = mkEnableOption "niri Wayland compositor configuration";

      package = mkOption {
        type = package;
        default = pkgs.niri;
        description = "The niri package to use";
      };

      monitors = mkOption {
        type = attrsOf (submodule {
          options = {
            enabled = mkOption {
              type = bool;
              default = true;
              description = "Whether the monitor is enabled";
            };
            mode = mkOption {
              type = nullOr str;
              default = null;
              description = "Display mode (e.g., '1920x1080@60.000')";
            };
            position = mkOption {
              type = nullOr (submodule {
                options = {
                  x = mkOption { type = int; };
                  y = mkOption { type = int; };
                };
              });
              default = null;
              description = "Monitor position";
            };
            scale = mkOption {
              type = nullOr float;
              default = null;
              description = "Display scale factor";
            };
            transform = mkOption {
              type = nullOr (enum [
                "normal"
                "90"
                "180"
                "270"
                "flipped"
                "flipped-90"
                "flipped-180"
                "flipped-270"
              ]);
              default = null;
              description = "Display transformation";
            };
          };
        });
        default = { };
        description = "Monitor configurations";
      };

      keybinds = mkOption {
        type = attrsOf str;
        default = { };
        description = "Keybind definitions (keys -> action)";
      };

      input = {
        keyboard = {
          xkb = {
            layout = mkOption {
              type = str;
              default = "fr";
              description = "Keyboard layout";
            };
            variant = mkOption {
              type = nullOr str;
              default = null;
              description = "Keyboard variant";
            };
            options = mkOption {
              type = nullOr str;
              default = null;
              description = "XKB options";
            };
          };
        };

        touchpad = {
          tap = mkOption {
            type = bool;
            default = false;
            description = "Enable tap to click";
          };
          natural-scroll = mkOption {
            type = bool;
            default = true;
            description = "Enable natural scrolling";
          };
        };
      };

      layout = {
        gaps = mkOption {
          type = int;
          default = 8;
          description = "Gap size between windows";
        };
        center-focused-column = mkOption {
          type = bool;
          default = false;
          description = "Center the focused column";
        };
        default-column-width = mkOption {
          type = nullOr (
            either float (submodule {
              options = {
                proportion = mkOption { type = float; };
              };
            })
          );
          default = null;
          description = "Default column width (proportion of screen)";
        };
      };

      spawn-at-startup = mkOption {
        type = listOf str;
        default = [ ];
        description = "Commands to run at startup";
      };

      environment = mkOption {
        type = attrsOf str;
        default = { };
        description = "Environment variables to set";
      };

      extraConfig = mkOption {
        type = lines;
        default = "";
        description = "Additional niri configuration";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      cfg.package

      # Core niri utilities
      fuzzel # Application launcher

      # Screenshot tools
      grim
      slurp
      satty # Screenshot annotation

      # Clipboard
      wl-clipboard
      cliphist

      # Background and theming
      swaybg
      wpaperd

      # Additional Wayland utilities
      wlogout # Logout menu
      wlr-randr # Display configuration

      # Polkit agent
      polkit_gnome

      # KDE Connect
      pkgs.kdePackages.qttools
    ];

    # Niri configuration file
    xdg.configFile."niri/config.kdl".text =
      let
        # Input configuration
        input-config = ''
          input {
            keyboard {
              xkb {
                layout "${cfg.input.keyboard.xkb.layout}"
                ${lib.optionalString (
                  cfg.input.keyboard.xkb.variant != null
                ) "variant \"${cfg.input.keyboard.xkb.variant}\""}
                ${lib.optionalString (
                  cfg.input.keyboard.xkb.options != null
                ) "options \"${cfg.input.keyboard.xkb.options}\""}
              }
            }

            touchpad {
              //tap
              // dwt
              // dwtp
              // drag false
              // drag-lock
              // accel-profile "flat"
              // scroll-factor 0.1
              // scroll-factor vertical=1.0 horizontal=-2.0
              scroll-method "two-finger"
              // scroll-button 273
              // scroll-button-lock
              // tap-button-map "left-middle-right"
              // click-method "clickfinger"
              // left-handed
              // disabled-on-external-mouse
              // middle-emulation

              ${lib.optionalString cfg.input.touchpad.natural-scroll "natural-scroll"}
            }


            mouse {
                // off
                // natural-scroll
                // accel-speed 0.2
                accel-profile "flat"
                scroll-factor 2.0
                // scroll-factor vertical=1.0 horizontal=-2.0
                // scroll-method "no-scroll"
                // scroll-button 273
                // scroll-button-lock
                // left-handed
                // middle-emulation
            }
          }
        '';

        # Layout configuration
        layout-config = ''
          layout {
            gaps ${toString cfg.layout.gaps}
            ${lib.optionalString cfg.layout.center-focused-column "center-focused-column"}
            ${lib.optionalString (cfg.layout.default-column-width != null) (
              if lib.isAttrs cfg.layout.default-column-width then
                "default-column-width { proportion ${toString cfg.layout.default-column-width.proportion}; }"
              else
                "default-column-width ${toString cfg.layout.default-column-width}"
            )}
          }
        '';

        # Environment variables
        env-config = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: value: ''environment "${name}" "${value}"'') cfg.environment
        );

        # Startup commands
        startup-config = lib.concatStringsSep "\n" (
          map (
            cmd:
            ''spawn-at-startup "${lib.head (lib.splitString " " cmd)}" ${
              lib.concatMapStringsSep " " (x: ''"${x}"'') (lib.tail (lib.splitString " " cmd))
            }''
          ) cfg.spawn-at-startup
        );

        # Default keybinds (can be overridden/extended via cfg.keybinds)
        default-binds = ''
          binds {
            // Window management
            Mod+Space { spawn "fuzzel"; }
            Mod+Shift+E { quit; }

            // Window focus
            Mod+h { focus-column-left; }
            Mod+l { focus-column-right; }
            Mod+k { focus-window-up; }
            Mod+j { focus-window-down; }

            // Window movement
            Mod+Left { move-column-left; }
            Mod+Right { move-column-right; }
            Mod+Up { move-window-up; }
            Mod+Down { move-window-down; }

            // Window actions
            Mod+Q { close-window; }
            Mod+F { maximize-column; }
            Mod+Shift+F { fullscreen-window; }

            // Workspaces
            Mod+Ampersand { focus-workspace 1; }
            Mod+Eacute { focus-workspace 2; }
            Mod+Quotedbl { focus-workspace 3; }
            Mod+Apostrophe { focus-workspace 4; }
            Mod+Parenleft { focus-workspace 5; }
            Mod+Minus { focus-workspace 6; }
            Mod+Egrave { focus-workspace 7; }
            Mod+Underscore { focus-workspace 8; }
            Mod+Ccedilla { focus-workspace 9; }
            Mod+Agrave { focus-workspace 10; }

            Mod+Shift+Ampersand { move-column-to-workspace 1; }
            Mod+Shift+Eacute { move-column-to-workspace 2; }
            Mod+Shift+Quotedbl { move-column-to-workspace 3; }
            Mod+Shift+Apostrophe { move-column-to-workspace 4; }
            Mod+Shift+Parenleft { move-column-to-workspace 5; }
            Mod+Shift+Minus { move-column-to-workspace 6; }
            Mod+Shift+Egrave{ move-column-to-workspace 7; }
            Mod+Shift+Underscore { move-column-to-workspace 8; }
            Mod+Shift+Ccedilla { move-column-to-workspace 9; }
            Mod+Shift+Agrave { move-column-to-workspace 10; }

            // Screenshot
            Mod+Shift+S { spawn "sh" "-c" "grim -g $(slurp) - | satty -f -"; }
            Print { spawn "sh" "-c" "grim - | wl-copy"; }

            // Lock screen
            Mod+Escape { spawn "noctalia-shell" "ipc" "call" "lockScreen" "lock"; }

            // Volume control
            XF86AudioRaiseVolume { spawn "noctalia-shell" "ipc" "call" "volume" "increase"; }
            XF86AudioLowerVolume { spawn "noctalia-shell" "ipc" "call" "volume" "decrease"; }
            XF86AudioMute { spawn "noctalia-shell" "ipc" "call" "volume" "muteOutput"; }

            // Brightness control
            XF86MonBrightnessUp { spawn "noctalia-shell" "ipc" "call" "brightness" "increase"; }
            XF86MonBrightnessDown { spawn "noctalia-shell" "ipc" "call" "brightness" "decrease"; }
          }
        '';

        # Custom keybinds
        custom-binds = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (keys: action: "binds { ${keys} { ${action}; } }") cfg.keybinds
        );
        animations = ''
          animations {
            // Uncomment to turn off all animations.
            // You can also put "off" into each individual animation to disable it.
            // off

            // Slow down all animations by this factor. Values below 1 speed them up instead.
            slowdown 0.5
          }'';

        workspaces = ''
          workspace "browser"
          workspace "terminal"
          workspace "social"
          workspace "fizzy"
          workspace "misc"
          workspace "music"
          workspace "zotero"
          workspace "misc2"
          workspace "misc3"

          window-rule {
              match at-startup=true app-id=r#"^kitty$"#
              open-on-workspace "terminal"
              open-maximized true
          }

          window-rule {
              match app-id=r#"^brave-browser$"#
              open-on-workspace "browser"
              open-maximized true
              scroll-factor 0.1
          }

          window-rule {
              match title=r#".*Fizzy$"#
              open-on-workspace "fizzy"
              open-maximized true
              scroll-factor 0.1
          }

          window-rule {
              match app-id=r#"^org.pwmt.zathura$"#
              scroll-factor 0.3
          }

          window-rule {
              match app-id=r#"^org.strawberrymusicplayer.strawberry$"#
              open-on-workspace "music"
              open-maximized true
          }
        '';
      in
      ''
        // Niri configuration
        // Auto-generated by Home Manager

        ${input-config}

        ${layout-config}

        ${monitors}

        ${env-config}

        ${startup-config}

        ${default-binds}

        ${custom-binds}

        ${animations}

        ${workspaces}

        ${cfg.extraConfig}
      '';

    # Fuzzel launcher configuration
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
          radius = 8;
        };
      };
    };

    services.kdeconnect.enable = true;

    # Default spawn-at-startup if not specified
    # Note: Noctalia provides its own bar and notification system
    wm.niri.spawn-at-startup = mkDefault [
      "noctalia-shell"
      # "swaybg"
      # "-m"
      # "fill"
      # "-c"
      # "#1e1e2e"
      # "wl-paste"
      # "--type"
      # "text"
      # "--watch"
      # "cliphist"
      # "store"
      # "wl-paste"
      # "--type"
      # "image"
      # "--watch"
      # "cliphist"
      # "store"
    ];

    programs.noctalia-shell = {
      enable = true;
      settings = {
        # configure noctalia here
        bar = {
          density = "default";
          barType = "simple";
          position = "bottom";
          showCapsule = true;
          widgets = {
            left = [
              {
                id = "ControlCenter";
                useDistroLogo = true;
              }
              {
                id = "Launcher";
              }
              {
                id = "plugin:mini-docker";
              }
              {
                id = "plugin:tailscale";
              }
              {
                id = "SystemMonitor";
                compactMode = true;
                showCpuUsage = false;
                showCpuTemp = false;
                showNetworkStats = true;
                showDiskUsage = true;
              }
              # {
              #   id = "ActiveWindow";
              # }
              {
                id = "plugin:catwalk";
              }
            ];
            center = [
              {
                id = "Workspace";
                showApplications = true;
                iconScale = 1.0;
              }
            ];
            right = [
              {
                id = "MediaMini";
              }
              {
                id = "Tray";
              }
              {
                id = "Battery";
                alwaysShowPercentage = true;
                warningThreshold = 50;
              }
              {
                id = "Volume";
              }
              {
                id = "Brightness";
              }
              {
                id = "plugin:kde-connect";
              }
              {
                formatHorizontal = "HH:mm";
                formatVertical = "HH mm";
                id = "Clock";
                useMonospacedFont = true;
                usePrimaryColor = true;
              }
              {
                id = "NotificationHistory";
              }

            ];
          };
        };
        colorSchemes.predefinedScheme = "Catppucin";
        general = {
          avatarImage = "/home/${flake.config.me.username}/.face";
          showChangelogOnStartup = false;
        };
        location = {
          monthBeforeDay = false;
          name = "Rennes, France";
        };
        brightness = {
          brightnessStep = 5;
          enforceMinimum = true;
          enableDdcSupport = true;
          backlightDeviceMappings = [
            {
              output = "eDP-1";
              device = "/sys/class/backlight/apple-panel-bl";
            }
          ];
        };
        osd.location = "bottom_center";
        notifications.location = "bottom_center";
      };
      # this may also be a string or a path to a JSON file.

      plugins = {
        sources = [
          {
            enabled = true;
            name = "Official Noctalia Plugins";
            url = "https://github.com/noctalia-dev/noctalia-plugins";
          }
        ];
        states =
          let
            sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
          in
          {
            catwalk = {
              enabled = true;
              inherit sourceUrl;
            };
            kde-connect = {
              enabled = true;
              inherit sourceUrl;
            };
            tailscale = {
              enabled = true;
              inherit sourceUrl;
            };
            mini-docker = {
              enabled = true;
              inherit sourceUrl;
            };
          };
        version = 2;
      };
      # this may also be a string or a path to a JSON file.

      pluginSettings = {
        catwalk = {
          minimumThreshold = 25;
          hideBackground = true;
        };
        tailscale = {
          showIpAddress = false;
          terminalCommand = "kitty";
        };
        # this may also be a string or a path to a JSON file.
      };
    };
  };
}
