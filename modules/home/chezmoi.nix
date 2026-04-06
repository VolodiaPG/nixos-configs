{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  cfg = config.chezmoi;
  inherit (lib) mkEnableOption mkIf;
  inherit (flake.inputs) self;
in
{
  options.chezmoi = {
    enable = mkEnableOption "chezmoi";
  };

  config = mkIf cfg.enable {

    xdg.configFile."chezmoi/chezmoi.json".source = pkgs.writeText "chezmoi.json" (
      builtins.toJSON {
        sourceDir = flake.config.me.chezmoiDirectory pkgs.stdenv;
      }
    );
    # we want to do stuffs after HM has finished linking stuffs in `$NIX_PROFILES/bin`
    home = {
      activation.chezmoi = lib.hm.dag.entryAfter [ "installPackages" ] ''
        # I want chezmoi to have access to the userspace $PATH
        _saved_path=$PATH
        PATH="${config.home.path}/bin:$PATH"
        # a lot of my chezmoi scripts needs system programs to work, might be a bad idea idk
        PATH=$PATH:/usr/local/bin:/usr/bin:/bin

        run ${pkgs.chezmoi}/bin/chezmoi apply -S ${self} $VERBOSE_ARG

        # return it back
        PATH=$_saved_path
      '';

      packages = [ pkgs.chezmoi ];
    };
  };
}
