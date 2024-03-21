{
  lib,
  pkgs,
  graphical,
  apps,
  config,
  homeDirectory,
  inputs,
  username,
  ...
}: let
  isClean = inputs.self ? rev;
  date_script = pkgs.writeShellScriptBin "date_since_last_nixpkgs" ''
    # Function to print colored text
    # $1: Color code
    # $2: Message
    print_colored() {
        echo -e "\033[''${1}m''${2}\033[0m"
    }

    # Get the full version string from nixos-version
    version_string=$(nixos-version)

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
    orange='1;38;5;208' # There's no standard orange in ANSI, this is a close approximation
    red='1;31;5'

    case $diff_days in
        0)
            echo "(today's version)"
            ;;
        1)
            echo "(yesterday's version)"
            ;;
        2)
            print_colored $yellow_bold "(version last updated $diff_days days ago)"
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
  status =
    if isClean
    then ''''
    else ''printf "(dirty)"'';
  status_style =
    if isClean
    then ""
    else "bright-red bold";
in {
  imports =
    lib.optional (graphical == "gnome") ./gnome.nix
    ++ lib.optional (apps != "no-apps") ./packages;

  fonts.fontconfig.enable = true;

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
    nix-index = {
      enable = true;
      enableBashIntegration = true;
    };
    # Shell
    bash = {
      enable = true;
      historyControl = ["ignoredups" "ignorespace"];

      initExtra = ''
        # Perform file completion in a case insensitive fashion
        bind "set completion-ignore-case on"

        # Treat hyphens and underscores as equivalent
        bind "set completion-map-case on"

        # Display matches for ambiguous patterns at first tab press
        bind "set show-all-if-ambiguous on"

        # Enable incremental history search with up/down arrows (also Readline goodness)
        # Learn more about this here: http://codeinthehole.com/writing/the-most-important-command-line-tip-incremental-history-searching-with-inputrc/
        bind '"\e[A": history-search-backward'
        bind '"\e[B": history-search-forward'
        bind '"\e[C": forward-char'
        bind '"\e[D": backward-char'
        bind '"\e\e[D": backward-word'
        bind '"\e\e[C": forward-word'

        # Attempt to add completions for _all_ aliases
        source ${pkgs.complete-alias}/bin/complete_alias
        complete -F _complete_alias "''${!BASH_ALIASES[@]}"
      '';

      bashrcExtra = ''
        # # Fix local warning with bash and perl
        # export LOCALE_ARCHIVE="$(nix profile list | grep glibcLocales | tail -n1 | cut -d ' ' -f4)/lib/locale/locale-archive"

        if [[ -a ~/.localrc ]]
        then
          source "$HOME/.localrc"
        fi

        # This helps bash-completion work, since bash-completion will look here for
        # other installed completions. Other packages that include bash completion
        # scripts will link them here.
        export XDG_DATA_DIRS="$HOME/.nix-profile/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

        # Make Nix and home-manager installed things available in PATH.
        # export PATH=/run/current-system/sw/bin/:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/opt/homebrew/bin:$PATH
        export PATH=$HOME/.nix-profile/bin:/opt/homebrew/bin:$PATH
        export GPG_TTY="$(tty)"
        EDITOR=nano

        echo "Running Nixos $(nixos-version) $(${lib.getExe date_script})"
      '';
    };
    # Status bar in the shell and stuff
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        format = "$shlvl$shell$username$hostname$\{custom.update_status}$nix_shell$\{custom.direnv}$git_branch$git_commit$git_state$git_status$directory$jobs$cmd_duration\n$character";
        shlvl = {
          disabled = true;
          symbol = "󰓠";
          style = "bright-red bold";
        };
        shell = {
          disabled = false;
          format = "$indicator";
          fish_indicator = "";
          bash_indicator = "[](bright-white) ";
          zsh_indicator = "[ZSH](bright-white) ";
        };
        username = {
          format = "[$user]($style)\@";
          style_user = "bright-white bold";
          style_root = "bright-red bold";
        };
        hostname = {
          format = "[$hostname]($style) ";
          style = status_style;
          ssh_only = false;
        };
        nix_shell = {
          symbol = "󱄅";
          format = "[$symbol]($style) ";
          style = "bright-purple bold";
        };
        git_branch = {
          only_attached = true;
          format = "[$symbol $branch]($style) ";
          symbol = "";
          style = "bright-yellow bold";
        };
        git_commit = {
          only_detached = true;
          format = "[ $hash]($style) ";
          style = "bright-yellow bold";
        };
        git_state = {
          style = "bright-purple bold";
        };
        git_status = {
          style = "bright-green";
          conflicted = "[](orange bold)";
          deleted = "[-](red bold)";
          modified = "[](green bold)";
          stashed = "[󰛄](bright-grey bold)";
          staged = "[](green bold)";
          renamed = "[](purple bold)";
          untracked = "[?](yellow bold)";
        };
        directory = {
          read_only = " ";
          truncation_length = 0;
        };
        cmd_duration = {
          format = "[$duration]($style) ";
          style = "bright-blue";
        };
        jobs = {
          style = "bright-green bold";
        };
        character = {
          success_symbol = "[](bright-green bold)";
          error_symbol = "[](bright-red bold)";
        };
        custom = {
          direnv = {
            format = "[\\[direnv\\]]($style) ";
            style = "fg:yellow dimmed";
            when = "env | grep -E '^DIRENV_FILE='";
          };
          update_status = {
            format = "[$output]($style) in ";
            command = "${status}";
            style = status_style;
            when = "true";
          };
        };
      };
    };
    dircolors = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      settings = {
        ".iso" = "01;31"; # .iso files bold red like .zip and other archives
        ".gpg" = "01;33"; # .gpg files bold yellow
        # Images to non-bold magenta instead of bold magenta like videos
        ".bmp" = "00;35";
        ".gif" = "00;35";
        ".jpeg" = "00;35";
        ".jpg" = "00;35";
        ".mjpeg" = "00;35";
        ".mjpg" = "00;35";
        ".mng" = "00;35";
        ".pbm" = "00;35";
        ".pcx" = "00;35";
        ".pgm" = "00;35";
        ".png" = "00;35";
        ".ppm" = "00;35";
        ".svg" = "00;35";
        ".svgz" = "00;35";
        ".tga" = "00;35";
        ".tif" = "00;35";
        ".tiff" = "00;35";
        ".webp" = "00;35";
        ".xbm" = "00;35";
        ".xpm" = "00;35";
      };
    };
    zoxide = {
      enable = true;
      # enableFishIntegration = true;
      enableBashIntegration = true;
    };
    zsh = {
      enable = true;
      initExtra = ''
        # Make Nix and home-manager installed things available in PATH.
        export PATH=/run/current-system/sw/bin/:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:$PATH
        ${pkgs.bashInteractive}/bin/bash
        exit $?
      '';
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      stdlib = ''
        export DIRENV_LOG_FORMAT=""
      '';
    };
    git = {
      enable = true;
      userName = "Volodia P.-G.";
      userEmail = "volodia.parol-guarino@proton.me";
      signing = {
        key = "B566FD4E11A22B543B82520B72063CC9DB438B82";
        signByDefault = true;
      };
      extraConfig = {
        rebase.autostash = true;
        init.defaultBranch = "main";
        core.editor = "nano";
      };
      aliases.lg = "log --color --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };

  services.gpg-agent = {
    enable = pkgs.stdenv.isLinux;
    grabKeyboardAndMouse = false;
    pinentryPackage = pkgs.pinentry-tty;
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.

  systemd.user.services.UseSecrets = let
    script = pkgs.writeShellScript "sops-nix-user" ''
      echo ${config.sops.secrets.pythong5k.path}
    '';
  in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "test";
      };
      Service = {
        ExecStart = script;
        Type = "oneshot";
        RemainAfterExit = true;
      };
      Install.WantedBy = ["default.target"];
    };

  #   launchd.agents.sops-nix = {
  #     enable = true;
  #     config = {
  #       ProgramArguments = [ script ];
  #       KeepAlive = {
  #         Crashed = false;
  #         SuccessfulExit = false;
  #       };
  #       ProcessType = "Background";
  #       StandardOutPath = "${config.home.homeDirectory}/Library/Logs/SopsNix/stdout";
  #       StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/SopsNix/stderr";
  #     };
  #   };
  # };

  home = {
    inherit homeDirectory username;
    # activation = {
    #   pythong5k = lib.hm.dag.entryAfter ["writeBoundary"] ''
    #     cat ${config.sops.secrets.pythong5k.path} > ${homeDirectory}/.python-grid5000.yaml
    #   '';
    # };
    shellAliases = {
      cd = "z";
      ll = "ls -l";
      l = "ls";
      g = "git";
      j = "just";
    };
    packages = with pkgs; [
      fontconfig
      (nerdfonts.override {fonts = ["FiraCode"];})
    ];

    file = {
      ".config/discord/settings.json".text = ''
        {
          "BACKGROUND_COLOR": "#202225",
          "IS_MAXIMIZED": false,
          "IS_MINIMIZED": true,
          "SKIP_HOST_UPDATE": true,
          "WINDOW_BOUNDS": {
            "x": 307,
            "y": 127,
            "width": 1280,
            "height": 725
          }
        }
      '';

      ".ssh/config".source = pkgs.substituteAll {
        src = ./config.ssh;
        # g5k_login = builtins.readFile ../../secrets/grid5000.user;
        g5k_login = "volparolguarino";
        keychain =
          if pkgs.stdenv.isLinux
          then ""
          else "UseKeychain yes";
      };
      ".ssh/authorized_keys".text = ''
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpDmkY5OctLdxrPUcnRafndhDvvgw/GNYvgo4I9LrPJ341vGzwgqSi90YRvn725DkYHmEi1bN7i3W2x1AQbuvEBzxMG3BlwtEGtz+/5rIMY+5LRzB4ppN+Ju/ySbPKSD2XpVgVOCegc7ZtZ4XpAevVsi/kyg35RPNGmljEyuN1wIxBVARZXZezsGf1MHzxEqiNogeAEncPCk/P44B6xBRt9qSxshIT/23Cq3M/CpFyvbI0vtdLaVFIPox6ACwlmTgdReC7p05EefKEXaxVe61yhBquzRwLZWf6Y8VESLFFPZ+lEF0Shffk15k97zJICVUmNPF0Wfx1Fn5tQyDeGe2nA5d2aAxHqvl2mJk/fccljzi5K6j6nWNf16pcjWjPqCCOTs8oTo1f7gVXQFCzslPnuPIVUbJItE3Ui+mSTv9KF/Q9oH02FF40mSuKtq5WmntV0kACfokRJLZ6slLabo0LgVzGoixdiGwsuJbWAsNNHURoi3lYb8fMOxZ/2o4GZik= volodia@volodia-msi
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT volodia.parol-guarino@proton.me
      '';

      ".tmux".text = ''
        set -g mouse
        setw -g mouse on

        bind C-c run "tmux save-buffer - | wl-copy"

        bind C-v run "tmux set-buffer "$(wl-paste)"; tmux paste-buffer"
      '';
      ".config/mpv/scripts" = {
        source = ./packages/scripts;
        recursive = true;
      };
      ".yabairc".source = ./packages/.yabairc;
      ".skhdrc".source = ./packages/.skhdrc;
    };

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "22.05";
  };
}
