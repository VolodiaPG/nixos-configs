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
    pkgs.nvim
    pkgs-unstable.opencode
    pkgs-unstable.devenv
  ];

  # programs.steam.enable = true;
}
