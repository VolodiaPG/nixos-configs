{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.userSession;
in
{
  options.userSession = {
    enable = mkEnableOption "User session environment variables";
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      LG_CONFIG_FILE = "$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/theme.yml";
    };
  };
}
