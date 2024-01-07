{
  description = "Volodia P.-G'.s system config";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    srvos = {
      url = "github:nix-community/srvos";
      # Use the version of nixpkgs that has been tested to work with SrvOS
      # Alternativly we also support the latest nixos release and unstable
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    # nix-software-center.url = "github:vlinkz/nix-software-center";
    # nix-conf-editor.url = "github:vlinkz/nixos-conf-editor";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    impermanence.url = "github:nix-community/impermanence";
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
      overlays = with inputs; [
        nur-xddxdd.overlay
        nur-volodiapg.overlay
        peerix.overlay
      ];
      #++ import ./lib/overlays.nix;

      pkgsFor = nixpkgs_type: system:
        import nixpkgs_type {
          inherit overlays system;
          config.allowUnfree = true;
        };
      specialArgsFor = system: {
        inherit overlays;
        pkgs-unstable = pkgsFor nixpkgs-unstable system;
      };
    in
      nixpkgs.lib.foldl nixpkgs.lib.recursiveUpdate {}
      [
        (flake-utils.lib.eachDefaultSystem (system: let
          defaultModules =
            [
              {
                # Inherit everyhting we can from the flake
                environment.etc = {
                  "nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
                  "nix/inputs/self".source = "${inputs.self}";
                };
                # nix.settings = {
                #   # Pin channels to flake inputs.
                #   # registry.nixpkgs.flake = inputs.nixpkgs;
                #   # registry.self.flake = inputs.self;

                #   # substituters = self.substituters;
                #   # trusted-public-keys = self.trusted-public-keys;
                # };
                nixpkgs.overlays = overlays;

                system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

                # system.autoUpgrade.flake = "github:volodiapg/nixos-configs";
              }
              ./modules
            ]
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) ./modules/linux)
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) impermanence.nixosModules.impermanence)
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) {
              services.autoUpgrade = {
                enable = true;
                flakeURL = "github:volodiapg/nixos-configs";
                inherit inputs;
              };
            })
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "darwin" system) ./modules/darwin);
        in {
          nixosModules.default = defaultModules;
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
                }
              )
            );
        }))
        (flake-utils.lib.eachSystem ["x86_64-linux"] (system: {
          # Do not forget to also add to peerix to share the derivations
          packages.nixosConfigurations = {
            # "asus" = nixpkgs.lib.nixosSystem {
            #   inherit system;
            #   specialArgs = specialArgsFor system;
            #   modules =
            #     outputs.nixosModules.${system}.default
            #     ++ (with inputs; [
            #       ./machines/asus/hardware-configuration.nix
            #       ./machines/asus/configuration.nix
            #       nixos-hardware.nixosModules.common-cpu-intel
            #       nixos-hardware.nixosModules.common-cpu-intel-cpu-only
            #       nixos-hardware.nixosModules.common-cpu-intel-kaby-lake
            #       nixos-hardware.nixosModules.common-gpu-intel
            #       nixos-hardware.nixosModules.common-pc
            #       nixos-hardware.nixosModules.common-pc-laptop
            #       nixos-hardware.nixosModules.common-pc-laptop-acpi_call
            #       nixos-hardware.nixosModules.common-pc-laptop-ssd
            #     ]);
            # };
            # "msi" = nixpkgs.lib.nixosSystem {
            #   inherit system;
            #   specialArgs = specialArgsFor system;
            #   modules =
            #     outputs.nixosModules.${system}.default
            #     ++ (with inputs; [
            #       ./machines/msi/hardware-configuration.nix
            #       ./machines/msi/configuration.nix
            #       nixos-hardware.nixosModules.common-cpu-intel
            #       nixos-hardware.nixosModules.common-cpu-intel-cpu-only
            #       nixos-hardware.nixosModules.common-pc
            #       nixos-hardware.nixosModules.common-pc-ssd
            #       nixos-hardware.nixosModules.common-pc-hdd
            #     ]);
            # };
            "home-server" = nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = specialArgsFor system;
              modules =
                outputs.nixosModules.${system}.default
                ++ (with inputs; [
                  ./machines/home-server/hardware-configuration.nix
                  ./machines/home-server/confwiguration.nix
                  nixos-hardware.nixosModules.common-cpu-intel
                  nixos-hardware.nixosModules.common-cpu-intel-cpu-only
                  nixos-hardware.nixosModules.common-pc
                  nixos-hardware.nixosModules.common-pc-ssd
                  nixos-hardware.nixosModules.common-pc-hdd
                  srvos.nixosModules.server
                ]);
            };
            "dell" = nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = specialArgsFor system;
              modules =
                outputs.nixosModules.${system}.default
                ++ (with inputs; [
                  ./machines/dell/configuration.nix
                  ./machines/dell/hardware-configuration.nix
                  nixos-hardware.nixosModules.common-cpu-intel
                  nixos-hardware.nixosModules.common-cpu-intel-cpu-only
                  nixos-hardware.nixosModules.common-gpu-intel
                  nixos-hardware.nixosModules.common-pc
                  nixos-hardware.nixosModules.common-pc-laptop
                  nixos-hardware.nixosModules.common-pc-laptop-acpi_call
                  nixos-hardware.nixosModules.common-pc-laptop-ssd
                  vscode-server.nixosModules.default
                  #srvos.nixosModules.server
                  {
                    services = {
                      desktop.enable = true;
                      kernel.enable = true;
                      intel.enable = true;
                      impermanence.enable = true;
                      impermanence.rootVolume = "nvme0n1p11";
                      elegantBoot.enable = false;
                      vpn.enable = true;
                      vscode-server.enable = true;
                    };
                  }
                ]);
            };
          };
        }))
        (flake-utils.lib.eachSystem ["x86_64-darwin" "aarch64-darwin"] (
          system: let
            inherit (darwin.lib) darwinSystem;
            # pkgs = nixpkgs-darwin.legacyPackages.${system};
            # linuxSystem = builtins.replaceStrings ["darwin"] ["linux"] system;
          in {
            packages.darwinConfigurations."Volodias-MacBook-Pro" = darwinSystem {
              inherit system;
              modules =
                outputs.nixosModules.${system}.default
                ++ [
                  {
                    nixpkgs.hostPlatform = system;

                    nix = {
                      settings = {
                        substituters = [
                          "https://cache.nixos.org/"
                        ];
                        trusted-public-keys = [
                          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                        ];
                      };
                      configureBuildUsers = true;

                      linux-builder = {
                        enable = true;
                        maxJobs = 4;
                      };
                    };

                    launchd.daemons.linux-builder.serviceConfig = {
                      StandardOutPath = "/var/log/linux-builder.log";
                      StandardErrorPath = "/var/log/linux-builder.log";
                    };

                    system.activationScripts.extraActivation.text = ''
                      /usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license
                    '';

                    services.nix-daemon.enable = true;

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
