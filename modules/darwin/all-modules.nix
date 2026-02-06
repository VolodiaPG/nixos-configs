# Entry point for all Home Manager modules with specialArgs wiring
# This module auto-imports all modules in the directory and provides
# flake inputs as specialArgs so modules can self-import their dependencies
{ flake, ... }:
let
  moduleFiles =
    with builtins;
    map (fn: ./${fn}) (
      filter (fn: fn != "default.nix" && fn != "all-modules.nix") (attrNames (readDir ./.))
    );
in
{
  imports = moduleFiles; # ++ [ ./packages ];

  # Pass flake inputs as specialArgs to all imported modules
  # This allows each module to self-import its flake dependencies
  _module.args = {
    inherit flake;
    # Note: 'apps' specialArg is provided by nixos-unified autowiring
    # Do not define it here to avoid infinite recursion
  };
}
