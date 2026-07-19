{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.elegantBoot;
in
{
  options = {
    services.elegantBoot = {
      enable = mkEnableOption "elegantBoot";
    };
  };

  config = mkIf cfg.enable {
    # Console
    # console = {
    #   font = "Lat2-Terminus16";
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
        themePackages = [
          # By default we would install all themes
          (pkgs.adi1090x-plymouth-themes.override {
            selected_themes = [ "abstract_ring_alt" ];
          })
        ];
      };
      kernelParams = [
        "quiet"
        "rd.systemd.show_status=auto"
        "udev.log_priority=3"
        "boot.shell_on_fail"
      ];

      # Boot Loader
      loader = {
        efi.canTouchEfiVariables = true;

        grub = {
          theme = pkgs.sleek-grub-theme.override {
            withBanner = "Welcome, ${flake.config.me.name}!";
            withStyle = "dark";
          };
          default = "saved";
          gfxmodeEfi = "1920x1080,auto";
        };
      };
    };
  };
}
