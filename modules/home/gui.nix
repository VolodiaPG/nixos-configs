{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui;
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    gui = {
      enable = mkEnableOption "GUI configuration for users";
    };
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = pkgs.stdenv.isLinux;

    home = {
      packages = [
        pkgs.signal-desktop
        pkgs.qbittorrent
        # pkgs.drawio
        pkgs.kitty
        pkgs.kitty-themes
      ]
      ++ (lib.optionals pkgs.stdenv.isLinux [
        pkgs.gparted
        pkgs.filezilla
        pkgs.libnotify
        # pkgs.vlc
        pkgs.legcord
        pkgs.notify-desktop
        pkgs.fontconfig
        pkgs.distrobox
        pkgs.distrobox-tui
        # pkgs.easyeffects
        # pkgs.libreoffice-qt-fresh
        # pkgs.freerdp
        pkgs.high-tide
        # (pkgs.symlinkJoin {
        #   name = "sone";
        #   paths = [
        #     pkgs.sone
        #   ];
        #   nativeBuildInputs = [ pkgs.makeWrapper ];
        #   postBuild = ''
        #     wrapProgram $out/bin/sone \
        #       --set WEBKIT_DISABLE_DMABUF_RENDERER "0" \
        #       --set WEBKIT_DISABLE_COMPOSITING_MODE "0"
        #   '';
        # })
        # pkgs.calibre
        pkgs.inkscape
        pkgs.gimp
        pkgs.freecad
        # pkgs.bambu-studio
        # (pkgs.symlinkJoin {
        #   #  Wrap for nvidia drivers, don't use the default override not to rebuild the whole package
        #   name = "orca-slicer";
        #   paths = [ pkgs.orca-slicer ];
        #   nativeBuildInputs = [ pkgs.makeWrapper ];
        #   postBuild = ''
        #     wrapProgram $out/bin/orca-slicer \
        #       --set __GLX_VENDOR_LIBRARY_NAME "mesa" \
        #       --set __EGL_VENDOR_LIBRARY_FILENAMES "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json" \
        #       --set MESA_LOADER_DRIVER_OVERRIDE "zink" \
        #       --set GALLIUM_DRIVER "zink" \
        #       --set WEBKIT_DISABLE_DMABUF_RENDERER "1"
        #   '';
        # })
      ]);

      file = {
        ".config/kitty/kitty-themes".source = "${pkgs.kitty-themes}/share/kitty-themes";
        ".config/discord/settings.json".text = ''
          {
            "BACKGROUND_COLOR": "#202225",
            "IS_MAXIMIZED": false,
            "IS_MINIMIZED": true,
            "SKIP_HOST_UPDATE": true,
            "WINDOW_BOUNDS": {
              "x": 307,
              "y": 127,
              "width": 1280,
              "height": 725
            }
          }
        '';
      };
    };
  };
}
