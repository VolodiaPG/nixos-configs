let
  inherit (builtins) readDir attrNames filter;
  inherit (builtins) map listToAttrs;

  # Get all .nix files in the current directory except default.nix
  nixFiles = filter (name: name != "default.nix") (
    filter (name: builtins.match ".*\\.nix" name != null) (attrNames (readDir ./.))
  );

  # Convert filename to module name (remove .nix extension)
  fileToModuleName = file: builtins.head (builtins.split "\\.nix$" file);

  # Create attribute set from files
  modules = listToAttrs (
    map (file: {
      name = fileToModuleName file;
      value = import (./. + "/${file}");
    }) nixFiles
  );
in
modules
