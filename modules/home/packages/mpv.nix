{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.services.mpv;
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    services.mpv = {
      enable = mkEnableOption "MPV configuration";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        #mpv
        pkgs.play-with-mpv
      ]
      ++ [
        pkgs-unstable.mpv
      ];
      file = {
        ".config/mpv" = {
          source = ./mpv;
          recursive = true;
        };
        #".config/mpv/svp.py".source = pkgs.substituteAll {
        #  src = ./svp.py;
        #  svpflow = "${pkgs.svpflow}/lib/";
        #};
        #".config/mpv/svp_max.py".source = pkgs.substituteAll {
        #  src = ./svp_max.py;
        #  svpflow = "${pkgs.svpflow}/lib/";
        #};
        #".config/mpv/svp_nvof.py".source = pkgs.substituteAll {
        #  src = ./svp_nvof.py;
        #  svpflow = "${pkgs.svpflow}/lib/";
        #};
      };
    };

    #systemd.user.services = {
    #  play-with-mpv = {
    #    Service = {
    #      ExecStart = let
    #        script = pkgs.writeShellScript "play-with-mpv-script" ''
    #          PATH=$PATH:${pkgs-unstable.mpv}/bin
    #          ${pkgs.systemd}/share/factory/etc/X11/xinit/xinitrc.d/50-systemd-user.sh
    #          ${pkgs.play-with-mpv}/bin/play-with-mpv
    #        '';
    #      in "${script}";
    #    };
    #    Unit = {
    #      Requires = ["xdg-desktop-autostart.target"];
    #      WantedBy = ["default.target"];
    #    };
    #  };
    #};
  };
}
