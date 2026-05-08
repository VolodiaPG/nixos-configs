{
  config,
  lib,
  flake,
  ...
}:
with lib;
let
  cfg = config.services.helium;
  inherit (flake) inputs;

in
{
  options.services.helium = {
    enable = lib.mkEnableOption "Helium browser";
  };

  imports = [
    inputs.helium.nixosModules.default
  ];

  config = mkIf cfg.enable {
    programs.helium = {
      enable = true;

      # Optional: override the package
      # package = pkgs.helium;

      # 🚩 Flags - Command-line arguments always passed to Helium
      # flags = [
      #   "--disable-gpu"
      #   "--ozone-platform-hint=auto"
      # ];

      # 🎯 Policies - Written to /etc/chromium/policies/managed/helium-nixos.json
      # Also written to /etc/helium/policies/managed/ for future compatibility
      policies = {
        "BrowserSignin" = 0;
        "PasswordManagerEnabled" = false;
        "SyncDisabled" = true;
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [ "en-US" ];
        "ExtensionInstallForcelist" = [
          # Pre-install extensions
          "nngceckbapebfimnlniiiahkandclblb" # bitwarden
          "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock
          "phaodiidhofhdmfkjiacigibgikhfafn" # Qudelix
        ];
      };
    };
  };
}
