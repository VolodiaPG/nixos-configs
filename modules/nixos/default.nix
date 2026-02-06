# Auto-import all modules in this directory with flake specialArgs
{ flake, ... }:
{
  imports =
    with builtins;
    map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));

  # Pass flake inputs as specialArgs to all imported modules
  # This allows each module to self-import its flake dependencies
  _module.args = {
    inherit flake;
  };
}
