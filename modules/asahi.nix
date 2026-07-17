{
  inputs,
  ...
}:
{
  config.nixos.asahi = _: {
    imports = [ inputs.nixos-apple-silicon.nixosModules.default ];
  };
}
