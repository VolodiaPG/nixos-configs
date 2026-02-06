{
  flake,
  lib,
  config,
  ...
}:
with lib;
let
  inherit (flake.config) me;
  cfg = config.programs.kitty;
in
{
  config = mkIf cfg.enable {
    programs.kitty = {
      font = {
        name = "Comic Code Ligatures";
        size = 14;
      };

      settings = {
        # Cursor customization
        cursor_blink_interval = 0;
        cursor_trail = 3;
        cursor_trail_decay = "0.1 0.4";
        cursor_shape = "block";

        # Scrollback
        scrollback_lines = 2000;

        # Mouse
        mouse_hide_wait = "-3.0";

        # Window layout
        enabled_layouts = "*";
        window_border_width = 1;
        window_margin_width = 0;
        window_padding_width = 0;
        inactive_text_alpha = "0.6";

        # Tab bar
        tab_bar_margin_width = 4;
        tab_bar_style = "fade";
        tab_fade = "1 1 1";

        # # Background opacity and blur
        # background_opacity = "0.8";
        # background_blur = 64;
        # dynamic_background_opacity = true;

        # Shell
        shell = "/etc/profiles/per-user/${me.username}/bin/zsh";
        editor = "nvim";

        # macOS specific
        macos_hide_titlebar = true;
        hide_window_decorations = true;
        confirm_os_window_close = 0;

        # Allow control from socket
        allow_remote_control = true;
        listen_on = "unix:/tmp/kitty";
      };

      keybindings = {
        # Scrolling
        "kitty_mod+b" = "scroll_page_up";
        "kitty_mod+f" = "scroll_page_down";

        # Window management
        "kitty_mod+enter" = "new_window_with_cwd";
        "kitty_mod+j" = "previous_window";
        "kitty_mod+k" = "next_window";
        "kitty_mod+up" = "move_window_forward";
        "kitty_mod+down" = "move_window_backward";

        # Tab management
        "kitty_mod+]" = "next_tab";
        "kitty_mod+[" = "previous_tab";
        "kitty_mod+right" = "move_tab_forward";
        "kitty_mod+left" = "move_tab_backward";
        "kitty_mod+t" = "new_tab_with_cwd";

        # Layout management
        "kitty_mod+0" = "goto_layout stack";
        "kitty_mod+9" = "goto_layout tall";
        "kitty_mod+8" = "goto_layout fat";

        # Font sizes
        "kitty_mod+equal" = "change_font_size all +2.0";
        "kitty_mod+minus" = "change_font_size all -2.0";
        "kitty_mod+backspace" = "change_font_size all 0";

        # Custom keybinding
        "ctrl+space" = "send_text all \\x10";
      };
    };
  };
}
