{
  config,
  lib,
  ...
}:
let
  cfg = config.services.user-dotfiles;
in
{
  options.services.user-dotfiles = {
    enable = lib.mkEnableOption "user dotfiles management (placeholder for dynamic configs only - most dotfiles go to chezmoi)";
  };

  config = lib.mkIf cfg.enable {
    # Placeholder for truly dynamic configs only
    # Most dotfiles should be managed by chezmoi instead
    environment.etc = { };
  };
}
