{
  config,
  ...
}:
let
  inherit (config) me;
in
{
  config.nixos.desktop =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
      boot = {
        consoleLogLevel = 3;
        initrd.verbose = false;

        plymouth = {
          enable = true;
          theme = "abstract_ring_alt";
          themePackages = with pkgs; [
            (adi1090x-plymouth-themes.override {
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

        loader = {
          efi.canTouchEfiVariables = true;

          grub = {
            theme = pkgs.sleek-grub-theme.override {
              withBanner = "Welcome, ${me.name}!";
              withStyle = "dark";
            };
            default = "saved";
            gfxmodeEfi = "1920x1080,auto";
          };
        };
      };
    };
}
