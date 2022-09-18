# https://www.tweag.io/blog/2020-07-31-nixos-flakes/

# To switch from channels to flakes execute:
# cd /etc/nixos
# sudo wget -O flake.nix https://gist.githubusercontent.com/misuzu/80af74212ba76d03f6a7a6f2e8ae1620/raw/flake.nix
# sudo git init
# sudo git add . # won't work without this
# nix-shell -p nixFlakes --run "sudo nix --experimental-features 'flakes nix-command' build .#nixosConfigurations.$(hostname).config.system.build.toplevel"
# sudo ./result/bin/switch-to-configuration switch

# Now nixos-rebuild can use flakes:
# sudo nixos-rebuild switch --flake /etc/nixos

# To update flake.lock run:
# sudo nix flake update --commit-lock-file /etc/nixos

{
  description = "Volodia P.-G'.s system config";

  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # flake-utils.url = "github:numtide/flake-utils";
    # nur.url = "github:nix-community/NUR";
    # nur = {
    #   # url = "github:xddxdd/nur-packages";
    #   url = "github:nix-community/NUR";
    #   # inputs.flake-utils.follows = "flake-utils";
    #   # inputs.nixpkgs.follows = "nixpkgs";
    # };
    nur-xddxdd = {
      url = "github:xddxdd/nur-packages";
      # inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.utils.follows = "flake-utils";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    vs-overlay.url = "github:volodiapg/vs-overlay";

  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      mkMachine = import ./lib/mkMachine.nix;
      
      system = "x86_64-linux";
      user = "volodia";
      overlays = import ./lib/overlays.nix ++ (with inputs; [
        vs-overlay.overlay
        nur-xddxdd.overlay
      ]);

      modules-additionnal-sources = [
        # inputs.nur.nixosModules.nur
      ];
    in
    {
      nixosConfigurations.ux430ua = mkMachine "ux430ua" {
        inherit nixpkgs home-manager system overlays user;
        additionnal-modules = modules-additionnal-sources ++ (with inputs; [
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-cpu-intel-cpu-only
          nixos-hardware.nixosModules.common-cpu-intel-kaby-lake
          nixos-hardware.nixosModules.common-gpu-intel
          nixos-hardware.nixosModules.common-pc
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.common-pc-laptop-acpi_call
          nixos-hardware.nixosModules.common-pc-laptop-ssd
        ]);
      };
      nixosConfigurations.msi = mkMachine "msi" {
        inherit nixpkgs home-manager system overlays user;
        additionnal-modules = modules-additionnal-sources ++ (with inputs;[
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-cpu-intel-cpu-only
          nixos-hardware.nixosModules.common-pc
          nixos-hardware.nixosModules.common-pc-ssd
          nixos-hardware.nixosModules.common-pc-hdd
        ]);
      };
    };
}
