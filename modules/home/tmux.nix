{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.tmux;
in
{
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tmux-session-color
      pkgs.openrouter-credits
    ];

    programs.tmux = {
      baseIndex = 1;
      historyLimit = 10000;
      keyMode = "vi";
      prefix = "C-a";
      # default-terminal = "screen-256color";

      extraConfig = ''
        # Enable true color support
        set -g default-terminal "screen-256color"
        set -ga terminal-overrides ",*256col*:Tc"
        # set-option -sa terminal-overrides ",xerm-kitty:RGB"

        set-option -sg escape-time 10
        set-option -g focus-events on

        set-option -g detach-on-destroy off

        # Unbind default prefix and set to C-a
        unbind C-b
        bind C-a send-prefix

        # Set pane base index to 1
        setw -g pane-base-index 1

        # Automatically renumber windows
        set -g renumber-windows on

        # New window in current path
        bind c new-window -c "#{pane_current_path}"

        # Split windows in current path
        bind \" split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind -r v copy-mode

        # Smart pane switching with awareness of Vim splits
        # See: https://github.com/christoomey/vim-tmux-navigator
        vim_pattern='(\S+/)?g?\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?'
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
            | grep -iqE '^[^TXZ ]+ +''${vim_pattern}$'"
        bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
        bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
        bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
        bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
        tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l
      '';

      plugins = with pkgs.tmuxPlugins; [
        {
          plugin = resurrect;
          extraConfig = ''
            resurrect_dir="$HOME/.tmux/resurrect"
            set -g @resurrect-dir $resurrect_dir
            set -g @resurrect-hook-post-save-all 'target=$(readlink -f $resurrect_dir/last); sed "s| --cmd .*-vim-pack-dir||g; s|/etc/profiles/per-user/$USER/bin/||g; s|/home/$USER/.nix-profile/bin/||g" $target | sponge $target'
            set -g @resurrect-processes 'nvim htop nvtop neomutt'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
          '';
        }
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
