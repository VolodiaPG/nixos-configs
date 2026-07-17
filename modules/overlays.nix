{
  self,
  ...
}:
{
  config.nixos.base = _: {
    nixpkgs.overlays = [ self.overlays.default ];
  };

  config.darwin.mac = _: {
    nixpkgs.overlays = [ self.overlays.default ];
  };
}
