{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.browser;
in
{
  options.services.browser = {
    enable = lib.mkEnableOption "My browser";
  };

  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;

      package = pkgs.brave;

      # 🚩 Flags - Command-line arguments always passed to Helium
      # flags = [
      #   "--disable-gpu"
      #   "--ozone-platform-hint=auto"
      # ];

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
          "enamippconapkdmgfgjchkhakpfinmaj" # dearrow
        ];
      };
    };
  };
}
