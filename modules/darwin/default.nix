{ lib, ... }:
{
  imports = [ ];
  ids.uids.nixbld = lib.mkForce 350; # or some other uid
  ids.gids.nixbld = 30000;
  nix = {
    settings.experimental-features = "nix-command flakes";
    gc.interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
  };
}
