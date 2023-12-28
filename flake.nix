{
  description = "Volodia P.-G'.s system config";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  nixConfig = {
    # extra-substituters = "https://cache.nixos.org https://nix-community.cachix.org https://volodiapg.cachix.org";
    # extra-trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI=";
    substituters = "https://cache.nixos.org";
    trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
  };

  outputs = inputs:
    with inputs; let
      inherit (self) outputs;
      # system = if system_raw == "aarch64-darwin" then "x86_64-darwin" else system;
    in
      nixpkgs.lib.foldl nixpkgs.lib.recursiveUpdate {}
      [
        (flake-utils.lib.eachDefaultSystem (system: let
          overlays =
            (with inputs; [
              nur-xddxdd.overlay
              nur-volodiapg.overlay
              peerix.overlay
            ])
            ++ import ./lib/overlays.nix;

          pkgsFor = nixpkgs_type: system:
            import nixpkgs_type {
              inherit overlays system;
              config.allowUnfree = true;
            };
          specialArgsFor = system: {
            inherit overlays;
            pkgs-unstable = pkgsFor nixpkgs-unstable system;
          };

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
        in {
          # Configurations, option are obtained by .#volodia.<de>.<apps>
          packages.homeConfigurations =
            builtins.listToAttrs
            (
              builtins.map
              (
                settings: {
                  name = "volodia.${settings.graphical}.${settings.apps}";
                  # value = home-manager.lib.homeManagerConfiguration (flake-utils.lib.eachDefaultSystem (
                  value = home-manager.lib.homeManagerConfiguration (
                    with settings; let
                      pkgs = pkgsFor nixpkgs system;
                      specialArgs = specialArgsFor system;
                    in {
                      inherit pkgs;
                      # inherit (pkgs) lib;
                      modules = [./users/volodia/home.nix];
                      extraSpecialArgs = specialArgs // {inherit (settings) graphical apps;};
                    }
                  );
                }
              )
              (
                nixpkgs.lib.attrsets.cartesianProductOfSets
                {
                  graphical = ["no-de" "gnome"];
                  apps = ["no-apps" "work" "personal"];
                  # system = ["x86_64-linux" "aarch64-darwin"];
                }
              )
            );
          # Do not forget to also add to peerix to share the derivations
          nixosConfigurations."asus" = let
            system = "x86_64-linux";
          in
            nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = specialArgsFor system;
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
          nixosConfigurations."msi" = let
            system = "x86_64-linux";
          in
            nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = specialArgsFor system;
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
        }))
        (flake-utils.lib.eachSystem ["x86_64-darwin" "aarch64-darwin"] (
          system: let
            inherit (darwin.lib) darwinSystem;
            pkgs = nixpkgs-darwin.legacyPackages.${system};
            linuxSystem = builtins.replaceStrings ["darwin"] ["linux"] system;
          in {
            packages.darwinConfigurations."Volodias-MacBook-Pro" = darwinSystem {
              inherit system;
              modules = [
                {
                  nixpkgs.hostPlatform = system;

                  nix.settings.substituters = [
                    "https://cache.nixos.org/"
                  ];
                  nix.settings.trusted-public-keys = [
                    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  ];
                  nix.settings.allowed-users = ["root" "volodia" "@admin"];
                  nix.settings.trusted-users = ["root" "volodia" "@admin"];

                  nix.configureBuildUsers = true;

                  nix.linux-builder.enable = true;
                  nix.linux-builder.maxJobs = 4;

                  launchd.daemons.linux-builder.serviceConfig.StandardOutPath = "/var/log/linux-builder.log";
                  launchd.daemons.linux-builder.serviceConfig.StandardErrorPath = "/var/log/linux-builder.log";

                  # virtualisation.rosetta.enable = true;
                  system.activationScripts.extraActivation.text = ''
                    softwareupdate --install-rosetta --agree-to-license
                  '';

                  environment.systemPackages = [
                    # pkgs.fish
                    pkgs.direnv
                    pkgs.alacritty
                  ];

                  # environment.loginShell = pkgs.fish;
                  nix.package = pkgs.nix;
                  nix.settings.experimental-features = "nix-command flakes";
                  nix.settings.auto-optimise-store = true;
                  nix.settings.keep-outputs = true;
                  nix.settings.keep-derivations = true;
                  nix.settings.warn-dirty = false;
                  nix.settings.build-users-group = "nixbld";
                  nix.settings.builders-use-substitutes = true;
                  nix.settings.max-jobs = "auto";
                  nix.settings.cores = 0;
                  nix.settings.log-lines = 50;

                  # programs.fish.enable = true;
                  # programs.zsh.enable = true;

                  # Auto upgrade nix package and the daemon service.
                  services.nix-daemon.enable = true;
                  # programs.nix-index.enable = true;
                  # Add ability to used TouchID for sudo authentication
                  security.pam.enableSudoTouchIdAuth = true;
                }
              ];
            };
          }
        ))
        (flake-utils.lib.eachDefaultSystem (
          system: let
            pkgs = nixpkgs.legacyPackages.${system};
          in {
            formatter = pkgs.alejandra;

            checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                alejandra.enable = true;
                statix.enable = true;
                deadnix.enable = true;
                commitizen.enable = true;
              };
            };

            devShells.default = pkgs.mkShell {
              inherit
                (outputs.checks.${system}.pre-commit-check)
                shellHook
                ;
              packages =
                (with pkgs; [just git git-crypt home-manager])
                ++ (nixpkgs.lib.lists.optional pkgs.stdenv.isDarwin [darwin.packages.${system}.darwin-rebuild]);
            };
          }
        ))
      ];
}
