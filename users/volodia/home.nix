{ pkgs, ... }:
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "volodia";
  home.homeDirectory = "/home/volodia";

  programs.nix-index =
    {
      enable = true;
      enableFishIntegration = true;
    };

  programs.fish = {
    # 2. Enable fish-shell if you didn't.
    enable = true;

    # 3. Declare fish plugins to be installed.
    plugins = [
      {
        name = "fzf";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "fzf";
          rev = "479fa67d7439b23095e01b64987ae79a91a4e283";
          sha256 = "sha256-28QW/WTLckR4lEfHv6dSotwkAKpNJFCShxmKFGQQ1Ew=";
        };
      }
      { name = "grc"; inherit (pkgs.fishPlugins.grc) src; }
      { name = "done"; inherit (pkgs.fishPlugins.done) src; }
      { name = "pure"; inherit (pkgs.fishPlugins.pure) src; }
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

  home.packages = with pkgs;
    [
      ff2mpv
    ];

  home.file.".config/mpv" = {
    source = ./mpv;
    recursive = true;
  };
  home.file.".config/mpv/svp.py".source = pkgs.substituteAll {
    src = ./svp.py;
    svpflow = "${pkgs.svpflow}/lib/";
  };
  home.file.".config/mpv/svp_max.py".source = pkgs.substituteAll {
    src = ./svp_max.py;
    svpflow = "${pkgs.svpflow}/lib/";
  };
  home.file.".config/mpv/svp_nvof.py".source = pkgs.substituteAll {
    src = ./svp_nvof.py;
    svpflow = "${pkgs.svpflow}/lib/";
  };

  home.file.".ssh/config".source = pkgs.substituteAll {
    src = ./config.ssh;
    g5k_login = builtins.readFile ../../secrets/grid5000.user;
  };
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
      core.editor = "micro";
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
