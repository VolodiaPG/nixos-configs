{ config, pkgs, lib, ... }:


{
  options = {
    services.nvfancontrol = with lib; with types; {
      enable = mkEnableOption "nvfancontrol";

      package = mkOption {
        description = "nvfancontrol package";
        defaultText = literalExpression "pkgs.nvfancontrol";
        type = package;
        default = pkgs.nvfancontrol;
      };

      configuration = mkOption {
        description = "configuration";
        type = lines;
        default = builtins.readFile ./nvfancontrol.conf;
      };

      cliArgs = mkOption {
        description = "CLI arguments";
        type = str;
        default = "";
      };
    };
  };

  ### Implementation ###

  config =
    let
      cfg = config.services.nvfancontrol;
    in
    lib.mkIf cfg.enable {
      systemd.user.services.foo = {
        enable = cfg.enable;
        description = "Nvidia fan control startup";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        script = "${cfg.package}/bin/nvfancontrol ${cfg.cliArgs}";
      };

      environment.etc = {
        "xdg/nvfancontrol.conf".text = "${cfg.configuration}";
      };

      environment.systemPackages = [
        (cfg.package)
      ];
    };
}

