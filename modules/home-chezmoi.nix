{
  config,
  self,
  ...
}:
let
  inherit (config) me;
in
{
  config.home.base =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      xdg.configFile."chezmoi/chezmoi.json".source = pkgs.writeText "chezmoi.json" (
        builtins.toJSON {
          sourceDir = me.chezmoiDirectory pkgs.stdenv;
        }
      );

      home = {
        activation.chezmoi = lib.hm.dag.entryAfter [ "installPackages" ] ''
          _saved_path=$PATH
          PATH="${config.home.path}/bin:$PATH"
          PATH=$PATH:/usr/local/bin:/usr/bin:/bin

          run ${pkgs.chezmoi}/bin/chezmoi apply -S ${self} --force $VERBOSE_ARG

          PATH=$_saved_path
        '';

        packages = [ pkgs.chezmoi ];
      };
    };
}
