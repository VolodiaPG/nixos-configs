{ lib, ... }:
{
  options.test-class = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
}
