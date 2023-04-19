{
  lib,
  pkgs,
  overlays,
  graphical,
  apps,
  ...
}: {
  imports =
    lib.optional (graphical == "gnome") ./gnome.nix
    ++ lib.optional (apps != "no-apps") ./packages;

  nixpkgs.overlays = overlays;
  nixpkgs.config.allowUnfree = true;
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "volodia";
  home.homeDirectory = "/home/volodia";
  # home.homeDirectory = "/Users/volodia";

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish = {
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

    shellAliases = {
      cd = "z";
      ll = "ls -l";
      l = "ls";
      push = "git push";
      pull = "git pull";
      fetch = "git fetch";
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  home.file.".config/discord/settings.json".text = ''
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

  home.file.".ssh/config".source = pkgs.substituteAll {
    src = ./config.ssh;
    g5k_login = builtins.readFile ../../secrets/grid5000.user;
  };
  home.file.".ssh/authorized_keys".text = ''
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpDmkY5OctLdxrPUcnRafndhDvvgw/GNYvgo4I9LrPJ341vGzwgqSi90YRvn725DkYHmEi1bN7i3W2x1AQbuvEBzxMG3BlwtEGtz+/5rIMY+5LRzB4ppN+Ju/ySbPKSD2XpVgVOCegc7ZtZ4XpAevVsi/kyg35RPNGmljEyuN1wIxBVARZXZezsGf1MHzxEqiNogeAEncPCk/P44B6xBRt9qSxshIT/23Cq3M/CpFyvbI0vtdLaVFIPox6ACwlmTgdReC7p05EefKEXaxVe61yhBquzRwLZWf6Y8VESLFFPZ+lEF0Shffk15k97zJICVUmNPF0Wfx1Fn5tQyDeGe2nA5d2aAxHqvl2mJk/fccljzi5K6j6nWNf16pcjWjPqCCOTs8oTo1f7gVXQFCzslPnuPIVUbJItE3Ui+mSTv9KF/Q9oH02FF40mSuKtq5WmntV0kACfokRJLZ6slLabo0LgVzGoixdiGwsuJbWAsNNHURoi3lYb8fMOxZ/2o4GZik= volodia@volodia-msi
  '';
  home.file.".python-grid5000.yaml".source = ../../secrets/python-grid5000.yaml;

  home.file.".tmux".text = ''
    set -g mouse

    bind C-c run "tmux save-buffer - | wl-copy"

    bind C-v run "tmux set-buffer "$(wl-paste)"; tmux paste-buffer"
  '';

  programs.git = {
    enable = true;
    userName = "Volodia P.-G.";
    userEmail = builtins.readFile ../../secrets/gitmail;
    signing = {
      key = builtins.readFile ../../secrets/gitkeyid;
      signByDefault = true;
    };
    extraConfig = {
      rebase.autostash = true;
      init.defaultBranch = "main";
      core.editor = "nano";
      aliases.lg = "log --color --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";
}
