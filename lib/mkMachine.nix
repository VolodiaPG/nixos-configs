# This function creates a NixOS system based on our VM setup for a
# particular architecture.
name: {
  nixpkgs,
  pkgs,
  home-manager,
  system,
  user,
  additionnal-modules,
}:
nixpkgs.lib.nixosSystem rec {
  inherit system pkgs;

  modules =
    additionnal-modules
    ++ [
      # # Apply our overlays. Overlays are keyed by system type so we have
      # # to go through and apply our system type. We do this first so
      # # the overlays are available globally.
      # {
      #   nixpkgs = {
      #     inherit overlays;
      #     config.allowUnfree = true;
      #   };
      # }

      ../machines/${name}/hardware-configuration.nix
      ../machines/${name}/configuration.nix

      ../modules/kernel.nix
      ../modules/intel.nix
      ../modules/btrfs.nix
      ../modules/elegant-boot.nix

      ../modules/peerix.nix

      ../modules/common.nix
      ../modules/desktop.nix
      ../modules/vpn.nix
      ../modules/gaming.nix

      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = import ../users/${user}/home.nix;
        };
      }

      # We expose some extra arguments so that our modules can parameterize
      # better based on these values.
      {
        config._module.args = {
          currentSystemName = name;
          currentSystem = system;
        };
      }
    ];
}
