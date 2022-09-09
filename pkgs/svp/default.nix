{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}:
let
  originalPackage = pkgs.nur.repos.xddxdd.svp;

  # We use `overrideAttrs` instead of defining a new `mkDerivation` to keep
  # the original package's `output`, `passthru`, and so on.
  svpOverridenWayland = originalPackage.overrideAttrs (old: {
    name = "svp-overriden-with-wayland";

    # Using `buildCommand` replaces the original packages build phases.
    buildCommand = ''
      set -euo pipefail

      ${
        # Copy original files, for each split-output (`out`, `dev` etc.).
        # E.g. `${package.dev}` to `$dev`, and so on. If none, just "out".
        # Symlink all files from the original package to here (`cp -rs`),
        # to save disk space.
        # We could alternatiively also copy (`cp -a --no-preserve=mode`).
        lib.concatStringsSep "\n"
          (map
            (outputName:
              ''
                echo "Copying output ${outputName}"
                set -x
                cp -rs --no-preserve=mode "${originalPackage.${outputName}}" "''$${outputName}"
                set +x
              ''
            )
            (old.outputs or ["out"])
          )
      }

      # Change `Exec` in the desktop entry to insert an env variable forcing wayland for QT5
      # Make the file to be not a symlink by full copying using `install` first.
      # This also makes it writable (files in the nix store have `chmod -w`).
      install -v "${originalPackage}"/share/applications/svp-manager4.desktop "$out"/share/applications/svp-manager4.desktop
      sed -i -e 's/Exec=/Exec=env QT_QPA_PLATFORM=wayland /g' "$out"/share/applications/svp-manager4.desktop
    '';
  });
in
  svpOverridenWayland