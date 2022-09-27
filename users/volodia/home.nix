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

  # home.packages = [ mpv ] ++ (with pkgs;
  #   [ direnv ff2mpv ]);
  # home.packages = with pkgs; [ ];
  home.packages = with pkgs;
    [
      direnv
      ff2mpv
      vs-rife
      # (pkgs.callPackage ../../pkgs/vs-rife { })
    ];

  home.file.".config/mpv/svp.py".source = pkgs.substituteAll {
    src = ./svp.py;
    svpflow = "${pkgs.callPackage ../../pkgs/svpflow { }}/lib/";
  };
  home.file.".config/mpv/svp_nvof.py".source = pkgs.substituteAll {
    src = ./svp_nvof.py;
    svpflow = "${pkgs.callPackage ../../pkgs/svpflow { }}/lib/";
  };
  home.file.".config/mpv/rife.py".source = pkgs.substituteAll {
    src = ./rife.py;
    vsrife = "${pkgs.vs-rife}/lib/python3.10/site-packages/";
    # rife = "${pkgs.callPackage ../../pkgs/vs-rife { }}/lib/";
    # vsrife = "${pkgs.callPackage ../../pkgs/vs-rife { }}/lib/";
  };

  home.file.".config/mpv/mpv.conf".text = ''
    hwdec=auto-copy
    #hwdec=auto-safe
    # vo=gpu-next
    #profile=gpu-hq
    #hwdec-codecs=all
    #hr-seek-framedrop=no
    #no-resume-playback

    # gpu-api=vulkan
    # gpu-context=wayland
  '';

  home.file.".config/mpv/input.conf".text = ''
    h vf toggle vapoursynth=~~/svp.py:2:24
    y vf toggle vapoursynth=~~/svp_nvof.py:2:24
    n vf toggle vapoursynth=~~/rife.py:2:24
  '';

  # https://github.com/Ashyni/mpv-scripts/
  home.file.".config/mpv/scripts/dynamic-crop.lua".source = ./dynamic-crop.lua;

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
