{
  pkgs-unstable,
  pkgs,
  ...
}:
{
  # programs.obs-studio = {
  #   enable = true;
  #   plugins = with stable-pkgs.obs-studio-plugins; [
  #     wlrobs
  #     obs-backgroundremoval
  #     obs-pipewire-audio-capture
  #     obs-ndi
  #   ];
  # };
  home.packages = [
    pkgs.ripgrep
    pkgs.nvim
    pkgs-unstable.opencode
    pkgs-unstable.devenv
    pkgs.difftastic
    pkgs.discordo
  ];

  # programs.steam.enable = true;
}
