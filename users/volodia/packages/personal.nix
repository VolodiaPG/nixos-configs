{
  pkgs-unstable,
  pkgs,
  ...
}: {
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
    pkgs.opencode
    pkgs-unstable.devenv
    pkgs-unstable.aider-chat
    pkgs-unstable.difftastic
  ];

  # programs.steam.enable = true;
}
