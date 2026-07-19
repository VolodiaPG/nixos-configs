# Auto-import all modules in this directory with flake specialArgs
{ flake, ... }:
{
  imports = builtins.map (fn: ./${fn}) (
    builtins.filter (fn: fn != "default.nix") (builtins.attrNames (builtins.readDir ./.))
  );

  # Pass flake inputs as specialArgs to all imported modules
  # This allows each module to self-import its flake dependencies
  _module.args = {
    inherit flake;
  };
}
