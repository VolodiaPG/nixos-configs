{
  lib,
  pkgs,
  ...
}: {
  services.syncthing = {
    enable = true;
    overrideDevices = false;
    overrideFolders = true;
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
