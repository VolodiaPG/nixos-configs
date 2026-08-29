{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (flake.config) me;
  cfg = config.services.hyperhdr;
in
{
  options = {
    services.hyperhdr = {
      enable = mkEnableOption "hyperhdr";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.hyperhdr
    ];

    systemd.services.hyperhdr = {
      description = "HyperHDR Ambient Lighting";
      wantedBy = [ "graphical.target" ];
      after = [
        "graphical.target"
        "pipewire.service"
      ];
      wants = [ "pipewire.service" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.hyperhdr}/bin/hyperhdr --pipewire --service";
        Restart = "on-failure";
        RestartSec = "5s";
        User = me.username;
      };
    };

    # services.pipewire = {
    #   enable = true;
    #   alsa.enable = true;
    #   pulse.enable = true;
    # };

    users.users.${me.username}.extraGroups = [
      "audio"
      "video"
    ];
  };
}
