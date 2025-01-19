{
  config,
  lib,
  pkgs,
  hostName,
  ...
}:
# let
# msi = "msi";
# dell = "dell";
# volodias-macbook-pro = "Volodias-MacBook-Pro";
# home-server = "home-server";
# allDevices = [volodias-macbook-pro dell msi home-server];
# genDevice = hostName: id: {
#   inherit id;
#   addresses = ["tcp://${hostName}:22000"];
# };
# in
{
  services.syncthing = {
    enable = true;
    # openDefaultPorts = true;
    overrideDevices = false; # overrides any devices added or deleted through the WebUI
    overrideFolders = true; # overrides any folders added or deleted through the WebUI
    # user = "volodia";
    # dataDir = if lib.strings.hasSuffix "linux" pkgs.system then "/persistent/Sync" else "/Users/volodia/.syncthingdata";
    # cert = config.sops.secrets."syncthing-${hostName}-cert".path;
    # key = config.sops.secrets."syncthing-${hostName}-key".path;

    settings = {
      # devices = {
      #   ${volodias-macbook-pro} = genDevice volodias-macbook-pro "WLVZHQK-QBOS6XW-5I6WIPH-VZTUSHQ-CA7QWCW-TQ5VT2G-7WD3MC7-ANZDEQQ";
      #   ${dell} = genDevice dell "UFAZWAJ-4BFYDEK-MEZ7VPS-AV3YVG2-HDHXKOJ-SZKIBGM-ORDZ77R-NWYFZQB";
      #   ${msi} = genDevice msi "OPL2OSX-P5EIM6J-OIIKMZI-QE7IEXU-2KURAEU-KBWNUI7-CBWQK4H-CJQK2AO";
      #   ${home-server} = genDevice home-server "S3JD5BW-PMNUD5Y-GGRJINH-FK7MS5B-KEKJJDT-AM6Y6SA-WFAK2M5-S2N65AL";
      # };

      folders = {
        "Sync" = {
          path =
            if lib.strings.hasSuffix "linux" pkgs.system
            then "~/Documents/Sync"
            else "/Users/volodia/Documents/Sync";
          # devices = allDevices;
          # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          ignorePerms = false;
        };
      };
    };
  };
}
