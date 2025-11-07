{
  services.syncthing = {
    enable = true;
    overrideDevices = false;
    overrideFolders = false;
    guiAddress = "0.0.0.0:8384";
    extraOptions = [
      "--allow-newer-config"
    ];
  };
}
