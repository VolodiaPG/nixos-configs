{ config, lib, ... }:
with lib;

let
  colors = {
    bg = "#0a0e1a";
    bg-alt = "#0f1419";
    fg = "#e6e1cf";
    primary = "#00d4ff";
    secondary = "#ff0080";
    accent = "#39ff14";
    warning = "#ff6600";
    error = "#ff0040";
    surface = "#1a1f2e";
  };
  cfg = config.programs.zathura;
in
{
  config = mkIf cfg.enable {
    programs.zathura = {
      options = {
        # Colors
        default-bg = colors.bg;
        default-fg = colors.fg;
        statusbar-bg = colors.surface;
        statusbar-fg = colors.fg;
        inputbar-bg = colors.surface;
        inputbar-fg = colors.fg;
        notification-bg = colors.surface;
        notification-fg = colors.fg;
        notification-error-bg = colors.error;
        notification-error-fg = colors.bg;
        notification-warning-bg = colors.warning;
        notification-warning-fg = colors.bg;
        highlight-color = colors.accent;
        highlight-active-color = colors.primary;
        completion-bg = colors.surface;
        completion-fg = colors.fg;
        completion-highlight-bg = colors.primary;
        completion-highlight-fg = colors.bg;
        recolor-lightcolor = colors.bg;
        recolor-darkcolor = colors.fg;

        # Settings
        recolor = true;
        recolor-keephue = true;
        selection-clipboard = "clipboard";
        smooth-scroll = true;
        zoom-min = 10;
        zoom-max = 1000;
        zoom-step = 20;
        page-padding = 5;
        statusbar-basename = true;
        statusbar-home-tilde = true;
        window-title-home-tilde = true;
        window-title-basename = true;
        adjust-open = "best-fit";
        scroll-page-aware = true;
      };

      mappings = {
        # Navigation
        "J" = "scroll half-down";
        "K" = "scroll half-up";
        "H" = "scroll half-left";
        "L" = "scroll half-right";

        # Zoom
        "+" = "zoom in";
        "-" = "zoom out";
        "=" = "zoom in";

        # Page navigation
        "gg" = "goto top";
        "G" = "goto bottom";

        # Search
        "/" = "search forward";
        "!" = "search forward";
        "?" = "search backward";
        "n" = "search next";
        "N" = "search previous";

        # Modes
        "r" = "recolor";
        "R" = "reload";
        "f" = "toggle_fullscreen";
        "s" = "toggle_statusbar";

        # Quit
        "q" = "quit";
      };
    };
  };
}
