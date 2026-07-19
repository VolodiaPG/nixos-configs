# Entry point for all Darwin modules with specialArgs wiring
# This module auto-imports all modules in the directory and provides
# flake inputs as specialArgs so modules can self-import their dependencies
{ flake, ... }:
{
  imports = builtins.map (fn: ./${fn}) (
    builtins.filter (fn: fn != "default.nix" && fn != "all-modules.nix") (
      builtins.attrNames (builtins.readDir ./.)
    )
  );

  # Pass flake inputs as specialArgs to all imported modules
  # This allows each module to self-import its flake dependencies
  _module.args = {
    inherit flake;
  };
}
