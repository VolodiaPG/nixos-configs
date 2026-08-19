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

      package = pkgs.brave-origin;

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
        # {
        #   id = "enamippconapkdmgfgjchkhakpfinmaj"; # dearrow
        # }
      ];
    };
  };
}
