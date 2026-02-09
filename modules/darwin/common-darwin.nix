{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib;
with types;
let
  cfg = config.services.commonDarwin;
in
{
  options = {
    services.commonDarwin = {
      enable = mkEnableOption "Common Darwin configuration";
    };
  };

  config = mkIf cfg.enable {
    users.users."${flake.config.me.username}" = {
      name = flake.config.me.username;
      home = flake.config.me.homeDirectory pkgs.stdenv;
      shell = pkgs.zsh;
    };

    programs = {
      zsh.enable = true;
    };

    environment.systemPackages = with pkgs; [
      terminal-notifier
      kitty

      yabai
      skhd
    ];

    services = {
      yabai = {
        enable = true;
        package = pkgs.yabai;
        enableScriptingAddition = true;
        config = {
          mouse_follows_focus = "off";
          focus_follows_mouse = "off";
          window_opacity = "off";
          window_origin_display = "default";
          window_placement = "second_child";
          window_zoom_persist = "off";
          window_shadow = "float";
          window_animation_duration = 0;
          insert_feedback_color = "0xaad75f5f";
          split_ratio = 0.50;
          split_type = "auto";
          auto_balance = "off";
          top_padding = 0;
          bottom_padding = 0;
          left_padding = 0;
          right_padding = 0;
          window_gap = 10;
          layout = "bsp";
          mouse_modifier = "fn";
          mouse_action1 = "move";
          mouse_action2 = "resize";
          mouse_drop_action = "swap";
        };
      };
      skhd = {
        enable = true;
        skhdConfig = ''
          # Navigation
          alt - h : yabai -m window --focus west
          alt - j : yabai -m window --focus south
          alt - k : yabai -m window --focus north
          alt - l : yabai -m window --focus east

          # Moving windows
          ctrl + alt - h : yabai -m window --warp west
          ctrl + alt - j : yabai -m window --warp south
          ctrl + alt - k : yabai -m window --warp north
          ctrl + alt - l : yabai -m window --warp east

          # Resize windows
          shift + ctrl + alt - h : yabai -m window --resize left:-50:0
          shift + ctrl + alt - j : yabai -m window --resize bottom:0:50
          shift + ctrl + alt - k : yabai -m window --resize top:0:-50
          shift + ctrl + alt - l : yabai -m window --resize right:50:0

          # Equalize size of windows
          ctrl + alt - e : yabai -m space --balance

          # Rotate windows clockwise and anticlockwise
          alt - r : yabai -m space --rotate 270
          shift + alt - r : yabai -m space --rotate 90

          # Rotate on X and Y Axis
          shift + alt - x : yabai -m space --mirror x-axis
          shift + alt - y : yabai -m space --mirror y-axis

          # Set insertion point for focused container
          shift + lctrl + alt - h : yabai -m window --insert west
          shift + lctrl + alt - j : yabai -m window --insert south
          shift + lctrl + alt - k : yabai -m window --insert north
          shift + lctrl + alt - l : yabai -m window --insert east

          # Float / Unfloat window
          shift + alt - space : \
              yabai -m window --toggle float
          #yabai -m window --toggle border

          # Restart Yabai
          shift + lctrl + alt - r : \
              /usr/bin/env osascript <<< \
              "display notification \"Restarting Yabai\" with title \"Yabai\""

          # Make window native fullscreen
          alt - f : yabai -m window --toggle zoom-fullscreen
          shift + alt - f : yabai -m window --toggle native-fullscreen

          shift + lctrl + alt - p : yabai -m window --toggle sticky --toggle pip --resize abs:300:300

          # toggle sticky(+float), picture-in-picture
          shift + lctrl + alt - o : yabai -m window --toggle sticky
        '';
      };
    };

    # Add ability to used TouchID for sudo authentication
    security.pam.services.sudo_local = {
      touchIdAuth = true;
      reattach = true;
    };

    environment.shellInit = ''
      ulimit -n 524288
    '';

    launchd = {
      daemons = {
        # fixes "Too many open files" errors
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
        # Specifies the duration of a smooth frame-size change
        NSGlobalDomain.NSWindowResizeTime = 0.001;
      };

      activationScripts.extraActivation.text = ''
        /usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license
      '';
      stateVersion = 5;
    };
  };
}
