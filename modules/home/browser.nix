{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.browser;
  inherit (lib) mkIf;
in
{
  options.browser = {
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
      #
      extensions = [
        {
          id = "nngceckbapebfimnlniiiahkandclblb"; # bitwarden
        }

        {
          id = "mnjggcdmjocbbbhaepdhchncahnbgone"; # sponsorblock
        }

        {
          id = "phaodiidhofhdmfkjiacigibgikhfafn"; # Quedelix
        }
        {
          id = "enamippconapkdmgfgjchkhakpfinmaj"; # dearrow
        }
      ];
    };
  };
}
