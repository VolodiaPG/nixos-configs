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
    else ''"(dirty)" '';
in {
  imports =
    lib.optional (graphical == "gnome") ./gnome.nix
    ++ lib.optional (apps != "no-apps") ./packages;

  fonts.fontconfig.enable = true;

  catppuccin.enable = true;

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
    nix-index = {
      enable = true;
      enableBashIntegration = true;
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = [
        "--cmd cd"
      ];
      #enableBashIntegration = true;
    };
    fish = {
      enable = true;
      plugins = [
        {
          name = "fzf";
          inherit (pkgs.fzf) src;
        }
        {
          name = "grc";
          inherit (pkgs.grc) src;
        }
        {
          name = "done";
          inherit (pkgs.fishPlugins.done) src;
        }
        {
          name = "pure";
          inherit (pkgs.fishPlugins.pure) src;
        }
      ];
      shellInit = ''
        set -g GPG_TTY (tty)
        set -g EDITOR nvim

        set --universal pure_enable_nixdevshell true
        set --universal pure_symbol_nixdevshell_prefix ❄
      '';

      interactiveShellInit = ''
        if type -q nixos-version
            echo Running ${status}Nixos (nixos-version) (${lib.getExe date_script})
        else
          echo Running ${status}Nix
        end
      '';

      shellAliases = {
        ll = "ls -l";
        l = "ls";
        j = "just";
        jl = "just --list";
        g = "git";
        c = "clear";
      };
    };
    zsh = {
      enable = true;
      initExtra = ''
        # Make Nix and home-manager installed things available in PATH.
        export PATH=/run/current-system/sw/bin/:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/usr/local/bin/:$PATH
        exec ${pkgs.fish}/bin/fish
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
    packages = with pkgs; [
      fontconfig
      nvim
      tmux
      mosh
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
      ".config/kitty/kitty.conf".source = ./kitty.conf;
      #".config/kitty/theme.conf".source = ./theme.conf;
      ".ssh/config" = {
        source = pkgs.substituteAll {
          src = ./config.ssh;
          # g5k_login = builtins.readFile ../../secrets/grid5000.user;
          g5k_login = "volparolguarino";
          keychain =
            if pkgs.stdenv.isLinux
            then ""
            else "UseKeychain yes";
        };
        mode = "0600";
      };
      ".ssh/authorized_keys".text = ''
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpDmkY5OctLdxrPUcnRafndhDvvgw/GNYvgo4I9LrPJ341vGzwgqSi90YRvn725DkYHmEi1bN7i3W2x1AQbuvEBzxMG3BlwtEGtz+/5rIMY+5LRzB4ppN+Ju/ySbPKSD2XpVgVOCegc7ZtZ4XpAevVsi/kyg35RPNGmljEyuN1wIxBVARZXZezsGf1MHzxEqiNogeAEncPCk/P44B6xBRt9qSxshIT/23Cq3M/CpFyvbI0vtdLaVFIPox6ACwlmTgdReC7p05EefKEXaxVe61yhBquzRwLZWf6Y8VESLFFPZ+lEF0Shffk15k97zJICVUmNPF0Wfx1Fn5tQyDeGe2nA5d2aAxHqvl2mJk/fccljzi5K6j6nWNf16pcjWjPqCCOTs8oTo1f7gVXQFCzslPnuPIVUbJItE3Ui+mSTv9KF/Q9oH02FF40mSuKtq5WmntV0kACfokRJLZ6slLabo0LgVzGoixdiGwsuJbWAsNNHURoi3lYb8fMOxZ/2o4GZik= volodia@volodia-msi
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT volodia.parol-guarino@proton.me
      '';

      ".config/mpv/scripts" = {
        source = ./packages/scripts;
        recursive = true;
      };
      #".yabairc".source = ./packages/.yabairc;
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
