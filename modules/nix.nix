{
  inputs,
  ...
}:
{
  config.nixos.base = _: {
    imports = [ inputs.determinate.nixosModules.default ];
  };
}
