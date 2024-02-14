_: {
  imports = [];
  nix = {
    settings.experimental-features = "nix-command flakes";
    gc.interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
  };
}
