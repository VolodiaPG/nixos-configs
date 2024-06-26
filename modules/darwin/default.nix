{lib, ...}: {
  imports = [];
  ids.uids.nixbld = lib.mkForce 400; # or some other uid
  nix = {
    settings.experimental-features = "nix-command flakes";
    configureBuildUsers = true;
    gc.interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
  };
}
