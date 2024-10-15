{config, ...}: let
  inherit (config.sops) secrets;
  inherit (config.networking) hostName;
  msi = "msi";
  dell = "dell";
  m1 = "m1";
  home-server = "home-server";
  allDevices = [m1 dell msi home-server];

  genDevice = hostName: id: {
    inherit id;
    addresses = ["tcp://${hostName}:22000"];
  };
in {
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    overrideDevices = true; # overrides any devices added or deleted through the WebUI
    overrideFolders = true; # overrides any folders added or deleted through the WebUI
    user = "volodia";
    dataDir = "/persistent/Sync";
    cert = secrets."syncthing-${hostName}-cert".path;
    key = secrets."syncthing-${hostName}-key".path;

    settings = {
      devices = {
        ${m1} = genDevice m1 "MHXF54G-BZIEQMN-74IYJC6-HMJMCSW-MIBMEIJ-L3EGGXM-S5E74DQ-LXISYA6";
        ${dell} = genDevice dell "UFAZWAJ-4BFYDEK-MEZ7VPS-AV3YVG2-HDHXKOJ-SZKIBGM-ORDZ77R-NWYFZQB";
        ${msi} = genDevice msi "OPL2OSX-P5EIM6J-OIIKMZI-QE7IEXU-2KURAEU-KBWNUI7-CBWQK4H-CJQK2AO";
        ${home-server} = genDevice home-server "S3JD5BW-PMNUD5Y-GGRJINH-FK7MS5B-KEKJJDT-AM6Y6SA-WFAK2M5-S2N65AL";
      };
      folders = {
        "Sync" = {
          path = "/home/volodia/Documents/Sync";
          devices = allDevices;
          # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          ignorePerms = false;
        };
      };
    };
  };
}
