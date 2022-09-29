{ config, pkgs, ... }:
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

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "wayland";
    NIXOS_OZONE_WL = 1;
  };

  home.packages = with pkgs;
    [
      direnv
      ff2mpv
    ];

  home.file.".config/mpv" = {
    source = ./mpv;
    recursive = true;
  };
  home.file.".config/mpv/svp.py".source = pkgs.substituteAll {
    src = ./svp.py;
    svpflow = "${pkgs.callPackage ../../pkgs/svpflow { }}/lib/";
  };
  home.file.".config/mpv/svp_nvof.py".source = pkgs.substituteAll {
    src = ./svp_nvof.py;
    svpflow = "${pkgs.callPackage ../../pkgs/svpflow { }}/lib/";
  };

  # https://github.com/Ashyni/mpv-scripts/

  programs.git = {
    enable = true;
    userName = "Volodia P.-G.";
    userEmail = (builtins.readFile ../../secrets/gitmail);
    signing = {
      key = (builtins.readFile ../../secrets/gitkeyid);
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
