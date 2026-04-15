{
  config,
  lib,
  flake,
  ...
}:
let
  cfg = config.services.chezmoi-activation;
  inherit (flake.config) me;
in
{
  options.services.chezmoi-activation = {
    enable = lib.mkEnableOption "chezmoi activation on system rebuild";
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.chezmoi = {
      deps = [
        "users"
        "groups"
      ];
      text = ''
        # Run chezmoi apply as the user (non-fatal)
        echo "Running chezmoi apply for ${me.username}..."
        ${config.security.wrapperDir}/runuser -u ${me.username} -- \
          env PATH="/run/current-system/sw/bin:$PATH" \
          chezmoi apply || echo "Warning: chezmoi apply failed (non-fatal)"
      '';
    };

    system.activationScripts.kitty-themes = {
      deps = [ "chezmoi" ];
      text = ''
        # Create symlink for kitty themes
        echo "Setting up kitty themes symlink..."
        KITTY_CONFIG_DIR="${me.homeDirectory}/.config/kitty"
        if [ -d "$KITTY_CONFIG_DIR" ]; then
          ln -sf /run/current-system/sw/share/kitty-themes "$KITTY_CONFIG_DIR/kitty-themes" || echo "Warning: kitty-themes symlink failed (non-fatal)"
        fi
      '';
    };
  };
}
