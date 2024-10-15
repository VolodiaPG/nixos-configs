{config, ...}: let
  inherit (config.sops) secrets;
  # msi = "msi";
  dell = "dell";
  m1 = "m1";
  # home-server = "home-server";
  allDevices = [m1 dell];

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
    cert = secrets.syncthing-cert.path;
    key = secrets.syncthing-key.path;

    settings = {
      devices = {
        ${m1} = genDevice m1 "MHXF54G-BZIEQMN-74IYJC6-HMJMCSW-MIBMEIJ-L3EGGXM-S5E74DQ-LXISYA6";
        ${dell} = genDevice dell "GMGNHR6-PC2U5OI-H75XTU2-IZXVAVW-BVPYWUX-MYWECVE-QH2DD3B-GVWUCAB";
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
