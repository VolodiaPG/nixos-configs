{
  description = "Volodia P.-G'.s system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur-xddxdd = {
      url = "github:xddxdd/nur-packages";
    };
    nur-volodiapg = {
      url = "github:volodiapg/nur-packages";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    peerix = {
      url = "github:cid-chan/peerix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  nixConfig = {
    extra-substituters = "https://cache.nixos.org https://nix-community.cachix.org https://volodiapg.cachix.org";
    extra-trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI=";
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks, home-manager, ... }@inputs:
    let
      mkMachine = import ./lib/mkMachine.nix;

      system = "x86_64-linux";
      user = "volodia";

      overlays = (with inputs; [
        nur-xddxdd.overlay
        nur-volodiapg.overlay
        peerix.overlay
      ]) ++ import ./lib/overlays.nix;

      modules-additionnal-sources = with inputs;
        [
          peerix.nixosModules.peerix
        ];

      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.ux430ua-nixos = mkMachine "ux430ua" {
        inherit nixpkgs pkgs home-manager system overlays user;
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
      nixosConfigurations.msi-nixos = mkMachine "msi" {
        inherit nixpkgs pkgs home-manager system overlays user;
        additionnal-modules = modules-additionnal-sources ++ (with inputs;[
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-cpu-intel-cpu-only
          nixos-hardware.nixosModules.common-pc
          nixos-hardware.nixosModules.common-pc-ssd
          nixos-hardware.nixosModules.common-pc-hdd
        ]);
      };
      nixosConfigurations.hralaptop-nixos = mkMachine "hralaptop" {
        inherit nixpkgs pkgs home-manager system overlays user;
        additionnal-modules = modules-additionnal-sources ++ (with inputs;[
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-cpu-intel-cpu-only
          nixos-hardware.nixosModules.common-gpu-intel
          nixos-hardware.nixosModules.common-pc
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.common-pc-laptop-acpi_call
          nixos-hardware.nixosModules.common-pc-laptop-ssd
        ]);
      };
      nixosConfigurations.precision-3571-nixos = mkMachine "precision-3571" {
        inherit nixpkgs pkgs home-manager system overlays user;
        additionnal-modules = modules-additionnal-sources ++ (with inputs;[
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-cpu-intel-cpu-only
          nixos-hardware.nixosModules.common-gpu-intel
          nixos-hardware.nixosModules.common-pc
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.common-pc-laptop-acpi_call
          nixos-hardware.nixosModules.common-pc-laptop-ssd
        ]);
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      {
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
            };
          };
        };

        devShell = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = with pkgs; [ just ];
        };
      }
    );
}
