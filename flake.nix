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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";
    mosh.url = "github:mobile-shell/mosh";
    mosh.flake = false;
  };

  outputs = inputs:
    with inputs; let
      inherit (self) outputs;
      mosh-overlay = _final: prev: {
        mosh =
          prev.mosh.overrideAttrs
          (old: let
            # Remove a patch already merged in master
            patches =
              nixpkgs.lib.lists.remove (prev.fetchpatch {
                url = "https://github.com/mobile-shell/mosh/commit/eee1a8cf413051c2a9104e8158e699028ff56b26.patch";
                hash = "sha256-CouLHWSsyfcgK3k7CvTK3FP/xjdb1pfsSXYYQj3NmCQ=";
              })
              old.patches;
          in {
            inherit patches;
            src = inputs.mosh;
          });
      };

      overlays = with inputs; [
        nur-xddxdd.overlay
        nur-volodiapg.overlay
        peerix.overlay
        mosh-overlay
      ];

      pkgsFor = nixpkgs_type: system:
        import nixpkgs_type {
          inherit overlays system;
          config.allowUnfree = true;
        };
      specialArgsFor = system: username: {
        inherit overlays;
        pkgs-unstable = pkgsFor nixpkgs-unstable system;
        inherit inputs;
        homeDirectory =
          if nixpkgs.lib.strings.hasSuffix "linux" system
          then "/home/${username}"
          else "/Users/${username}";
        inherit username;
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
                nix = {
                  # Pin channels to flake inputs.
                  # registry.nixpkgs.flake = inputs.nixpkgs;
                  registry.self.flake = inputs.self;
                };
                nixpkgs.overlays = overlays;

                system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
              }
              ./modules
            ]
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) ./secrets/nixos.nix)
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) sops-nix.nixosModules.sops)
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) ./modules/linux)
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) home-manager.nixosModules.home-manager)
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) impermanence.nixosModules.impermanence)
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) {
              services.autoUpgrade = {
                enable = true;
                flakeURL = "github:volodiapg/nixos-configs";
                inherit inputs;
              };
              home-manager = {
                users.volodia = import ./users/volodia/home.nix;
                useGlobalPkgs = true;
                useUserPackages = true;
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                  ./secrets/home-manager.nix
                ];
                extraSpecialArgs =
                  (specialArgsFor system "volodia")
                  // {
                    graphical = "no-de";
                    apps = "no-apps";
                  };
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
                  name = with settings; "${username}.${graphical}.${apps}.${machine}";
                  value = home-manager.lib.homeManagerConfiguration (
                    with settings; let
                      pkgs = pkgsFor nixpkgs system;
                      specialArgs = specialArgsFor system username; # // (nixpkgs.lib.mkIf (machine != "no-machine") {nixosConfig = nixosConfigurations."${machine}".config;});
                    in {
                      inherit pkgs;
                      modules = [
                        sops-nix.homeManagerModules.sops
                        ./secrets/home-manager.nix
                        ./users/volodia/home.nix
                      ];
                      extraSpecialArgs = specialArgs // {inherit (settings) graphical apps;};
                    }
                  );
                }
              )
              (
                nixpkgs.lib.attrsets.cartesianProductOfSets
                {
                  username = ["volodia" "volparolguarino"];
                  graphical = ["no-de" "gnome"];
                  apps = ["no-apps" "work" "personal"];
                  machine = ["no-machine" "dell"];
                }
              )
            );
        }))
        (flake-utils.lib.eachSystem ["x86_64-linux"] (system: {
          # Do not forget to also add to peerix to share the derivations
          packages.nixosConfigurations = {
            "home-server" = nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = specialArgsFor system "volodia";
              modules =
                outputs.nixosModules.${system}.default
                ++ (with inputs; [
                  ./machines/home-server/hardware-configuration.nix
                  ./machines/home-server/configuration.nix
                  ./machines/home-server/disk.nix
                  nixos-hardware.nixosModules.common-cpu-intel
                  nixos-hardware.nixosModules.common-cpu-intel-cpu-only
                  nixos-hardware.nixosModules.common-pc
                  nixos-hardware.nixosModules.common-pc-ssd
                  nixos-hardware.nixosModules.common-pc-hdd
                  srvos.nixosModules.server
                  disko.nixosModules.disko
                  {
                    _module.args.disks = ["/dev/sda"];
                    services = {
                      desktop.enable = false;
                      kernel.enable = true;
                      intel.enable = true;
                      impermanence = {
                        enable = true;
                        rootVolume = "sda";
                        disko = true;
                      };
                      elegantBoot.enable = false;
                      vpn.enable = true;
                      laptopServer.enable = true;
                    };
                  }
                ]);
            };
            "dell" = nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = specialArgsFor "${system}" "volodia";
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
                  srvos.nixosModules.server
                  ({config, ...}: {
                    services = {
                      desktop.enable = false;
                      kernel.enable = true;
                      intel.enable = true;
                      impermanence = {
                        enable = true;
                        rootVolume = "nvme0n1p11";
                      };
                      elegantBoot.enable = false;
                      vpn.enable = true;
                      vscode-server = {
                        enable = true;
                      };
                      laptopServer.enable = true;
                      changeMAC = {
                        enable = true;
                        mac = config.sops.secrets.dellmac.path;
                        interface = "enp0s31f6";
                      };
                    };
                  })
                ]);
            };
          };
        }))
        (flake-utils.lib.eachSystem ["x86_64-darwin" "aarch64-darwin"] (
          system: let
            inherit (darwin.lib) darwinSystem;
          in {
            packages.darwinConfigurations."Volodias-MacBook-Pro" = darwinSystem {
              inherit system;
              specialArgs = specialArgsFor "${system}" "volodia";
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
                actionlint.enable = true;
              };
            };

            devShells.default = pkgs.mkShell {
              inherit
                (outputs.checks.${system}.pre-commit-check)
                shellHook
                ;
              packages =
                (with pkgs; [just git git-crypt sops home-manager])
                ++ (nixpkgs.lib.lists.optional pkgs.stdenv.isDarwin [darwin.packages.${system}.darwin-rebuild]);
            };
          }
        ))
      ];
}
