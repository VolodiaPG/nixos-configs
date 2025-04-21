{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.elegantBoot;
in {
  options = {
    services.elegantBoot = with types; {
      enable = mkEnableOption "elegantBoot";
    };
  };

  config =
    mkIf cfg.enable
    {
      # Console
      console = {
        font = "Lat2-Terminus16";
        keyMap = lib.mkForce "fr";
      };

      # TTY
      fonts.packages = with pkgs; [meslo-lgs-nf];
      services.kmscon = {
        enable = true;
        hwRender = true;
        extraConfig = ''
          font-name=MesloLGS NF
          font-size=14
        '';
      };

      # Boot
      boot = {
        # Plymouth
        consoleLogLevel = 0;
        initrd.verbose = false;
        initrd.systemd.enable = true;

        plymouth.enable = true;
        kernelParams = ["quiet" "splash" "rd.systemd.show_status=false" "rd.udev.log_level=3" "udev.log_priority=3" "boot.shell_on_fail"];

        # Boot Loader
        loader = {
          timeout = 3;
          efi.canTouchEfiVariables = true;
        };
      };
    };
}
