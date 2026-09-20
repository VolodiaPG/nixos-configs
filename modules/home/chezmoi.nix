{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  cfg = config.my.chezmoi;
  inherit (lib) mkEnableOption mkIf;
  inherit (flake.inputs) self;

  # Only the chezmoi tree, not the whole flake source. Handing `chezmoi apply`
  # the flake root makes the activation script — and therefore the whole system
  # generation — depend on every file in this repo, so editing a module or a
  # README produced a "changed" system that only re-ran chezmoi.
  # `.chezmoiroot` (= "chezmoi") is what points at this subdirectory when
  # chezmoi is run by hand from the repo root; passing it directly is equivalent.
  chezmoiSource = builtins.path {
    path = self + "/chezmoi";
    name = "chezmoi-source";
  };
in
{
  options.my.chezmoi = {
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

        run ${pkgs.chezmoi}/bin/chezmoi apply --force $VERBOSE_ARG -S ${chezmoiSource}

        # return it back
        PATH=$_saved_path
      '';

      packages = [ pkgs.chezmoi ];
    };
  };
}
