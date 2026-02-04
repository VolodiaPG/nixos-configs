{
  flake,
  pkgs,
  ...
}:
let
  inherit (flake.inputs) self;
in
{
  home.file = {
    ".ssh/config" = {
      target = ".ssh/config_source";
      onChange = "cat ~/.ssh/config_source > ~/.ssh/config && chmod 400 ~/.ssh/config";
      source = pkgs.replaceVars (self + "/assets/config.ssh") {
        g5k_login = "volparolguarino";
        keychain = if pkgs.stdenv.isLinux then "" else "UseKeychain yes";
      };
    };
  };
}
