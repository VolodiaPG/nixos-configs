{ config, lib, ... }:
with lib;

let
  colors = {
    bg = "#0a0e1a";
    bg-alt = "#0f1419";
    fg = "#e6e1cf";
    primary = "#00d4ff80";
    secondary = "#ff008080";
    accent = "#39ff1480";
    warning = "#ff660080";
    error = "#ff004080";
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

        # --- Performance ---
        render-loading = true;
        render-loading-bg = colors.bg;
        render-loading-fg = colors.fg;
        page-cache-size = 50; # Cache more pages for faster navigation
        pages-per-row = 1;
        scroll-page-aware = true;
        scroll-full-overlap = "0.01";
        scroll-step = 100;

        # --- UI & Appearance ---
        statusbar-home-tilde = true;
        window-title-home-tilde = true;
        window-title-basename = true;
        guioptions = "shv"; # Show statusbar, horizontal/vertical scrollbars

        # --- Search ---
        incremental-search = true;
        nohlsearch = false; # Keep search highlights visible

        # --- Clipboard ---
        selection-clipboard = "clipboard"; # Use system clipboard for selections
        selection-notification = true;

        # --- Zoom ---
        zoom-min = 10;
        zoom-max = 1000;
        zoom-step = 20;
        adjust-open = "best-fit";

        # Settings
        recolor = true;
        recolor-keephue = true;
        smooth-scroll = true;
        page-padding = 5;
        statusbar-basename = true;

        synctex = true;
      };

      mappings = {
        # Navigation
        "[normal] J" = "scroll half-down";
        "[normal] K" = "scroll half-up";
        "[normal] H" = "scroll half-left";
        "[normal] L" = "scroll half-right";

        # Zoom
        "[normal] +" = "zoom in";
        "[normal] -" = "zoom out";
        "[normal] =" = "zoom in";

        # Page navigation
        "[normal] gg" = "goto top";
        "[normal] G" = "goto bottom";

        # Search
        "[normal] n" = "search forward";
        "[normal] N" = "search backward";

        # Modes
        "[normal] r" = "recolor";
        "[normal] R" = "reload";
        "[normal] f" = "toggle_fullscreen";
        "[normal] s" = "toggle_statusbar";

        # Quit
        "[normal] q" = "quit";

        # Index (table of contents)
        "[normal] <Tab>" = "toggle_index";
      };
      extraConfig = ''
        # Additional settings
        set database sqlite
        set sandbox normal
        set page-padding 2
        set show-recent 20
        set first-page-column 1
      '';
    };
  };
}
