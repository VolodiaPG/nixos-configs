{
  pkgs,
  ...
}:
{
  programs.opencode = {
    enable = true;
    # settings = {
    #   "plugin" = [ "@plannotator/opencode@latest" ];
    # };
  };
  home.packages = [
    pkgs.cachix
    pkgs.nvim
    pkgs.devenv
  ];
}
