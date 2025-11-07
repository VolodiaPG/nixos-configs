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
}:
let
  mkOutOfStore =
    path:
    if symlinkPath == null then
      ./. + "/${path}"
    else
      config.lib.file.mkOutOfStoreSymlink "${symlinkPath}/${path}";
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
  status = if isClean then '''' else ''"dirty" '';
in
{
  imports =
    lib.optional (graphical == "gnome") ./gnome.nix
    ++ lib.optional (builtins.elem graphical [
      "gnome"
      "macos"
    ]) ./mail.nix
    ++ lib.optional (apps != "no-apps") ./packages
    ++ [
      ./syncthing.nix
    ];

  fonts.fontconfig.enable = true;

  catppuccin.enable = true;

  programs = {
    # Let Home Manager install and manage itself.
    lazygit = {
      enable = true;
      settings = {
        git = {
          paging = {
            pager = "diff-so-fancy";
          };
        };
      };
    };
    home-manager.enable = true;
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
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

        if (which nixos-version > /dev/null); then
         echo $"Running ${status}Nixos $(nixos-version) $(${lib.getExe date_script})"
        else
          echo "Running ${status}Nix"
        fi

        if [ -f ${config.age.secrets.envvars.path} ]; then
          source ${config.age.secrets.envvars.path}
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
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
    starship = {
      enable = true;
      enableZshIntegration = true;
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
      settings = {
        user = {
          name = "Volodia P.-G.";
          email = "volodia.parol-guarino@proton.me";
        };
        rebase.autostash = true;
        init.defaultBranch = "main";
        core.editor = "nvim";
        alias.lg = "log --color --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
      signing = {
        format = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT";
        signByDefault = true;
      };
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

  # systemd.user.services.UseSecrets =
  #   let
  #     script = pkgs.writeShellScript "agenix-user-test" ''
  #       echo "Accessing pythong5k secret path:"
  #       echo ${config.age.secrets.pythong5k.path}
  #       # Example: cat ${config.age.secrets.pythong5k.path}
  #     '';
  #   in
  #   lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  #     Unit = {
  #       Description = "test";
  #     };
  #     Service = {
  #       ExecStart = script;
  #       Type = "oneshot";
  #       RemainAfterExit = true;
  #     };
  #     Install.WantedBy = [ "default.target" ];
  #   };

  # systemd.user.services.sshIdRsa =
  #   let
  #     binPath = lib.strings.makeBinPath ([ pkgs.coreutils ] ++ pkgs.stdenv.initialPath);
  #     script = pkgs.writeShellScript "symlinkrsa" ''
  #       export PATH="${binPath}"
  #       if [ ! -f ~/.ssh/id_rsa.pub ] || [ "$(realpath ~/.ssh/id_rsa.pub)" != "$(realpath ~/.ssh/id_ed25519.pub)" ]; then
  #         ln -s ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub
  #       fi
  #       if [ ! -f ~/.ssh/id_rsa ] || [ "$(realpath ~/.ssh/id_rsa)" != "$(realpath ~/.ssh/id_ed25519)" ]; then
  #         ln -s ~/.ssh/id_ed25519 ~/.ssh/id_rsa
  #       fi
  #     '';
  #   in
  #   lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  #     Unit = {
  #       Description = "symlink rsa keys";
  #     };
  #     Service = {
  #       ExecStart = script;
  #       Type = "oneshot";
  #       RemainAfterExit = true;
  #     };
  #     Install.WantedBy = [ "default.target" ];
  #   };

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

  home.activation = {
    copyNixApps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      # Create directory for the applications
      mkdir -p "$HOME/Applications/Nix-Apps"
      # Remove old entries
      rm -rf "$HOME/Applications/Nix-Apps"/*
      # Get the target of the symlink
      NIXAPPS=$(readlink -f "$HOME/.nix-profile/Applications")
      # For each application
      for app_source in "$NIXAPPS"/*; do
        if [ -d "$app_source" ] || [ -L "$app_source" ]; then
            appname=$(basename "$app_source")
            target="$HOME/Applications/Nix-Apps/$appname"

            # Create the basic structure
            mkdir -p "$target"
            mkdir -p "$target/Contents"

            # Copy the Info.plist file
            if [ -f "$app_source/Contents/Info.plist" ]; then
              mkdir -p "$target/Contents"
              cp -f "$app_source/Contents/Info.plist" "$target/Contents/"
            fi

            # Copy icon files
            if [ -d "$app_source/Contents/Resources" ]; then
              mkdir -p "$target/Contents/Resources"
              find "$app_source/Contents/Resources" -name "*.icns" -exec cp -f {} "$target/Contents/Resources/" \;
            fi

            # Symlink the MacOS directory (contains the actual binary)
            if [ -d "$app_source/Contents/MacOS" ]; then
              ln -sfn "$app_source/Contents/MacOS" "$target/Contents/MacOS"
            fi

            # Symlink other directories
            for dir in "$app_source/Contents"/*; do
              dirname=$(basename "$dir")
              if [ "$dirname" != "Info.plist" ] && [ "$dirname" != "Resources" ] && [ "$dirname" != "MacOS" ]; then
                ln -sfn "$dir" "$target/Contents/$dirname"
              fi
            done
          fi
          done
    '';
  };

  home = {
    inherit homeDirectory username;
    packages = with pkgs; [
      fontconfig
      tmux
      mosh
      diff-so-fancy
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
          keychain = if pkgs.stdenv.isLinux then "" else "UseKeychain yes";
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
      ".yabairc".source = mkOutOfStore "packages/yabairc";
      ".skhdrc".source = mkOutOfStore "packages/skhdrc";
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
    # "starship.toml".source = lib.mkForce (mkOutOfStore "packages/starship.toml");

    "ghostty/config".source = mkOutOfStore "packages/ghostty.conf";
    "opencode/.opencode.json".source = mkOutOfStore "packages/opencode.json";
  };
}
