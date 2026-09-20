# Aggregator for the nix-darwin modules in this directory. Imported by the
# darwin host as `self.darwinModules.default`.
#
# Home Manager is wired separately, in ./home-manager.nix.
{
  imports = [
    ./common-darwin.nix
    ./common-nix-settings.nix
    ./common-overlays.nix
  ];
}
