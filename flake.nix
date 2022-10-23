{
  description = "Volodia P.-G'.s system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur-xddxdd = {
      url = "github:xddxdd/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
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

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks, home-manager, ... }@inputs:
    let
      mkMachine = import ./lib/mkMachine.nix;

      system = "x86_64-linux";
      user = "volodia";

      overlays = import ./lib/overlays.nix ++ (with inputs; [
        nur-xddxdd.overlay
        peerix.overlay
      ]);

      modules-additionnal-sources = with inputs;[
        peerix.nixosModules.peerix
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
      };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      nixosConfigurations.ux430ua-nixos = mkMachine "ux430ua" {
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
      nixosConfigurations.msi-nixos = mkMachine "msi" {
        inherit nixpkgs home-manager system overlays user;
        additionnal-modules = modules-additionnal-sources ++ (with inputs;[
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-cpu-intel-cpu-only
          nixos-hardware.nixosModules.common-pc
          nixos-hardware.nixosModules.common-pc-ssd
          nixos-hardware.nixosModules.common-pc-hdd
        ]);
      };
      nixosConfigurations.hralaptop-nixos = mkMachine "hralaptop" {
        inherit nixpkgs home-manager system overlays user;
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
