{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  date_script = pkgs.writeShellScriptBin "date_since_last_nixpkgs" ''
    # Function to print colored text
    # $1: Color code
    # $2: Message
    print_colored() {
        echo -e "\033[''${1}m''${2}\033[0m"
    }

    # Get the full version string from nixos-version
    version_string=$(nixos-version)
    if [ $? -ne 0 ]; then
      exit 0
    fi

    # Extract the date part (assuming it's in the format YYYYMMDD as in "20.09.20201022.abcdefg")
    version_date=$(echo $version_string | grep -oP '\d{8}')

    # Convert the extracted date to a more standard format (YYYY-MM-DD)
    formatted_version_date=$(echo "''${version_date:0:4}-''${version_date:4:2}-''${version_date:6:2}")

    # Get the current date in the same format
    current_date=$(date '+%Y-%m-%d')

    # Calculate the difference in days using date command
    diff_days=$(echo $(( ($(date --date=$current_date +%s) - $(date --date=$formatted_version_date +%s) )/(60*60*24) )))

    # Color codes
    yellow='33'
    yellow_bold='1;33'
    orange='1;38;5;208'
    red='1;31;5'

    case $diff_days in
        0)
            echo "(today's version)"
            ;;
        1)
            echo "(yesterday's version)"
            ;;
        2)
            print_colored $yellow "(version last updated $diff_days days ago)"
            ;;
        3)
            print_colored $orange "(version last updated $diff_days days ago)"
            ;;
        4)
            print_colored $orange "(version last updated $diff_days days ago)"
            ;;
        *)
            print_colored $red "(version last updated $diff_days days ago)"
            ;;
    esac
  '';
  isClean = inputs.self ? rev;
  status = if isClean then "" else ''"dirty" '';
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
        "match_prev_cmd"
      ];
    };
    syntaxHighlighting.enable = false;
    initContent = ''
      export LC_ALL="C.UTF-8"

      # History settings
      HISTSIZE=10000
      SAVEHIST=2000000
      HISTFILE=~/.zsh_history
      setopt appendhistory
      setopt hist_ignore_all_dups
      setopt hist_ignore_space
      setopt hist_reduce_blanks
      setopt share_history

      # Ignore commands
      HISTORY_IGNORE="(ls|ll|ls -alh|pwd|clear|c|history|htop)"

      SHELL=${lib.getExe pkgs.zsh}
      TERM=screen-256color

      source ${pkgs.just}/share/zsh/site-functions/_just

      if (which nixos-version > /dev/null); then
       echo $"Running ${status}Nixos $(nixos-version) $(${lib.getExe date_script})"
      else
        echo "Running ${status}Nix"
      fi

      if [ -f ${config.age.secrets.envvars.path} ]; then
        source ${config.age.secrets.envvars.path}
      fi

      # create a zkbd compatible hash;
      # to add other keys to this hash, see: man 5 terminfo
      typeset -g -A key

      key[Home]=''${terminfo[khome]}
      key[End]=''${terminfo[kend]}
      key[Insert]=''${terminfo[kich1]}
      key[Backspace]=''${terminfo[kbs]}
      key[Delete]=''${terminfo[kdch1]}
      key[Up]=''${terminfo[kcuu1]}
      key[Down]=''${terminfo[kcud1]}
      key[Left]=''${terminfo[kcub1]}
      key[Right]=''${terminfo[kcuf1]}
      key[PageUp]=''${terminfo[kpp]}
      key[PageDown]=''${terminfo[knp]}
      key[Shift-Tab]=''${terminfo[kcbt]}

      # setup key accordingly
      [[ -n "''${key[Home]}"      ]] && bindkey -- "''${key[Home]}"       beginning-of-line
      [[ -n "''${key[End]}"       ]] && bindkey -- "''${key[End]}"        end-of-line
      [[ -n "''${key[Insert]}"    ]] && bindkey -- "''${key[Insert]}"     overwrite-mode
      [[ -n "''${key[Backspace]}" ]] && bindkey -- "''${key[Backspace]}"  backward-delete-char
      [[ -n "''${key[Delete]}"    ]] && bindkey -- "''${key[Delete]}"     delete-char
      [[ -n "''${key[Up]}"        ]] && bindkey -- "''${key[Up]}"         up-line-or-history
      [[ -n "''${key[Down]}"      ]] && bindkey -- "''${key[Down]}"       down-line-or-history
      [[ -n "''${key[Left]}"      ]] && bindkey -- "''${key[Left]}"       backward-char
      [[ -n "''${key[Right]}"     ]] && bindkey -- "''${key[Right]}"      forward-char
      [[ -n "''${key[PageUp]}"    ]] && bindkey -- "''${key[PageUp]}"     beginning-of-buffer-or-history
      [[ -n "''${key[PageDown]}"  ]] && bindkey -- "''${key[PageDown]}"   end-of-buffer-or-history
      [[ -n "''${key[Shift-Tab]}" ]] && bindkey -- "''${key[Shift-Tab]}"  reverse-menu-complete

      # Finally, make sure the terminal is in application mode, when zle is
      # active. Only then are the values from $terminfo valid.
      if (( ''${+terminfo[smkx]} && ''${+terminfo[rmkx]} )); then
      	autoload -Uz add-zle-hook-widget
      	function zle_application_mode_start { echoti smkx }
      	function zle_application_mode_stop { echoti rmkx }
      	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
      	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
      fi

      # ZLE search
      autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search

      [[ -n "''${key[Up]}"   ]] && bindkey -- "''${key[Up]}"   up-line-or-beginning-search
      [[ -n "''${key[Down]}" ]] && bindkey -- "''${key[Down]}" down-line-or-beginning-search

      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word

      # If in tmux, rename the session to the current git project, if any, and if no session name is set
      if [ -n "$TMUX" ]; then
        function refresh_tmux_session_name() {
          local current_session=$(tmux display-message -p '#S')
          local current_dir=$(basename "$PWD")

          if [ ! "$current_session" = "$current_dir" ]; then
            if git rev-parse --git-dir > /dev/null 2>&1; then
              tmux rename-session $(basename $(git rev-parse --show-toplevel))
            else
              tmux rename-session "$current_dir"
            fi
          fi
        }
        chpwd() {
          refresh_tmux_session_name
        }
        refresh_tmux_session_name
      fi
    '';
    shellAliases = {
      ll = "ls -l";
      j = "just";
      jl = "just --list";
      g = "git";
      c = "clear";
      n = "nvim";
    };
    plugins = [
      {
        name = "auto-suggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
        file = "share/zsh-completions/zsh-completions.zsh";
      }
      {
        name = "nix-zsh-completions";
        src = pkgs.nix-zsh-completions;
        file = "share/nix-zsh-completions/nix-zsh-completions.zsh";
      }
    ];
  };
}
