{
  lib,
  config,
  ...
}:
let
  # Determine the default flavor based on system theme
  # Users can override this by setting catppuccin.flavor directly
  defaultFlavor = "mocha"; # Dark theme default
  defaultLightFlavor = "latte"; # Light theme default
in
{
  options.catppuccin = {
    autoThemeSwitch = lib.mkEnableOption "automatic theme switching based on system theme";

    lightFlavor = lib.mkOption {
      type = lib.types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = defaultLightFlavor;
      description = "Catppuccin flavor to use for light mode";
    };

    darkFlavor = lib.mkOption {
      type = lib.types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = defaultFlavor;
      description = "Catppuccin flavor to use for dark mode";
    };
  };

  config = {
    # Set the default catppuccin flavor globally
    catppuccin = {
      flavor = lib.mkDefault config.catppuccin.darkFlavor;
      lazygit.enable = lib.mkDefault false;
    };

    xdg.configFile = {
      "lazygit/theme.dark.yml".source =
        "${config.catppuccin.sources.lazygit}/mocha/${config.catppuccin.accent}.yml";

      "lazygit/theme.light.yml".source =
        "${config.catppuccin.sources.lazygit}/latte/${config.catppuccin.accent}.yml";
    };

    home = {
      activation.lazygit-theme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [[ ! -f "${config.xdg.configHome}/lazygit/theme.yml" ]]; then
          ln -s "${config.xdg.configHome}/lazygit/theme.dark.yml" "${config.xdg.configHome}/lazygit/theme.yml"
        fi
      '';

      sessionVariables =
        let
          configDirectory = config.xdg.configHome;
          configFiles = [
            "${configDirectory}/lazygit/config.yml"
            "${configDirectory}/lazygit/theme.yml"
          ];
        in
        {
          # Ensure that the default config file is still sourced
          LG_CONFIG_FILE = lib.concatStringsSep "," configFiles;
        };
    };
  };
}
