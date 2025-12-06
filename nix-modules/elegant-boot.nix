{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.elegantBoot;
in
{
  options = {
    services.elegantBoot = with types; {
      enable = mkEnableOption "elegantBoot";
    };
  };

  config = mkIf cfg.enable {
    # Console
    # console = {
    #   font = "Lat2-Terminus16";
    #   keyMap = lib.mkForce "fr";
    # };

    # TTY
    # fonts.packages = with pkgs; [meslo-lgs-nf];
    # services.kmscon = {
    #   enable = true;
    #   hwRender = true;
    #   extraConfig = ''
    #     font-name=MesloLGS NF
    #     font-size=14
    #   '';
    # };

    # Boot
    boot = {
      # Plymouth
      consoleLogLevel = 3;
      initrd.verbose = false;

      plymouth = {
        enable = true;
        theme = "abstract_ring_alt";
        themePackages = with pkgs; [
          # By default we would install all themes
          (adi1090x-plymouth-themes.override {
            selected_themes = [ "abstract_ring_alt" ];
          })
        ];
      };
      kernelParams = [
        "quiet"
        "splash"
        "rd.systemd.show_status=auto"
        "udev.log_priority=3"
        "boot.shell_on_fail"
      ];

      # Boot Loader
      loader = {
        timeout = 0;
        efi.canTouchEfiVariables = true;
      };
    };
  };
}
