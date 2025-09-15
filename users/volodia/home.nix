{
  lib,
  pkgs,
  graphical,
  apps,
  symlinkPath ? null,
  config,
  homeDirectory,
  inputs,
  username,
  ...
}: let
  mkOutOfStore = path:
    if symlinkPath == null
    then ./. + "/${path}"
    else config.lib.file.mkOutOfStoreSymlink "${symlinkPath}/${path}";
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
  status =
    if isClean
    then ''''
    else ''"dirty" '';
in {
  imports =
    lib.optional (graphical == "gnome") ./gnome.nix
    ++ lib.optional (apps != "no-apps") ./packages
    ++ [./syncthing.nix];

  fonts.fontconfig.enable = true;

  catppuccin.enable = true;

  programs = {
    # Let Home Manager install and manage itself.
    lazygit = {
      enable = true;
      settings = {
        git = {
          paging = {
            externalDiffCommand = "${pkgs.difftastic}/bin/difft --color=always";
          };
        };
      };
    };
    home-manager.enable = true;
    nix-index = {
      enable = true;
    };
    zoxide = {
      enable = true;
      enableBashIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
    zsh = {
      enable = pkgs.stdenv.isDarwin;
      initContent = ''
        if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'nu' ]]
        then
            export PATH=/run/current-system/sw/bin/:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/usr/local/bin/:$PATH
            exec nu
        fi
      '';
    };
    bash = {
      enable = true;
      # for editing directly to config.nu
      initExtra = ''
        source -- ${pkgs.blesh}/share/blesh/ble.sh

        export SSH_AUTH_SOCK=/Users/volodia/.bitwarden-ssh-agent.sock
        export LC_ALL="C.UTF-8"

        # Save 5,000 lines of history in memory
        HISTSIZE=10000
        # Save 2,000,000 lines of history to disk (will have to grep ~/.bash_history for full listing)
        HISTFILESIZE=2000000
        # Append to history instead of overwrite
        shopt -s histappend
        # Ignore redundant or space commands
        HISTCONTROL=ignoreboth
        # Ignore more
        HISTIGNORE='ls:ll:ls -alh:pwd:clear:c:history:htop'
        # Set time format
        HISTTIMEFORMAT='%F %T '
        # Multiple commands on one line show up as a single line
        shopt -s cmdhist

        function __set_prompt() {
            # Check for a Git repository.
            # The 'git branch' command will be empty if not in a repo.
            local git_info
            git_info=$(git branch --show-current 2>/dev/null)
            if [[ -n "$git_info" ]]; then
                # If a branch is found, set the Git part of the prompt.
                PS1_GIT="  \e[3m$git_info\e[0m"
            else
                # Otherwise, set it to an empty string.
                PS1_GIT=""
            fi

            # Check for background jobs.
            # The `\j` prompt escape sequence expands to the number of jobs.
            # The `jobs` command returns a non-empty string if there are any jobs.
            # The original prompt had a newline for jobs.
            local jobs_count
            jobs_count=$(jobs -p | wc -l)
            if [[ "$jobs_count" -gt 0 ]]; then
                # If there are jobs, set the jobs part of the prompt with a newline.
                PS1_JOBS="(\j)"
            else
                # Otherwise, set it to an empty string.
                PS1_JOBS=""
            fi

            # Finally, set the PS1 variable using the conditional strings.
            # The \w part is the current working directory.
            # The final prompt will be on a new line and colored.
            export PS1="\033[38;5;103m\w$PS1_GIT\n$PS1_JOBS\[\e[1;38;5;38m\]\$ \[\e[0m\]"
            # newline after command
            echo
            history -a
            # history -c
            # history -r
        }

        export PROMPT_COMMAND=__set_prompt

        if (which nixos-version > /dev/null); then
         echo $"Running ${status}Nixos $(nixos-version) $(${lib.getExe date_script})"
        else
          echo "Running ${status}Nix"
        fi
      '';
      shellAliases = {
        ll = "ls -l";
        j = "just";
        jl = "just --list";
        g = "git";
        c = "clear";
      };
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
      difftastic = {
        enable = true;
        package = pkgs.difftastic;
      };
      signing = {
        format = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT";
        signByDefault = true;
      };
      extraConfig = {
        rebase.autostash = true;
        init.defaultBranch = "main";
        core.editor = "nvim";
      };
      aliases.lg = "log --color --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };

  services.gpg-agent = {
    enable = pkgs.stdenv.isLinux;
    grabKeyboardAndMouse = false;
    pinentry.package = pkgs.pinentry-tty;
    extraConfig = ''
      allow-loopback-pinentry
    '';
    enableSshSupport = true;
    enableExtraSocket = true;
    enableScDaemon = false;
  };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.

  systemd.user.services.UseSecrets = let
    script = pkgs.writeShellScript "agenix-user-test" ''
      echo "Accessing pythong5k secret path:"
      echo ${config.age.secrets.pythong5k.path}
      # Example: cat ${config.age.secrets.pythong5k.path}
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

  systemd.user.services.sshIdRsa = let
    binPath = lib.strings.makeBinPath (
      [pkgs.coreutils]
      ++ pkgs.stdenv.initialPath
    );
    script = pkgs.writeShellScript "symlinkrsa" ''
      export PATH="${binPath}"
      if [ ! -f ~/.ssh/id_rsa.pub ] || [ "$(realpath ~/.ssh/id_rsa.pub)" != "$(realpath ~/.ssh/id_ed25519.pub)" ]; then
        ln -s ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub
      fi
      if [ ! -f ~/.ssh/id_rsa ] || [ "$(realpath ~/.ssh/id_rsa)" != "$(realpath ~/.ssh/id_ed25519)" ]; then
        ln -s ~/.ssh/id_ed25519 ~/.ssh/id_rsa
      fi
    '';
  in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "symlink rsa keys";
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
    packages = with pkgs; [
      fontconfig
      tmux
      mosh
      # nerd-fonts.zed-mono
    ];

    sessionVariables = {
      EDITOR = "nvim";
    };

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
      ".config/kitty/kitty.conf".source = ./kitty.conf;
      ".ssh/config" = {
        target = ".ssh/config_source";
        onChange = ''cat ~/.ssh/config_source > ~/.ssh/config && chmod 400 ~/.ssh/config'';
        source = pkgs.replaceVars ./config.ssh {
          g5k_login = "volparolguarino";
          keychain =
            if pkgs.stdenv.isLinux
            then ""
            else "UseKeychain yes";
        };
      };
      ".ssh/authorized_keys".text = ''
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpDmkY5OctLdxrPUcnRafndhDvvgw/GNYvgo4I9LrPJ341vGzwgqSi90YRvn725DkYHmEi1bN7i3W2x1AQbuvEBzxMG3BlwtEGtz+/5rIMY+5LRzB4ppN+Ju/ySbPKSD2XpVgVOCegc7ZtZ4XpAevVsi/kyg35RPNGmljEyuN1wIxBVARZXZezsGf1MHzxEqiNogeAEncPCk/P44B6xBRt9qSxshIT/23Cq3M/CpFyvbI0vtdLaVFIPox6ACwlmTgdReC7p05EefKEXaxVe61yhBquzRwLZWf6Y8VESLFFPZ+lEF0Shffk15k97zJICVUmNPF0Wfx1Fn5tQyDeGe2nA5d2aAxHqvl2mJk/fccljzi5K6j6nWNf16pcjWjPqCCOTs8oTo1f7gVXQFCzslPnuPIVUbJItE3Ui+mSTv9KF/Q9oH02FF40mSuKtq5WmntV0kACfokRJLZ6slLabo0LgVzGoixdiGwsuJbWAsNNHURoi3lYb8fMOxZ/2o4GZik= volodia@volodia-msi
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT volodia.parol-guarino@proton.me
      '';

      ".config/mpv/scripts" = {
        source = ./packages/scripts;
        recursive = true;
      };
      ".yabairc".source =
        mkOutOfStore "packages/yabairc";
      ".skhdrc".source =
        mkOutOfStore "packages/skhdrc";
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

  xdg.configFile = {
    "starship.toml".source = lib.mkForce (
      mkOutOfStore "packages/starship.toml"
    );

    "ghostty/config".source = mkOutOfStore "packages/ghostty.conf";
    "opencode/.opencode.json".source = mkOutOfStore "packages/opencode.json";
  };
}
