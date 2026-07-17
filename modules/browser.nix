_: {
  config.nixos.desktop =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
      programs.chromium = {
        enable = true;
        extensions = [
          "nngceckbapebfimnlniiiahkandclblb"
          "mnjggcdmjocbbbhaepdhchncahnbgone"
          "phaodiidhofhdmfkjiacigibgikhfafn"
          "enamippconapkdmgfgjchkhakpfinmaj"
        ];
        extraOpts = {
          "BrowserSignin" = 0;
          "PasswordManagerEnabled" = false;
          "SyncDisabled" = true;
          "SpellcheckEnabled" = true;
          "SpellcheckLanguage" = [ "en-US" ];
        };
      };
      environment.systemPackages = [ pkgs.brave ];
    };
}
