{
  description = "Volodia P.-G'.s system config";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nur-xddxdd = {
      url = "github:xddxdd/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-volodiapg = {
      url = "github:volodiapg/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    peerix = {
      url = "github:volodiapg/peerix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    # nix-software-center.url = "github:vlinkz/nix-software-center";
    # nix-conf-editor.url = "github:vlinkz/nixos-conf-editor";
    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = "https://cache.nixos.org https://nix-community.cachix.org https://volodiapg.cachix.org";
    extra-trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI=";
  };

  outputs = inputs:
    with inputs; let
      system = "x86_64-linux";

      overlays =
        (with inputs; [
          nur-xddxdd.overlay
          nur-volodiapg.overlay
          peerix.overlay
        ])
        ++ import ./lib/overlays.nix;

      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system overlays;
        config.allowUnfree = true;
      };

      specialArgs = {
        inherit pkgs-unstable overlays;
      };
      # homeManagerModule = {
      #   nix.registry.self.flake = inputs.self;
      #   home-manager.users.volodia = import ./users/volodia/home.nix;
      #   home-manager.useGlobalPkgs = false;
      #   home-manager.useUserPackages = true;
      #   home-manager.extraSpecialArgs = {
      #     inherit pkgs-unstable overlays;
      #   };
      # };
      # home-manager.nixosModules.home-manager
      defaultModules = [
        {
          nix.registry.self.flake = inputs.self;
          nixpkgs.overlays = overlays;
        }
        inputs.nur-xddxdd.nixosModules.setupOverlay
        {
          environment.systemPackages = [
            # inputs.nix-software-center.packages.${system}.nix-software-center
            # inputs.nix-conf-editor.packages.${system}.nixos-conf-editor
          ];
        }
        inputs.peerix.nixosModules.peerix
        ./modules
      ];
      # hmConfigurations =
      # builtins.listToAttrs
      #       (
      #         builtins.map
      #           (
      #             graphical:
      #             home-manager.lib.homeManagerConfiguration {
      #               inherit pkgs;
      #               modules = [./users/volodia/home.nix];
      #               extraSpecialArgs = specialArgs // { inherit graphical; };
      #             }
      #           )
      #           ["gnome" "none"]
      #       );
    in
      {
        # homeConfigurations."volodia" = home-manager.lib.homeManagerConfiguration {
        #   inherit pkgs;
        #   modules = [./users/volodia/home.nix];
        #   extraSpecialArgs = specialArgs;
        # };
        # homeConfigurations."volodia.gnome" = hmConfigurations.gnome;
        # homeConfigurations."volodia.none" = hmConfigurations.none;
        homeConfigurations =
          builtins.listToAttrs
          (
            builtins.map
            (
              graphical: {
                name = "volodia.${graphical}";
                value = home-manager.lib.homeManagerConfiguration {
                  inherit pkgs;
                  modules = [./users/volodia/home.nix];
                  extraSpecialArgs = specialArgs // {inherit graphical;};
                };
              }
            )
            ["default" "gnome"]
          );
        # Do not forget to also add to peerix to share the derivations
        nixosConfigurations."asus" = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules =
            defaultModules
            ++ (with inputs; [
              ./machines/asus/hardware-configuration.nix
              ./machines/asus/configuration.nix
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
        nixosConfigurations."msi" = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules =
            defaultModules
            ++ (with inputs; [
              ./machines/msi/hardware-configuration.nix
              ./machines/msi/configuration.nix
              nixos-hardware.nixosModules.common-cpu-intel
              nixos-hardware.nixosModules.common-cpu-intel-cpu-only
              nixos-hardware.nixosModules.common-pc
              nixos-hardware.nixosModules.common-pc-ssd
              nixos-hardware.nixosModules.common-pc-hdd
            ]);
        };
        # nixosConfigurations.dell = mkMachine "dell" {
        #   inherit nixpkgs pkgs pkgs-unstable home-manager system user;
        #   additionnal-modules = modules-additionnal-sources ++ (with inputs;[
        #     nixos-hardware.nixosModules.common-cpu-intel
        #     nixos-hardware.nixosModules.common-cpu-intel-cpu-only
        #     nixos-hardware.nixosModules.common-gpu-intel
        #     nixos-hardware.nixosModules.common-pc
        #     nixos-hardware.nixosModules.common-pc-laptop
        #     nixos-hardware.nixosModules.common-pc-laptop-acpi_call
        #     nixos-hardware.nixosModules.common-pc-laptop-ssd
        #   ]);
        # };
      }
      // flake-utils.lib.eachDefaultSystem (
        system: {
          formatter = alejandra.defaultPackage.${system};

          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                alejandra.enable = true;
                statix.enable = true;
                deadnix.enable = true;
                commitizen.enable = true;
              };
            };
          };

          devShell = nixpkgs.legacyPackages.${system}.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = with pkgs-unstable; [just git git-crypt home-manager];
          };
        }
      );
}
