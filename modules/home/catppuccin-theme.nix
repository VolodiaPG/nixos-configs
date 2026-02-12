{
  lib,
  config,
  pkgs,
  ...
}:
let
  # Determine the default flavor based on system theme
  # Users can override this by setting catppuccin.flavor directly
  defaultFlavor = "mocha"; # Dark theme default
  defaultLightFlavor = "latte"; # Light theme default
  cfg = config.catppuccin;
in
{
  options.catppuccin = {
    autoThemeSwitch = lib.mkEnableOption "automatic theme switching based on system theme";

    lightFlavor = lib.mkOption {
      type = lib.types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = defaultLightFlavor;
      description = "Catppuccin flavor to use for light mode";
    };

    darkFlavor = lib.mkOption {
      type = lib.types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = defaultFlavor;
      description = "Catppuccin flavor to use for dark mode";
    };
  };

  config = lib.mkIf cfg.autoThemeSwitch {
    # Set the default catppuccin flavor globally
    catppuccin = {
      flavor = lib.mkDefault config.catppuccin.darkFlavor;
      lazygit.enable = lib.mkDefault false;
    };

    xdg.configFile = {
      "lazygit/theme.dark.yml".source =
        "${config.catppuccin.sources.lazygit}/mocha/${config.catppuccin.accent}.yml";

      "lazygit/theme.light.yml".source =
        "${config.catppuccin.sources.lazygit}/latte/${config.catppuccin.accent}.yml";
    };

    home = {
      activation.lazygit-theme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [[ ! -f "${config.xdg.configHome}/lazygit/theme.yml" ]]; then
          ln -s "${config.xdg.configHome}/lazygit/theme.dark.yml" "${config.xdg.configHome}/lazygit/theme.yml"
        fi
      '';

      sessionVariables =
        let
          configDirectory = config.xdg.configHome;
          configFiles = [
            "${configDirectory}/lazygit/config.yml"
            "${configDirectory}/lazygit/theme.yml"
          ];
        in
        {
          # Ensure that the default config file is still sourced
          LG_CONFIG_FILE = lib.concatStringsSep "," configFiles;
        };

      packages = [
        pkgs.tmux-session-color
        pkgs.openrouter-credits
      ];
    };

    catppuccin.tmux.extraConfig = ''
      if-shell -b '[ "$(uname -a | grep Linux)" ]' {
        set -g @catppuccin_load_text "#[fg=#{@thm_overlay_0}] #(cat /proc/loadavg | cut -d' ' -f1-3)"
      } {
        if-shell -b '[ "$(uname -a | grep Darwin)" ]' {
          set -g @catppuccin_load_text "#[fg=#{@thm_overlay_0}] #(sysctl -q -n vm.loadavg | cut -d\" \" -f2-4)"
        } {
          set -g @catppuccin_load_text ""
        }
      }

      set -g @catppuccin_date_time_text "#[fg=#{@thm_subtext_0}]%H:%M"
      set -g @catppuccin_date_time_icon ""
      set -g @catppuccin_load_icon ""
      set -g @catppuccin_load_background "none"

      set -g status-left ""
      set -g status-right ""

      set -g @catppuccin_status_left_separator ""
      set -g @catppuccin_status_middle_separator ""
      set -g @catppuccin_status_right_separator "█"
      set -g @catppuccin_status_connect_separator "yes"
      set -g @catppuccin_status_module_bg_color "#{@thm_mantle}"

      set -g @catppuccin_window_current_number_color "#(tmux-session-color $(hostname))"

      set -ag status-right " #[fg=#{@thm_overlay_0}]#{?#(echo $(( #{client_width} < 120 ))),,#(openrouter-credits)}"
      set -ag status-right " #{?#(echo $(( #{client_width} < 120 ))),,#{E:@catppuccin_status_load}}"
      set -ag status-right " #{?#(echo $(( #{client_width} <  80 ))),,#{E:@catppuccin_status_date_time}}"
      set -ag status-right " #[fg=#{@thm_crust},bg=#(tmux-session-color #S)] #S "

      # Ensure that everything on the right side of the status line
      # is included.
      set -g status-right-length 400
    '';
  };
}
