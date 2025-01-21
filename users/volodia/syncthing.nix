{
  lib,
  pkgs,
  ...
}: {
  services.syncthing = {
    enable = true;
    overrideDevices = false;
    overrideFolders = false;
    guiAddress = "0.0.0.0:8384";
    settings = {
      folders = {
        "Sync" = {
          path =
            if lib.strings.hasSuffix "linux" pkgs.system
            then "~/Documents/Sync"
            else "/Users/volodia/Documents/Sync";
          ignorePerms = false;
        };
      };
    };
  };
}
