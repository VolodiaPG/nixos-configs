{ config, pkgs, ... }:
let
  mpv-unwrapped = pkgs.mpv-unwrapped.override { vapoursynthSupport = true; };
  mpv = pkgs.wrapMpv mpv-unwrapped { youtubeSupport = true; };
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "volodia";
  home.homeDirectory = "/home/volodia";

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM="wayland";
  };

  home.packages = [ mpv ] ++ (with pkgs;
    [ direnv ff2mpv ]);

  home.file.".config/mpv/motioninterpolation.py".source = pkgs.substituteAll {
    src = ./motioninterpolation.py;
    mvtoolslib = "${pkgs.vapoursynth-mvtools}/lib/vapoursynth/";
  };

  home.file.".config/mpv/svp.py".source = pkgs.substituteAll {
    src = ./svp.py;
    svpflow = "${pkgs.callPackage ../../pkgs/svpflow { }}/lib/";
    oclicd = "${pkgs.ocl-icd}/lib/";
    # mvtoolslib = "${pkgs.vapoursynth-mvtools}/lib/vapoursynth/";
  };

  home.file.".config/mpv/mpv.conf".text = ''
    hwdec=auto-copy
    # hwdec=auto-safe
    vo=gpu
    profile=gpu-hq
    hwdec-codecs=all
    hr-seek-framedrop=no
    no-resume-playback

    gpu-context=wayland
    #vf=format=yuv420p,vapoursynth=~~/motioninterpolation.py:4:4
    # vf=vapoursynth=~~/svp.py:2:24
  '';

  home.file.".config/mpv/input.conf".text = ''
    h vf toggle vapoursynth=~~/svp.py:2:24
  '';

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
