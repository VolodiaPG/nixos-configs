_: {
  config.nixos.server = _: {
    services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
    boot.kernelParams = [ "consoleblank=60" ];
  };
}
