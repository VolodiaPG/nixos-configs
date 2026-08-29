{ flake, ... }:
{
  imports = [
    ./common-darwin.nix
    ./common-nix-settings.nix
    ./common-overlays.nix
  ];

  _module.args = {
    inherit flake;
  };
}
