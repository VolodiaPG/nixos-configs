_: {
  config.nixos.hyperhdr =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
      environment.systemPackages = with pkgs; [ hyperhdr ];

      systemd.user.services.hyperhdr = {
        description = "HyperHDR Ambient Lighting";
        wantedBy = [ "graphical-session.target" ];
        after = [
          "graphical-session.target"
          "pipewire.service"
        ];
        wants = [ "pipewire.service" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.hyperhdr}/bin/hyperhdr --pipewire --service";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      users.users.volodia.extraGroups = [
        "audio"
        "video"
      ];
    };
}
