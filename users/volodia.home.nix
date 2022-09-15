{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "volodia";
  home.homeDirectory = "/home/volodia";

  home.packages = with pkgs; [ direnv ];

  xdg.configFile."mpv/mpv.conf".text = ''
    # SVP Options
    input-ipc-server=/tmp/mpvsocket
    hwdec=auto-copy
    # hwdec=auto-safe
    vo=gpu
    profile=gpu-hq
    # hwdec-codecs=all
    # hr-seek-framedrop=no
    # no-resume-playback

    gpu-context=wayland
  '';

  programs.git = {
    enable = true;
    userName = "Volodia P.-G.";
    userEmail = (builtins.readFile ../secrets/gitmail);
    signing = {
      key = (builtins.readFile ../secrets/gitkeyid);
      signByDefault = true;
    };
    extraConfig = {
      rebase.autostash = true;
      init.defaultBranch = "main";
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
