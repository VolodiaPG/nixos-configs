{
  description = "Volodia P.-G'.s system config";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    nixpkgs-unstable.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
    };
    vim.url = "github:volodiapg/vim";
    impermanence.url = "github:nix-community/impermanence";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";
    mosh = {
      url = "github:zhaofengli/mosh/fish-wcwidth";
      flake = false;
    };
    # yabai = {
    #   flake = false;
    #   url = "https://github.com/koekeishiya/yabai/releases/download/v7.1.15/yabai-v7.1.15.tar.gz";
    # };
    catppuccin.url = "github:catppuccin/nix";
    hosts = {
      url = "github:StevenBlack/hosts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
    deploy-rs.url = "github:volodiapg/deploy-rs";
  };

  nixConfig = {
    extra-substituters = [
      "https://volodiapg.cachix.org"
      "https://giraff.cachix.org"
      "https://vim.cachix.org"
      "https://install.determinate.systems"
    ];
    extra-trusted-public-keys = [
      "volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI="
      "giraff.cachix.org-1:3sol29PSsWCh/7bAiRze+5Zq6OML02FDRH13K5i3qF4="
      "vim.cachix.org-1:csyY4pnUgltVSD3alxSV6zZG/lRD7FQBfl4K4RNBgXA="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
  };

  outputs =
    inputs:
    with inputs;
    let
      inherit (self) outputs;
      mosh-overlay = _final: prev: {
        mosh = prev.mosh.overrideAttrs (
          old:
          let
            # Remove a patch already merged in master
            patches = nixpkgs.lib.lists.remove (prev.fetchpatch {
              url = "https://github.com/mobile-shell/mosh/commit/eee1a8cf413051c2a9104e8158e699028ff56b26.patch";
              hash = "sha256-CouLHWSsyfcgK3k7CvTK3FP/xjdb1pfsSXYYQj3NmCQ=";
            }) old.patches;
          in
          {
            inherit patches;
            src = inputs.mosh;
          }
        );
      };

      overlays = with inputs; [
        mosh-overlay
        vim.overlay
      ];

      pkgsFor =
        nixpkgs_type: system:
        import nixpkgs_type {
          inherit overlays system;
          config.allowUnfree = true;
        };
      specialArgsFor = system: username: hostName: {
        inherit overlays;
        inherit hostName;
        pkgs-unstable = pkgsFor nixpkgs-unstable system;
        inherit inputs;
        symlinkPath = null;
        homeDirectory =
          if nixpkgs.lib.strings.hasSuffix "linux" system then "/home/${username}" else "/Users/${username}";
        inherit username;
      };
    in
    nixpkgs.lib.foldl nixpkgs.lib.recursiveUpdate { } [
      (flake-utils.lib.eachDefaultSystem (
        system:
        let
          defaultModules = [
            (
              { hostName, ... }:
              {
                # Inherit everything we can from the flake
                environment.etc = {
                  "nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
                  "nix/inputs/self".source = "${inputs.self}";
                };
                nix = {
                  # Pin channels to flake inputs.
                  # registry.nixpkgs.flake = inputs.nixpkgs;
                  registry.self.flake = inputs.nixpkgs;
                };
                nixpkgs.overlays = overlays;

                system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

                home-manager = {
                  users.volodia = import ./users/volodia/home.nix;
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  sharedModules = [
                    ./secrets/home-manager.nix
                    agenix.homeManagerModules.default
                    catppuccin.homeModules.catppuccin
                  ];
                  extraSpecialArgs = specialArgsFor system "volodia" hostName;
                };
              }
            )
            ./modules
            ./secrets/nixos.nix
          ]
          ++ [ determinate.nixosModules.default ]
          ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) agenix.nixosModules.default)
          ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) ./modules/linux)
          ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) home-manager.nixosModules.home-manager)
          ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "darwin" system) home-manager.darwinModules.home-manager)
          ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) impermanence.nixosModules.impermanence)
          ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) catppuccin.nixosModules.catppuccin)
          ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "darwin" system) ./modules/darwin)
          ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "darwin" system) agenix.darwinModules.default)
          ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "darwin" system) mac-app-util.darwinModules.default);
        in
        {
          nixosModules.default = defaultModules;
          # Configurations, option are obtained by .#volodia.<de>.<apps>

          homeConfigurations = builtins.listToAttrs (
            builtins.map
              (settings: {
                name = with settings; "${username}.${graphical}.${apps}.${machine}";
                value = home-manager.lib.homeManagerConfiguration (
                  with settings;
                  let
                    pkgs = pkgsFor nixpkgs system;
                    specialArgs = specialArgsFor system username; # // (nixpkgs.lib.mkIf (machine != "no-machine") {nixosConfig = nixosConfigurations."${machine}".config;});
                  in
                  {
                    inherit pkgs;
                    modules = [
                      catppuccin.homeModules.catppuccin
                      agenix.homeManagerModules.default
                      ./secrets/home-manager.nix
                      ./users/volodia/home.nix
                    ]
                    ++ (nixpkgs.lib.optional pkgs.stdenv.isDarwin mac-app-util.homeManagerModules.default);
                    extraSpecialArgs = specialArgs // {
                      inherit (settings) graphical apps;
                    };
                  }
                );
              })
              (
                nixpkgs.lib.attrsets.cartesianProductOfSets {
                  username = [
                    "volodia"
                    "volparolguarino"
                  ];
                  graphical = [
                    "no-de"
                    "gnome"
                  ];
                  apps = [
                    "no-apps"
                    "work"
                    "personal"
                  ];
                  machine = [
                    "no-machine"
                    "dell"
                    "msi"
                    "Volodias-MacBook-Pro"
                  ];
                }
              )
          );
        }
      ))
      {
        # Do not forget to also add to peerix to share the derivations
        nixosConfigurations =
          let
            system = "x86_64-linux";
          in
          {
            "home-server" = nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = specialArgsFor system "volodia" "home-server";
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
                  srvos.nixosModules.server
                  disko.nixosModules.disko
                  {
                    _module.args.disks = [ "/dev/sda" ];
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
                    home-manager.extraSpecialArgs = {
                      graphical = "no-de";
                      apps = "no-apps";
                    };
                  }
                ]);
            };
            "msi" = nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = specialArgsFor "${system}" "volodia" "msi";
              modules =
                outputs.nixosModules.${system}.default
                ++ (with inputs; [
                  ./machines/msi/configuration.nix
                  ./machines/msi/hardware-configuration.nix
                  nixos-hardware.nixosModules.common-cpu-intel
                  nixos-hardware.nixosModules.common-gpu-nvidia
                  nixos-hardware.nixosModules.common-pc
                  nixos-hardware.nixosModules.common-pc-ssd
                  {
                    services = {
                      desktop.enable = true;
                      kernel.enable = true;
                      intel.enable = true;
                      impermanence = {
                        enable = true;
                        rootVolume = "disk/by-label/root";
                      };

                      elegantBoot.enable = false;
                      vpn.enable = true;
                    };
                    home-manager.extraSpecialArgs = {
                      graphical = "gnome";
                      apps = "personal";
                    };
                  }
                ]);
            };

            "dell" = nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = specialArgsFor "${system}" "volodia" "dell";
              modules =
                outputs.nixosModules.${system}.default
                ++ (with inputs; [
                  ./machines/dell/configuration.nix
                  ./machines/dell/hardware-configuration.nix
                  nixos-hardware.nixosModules.common-cpu-intel-cpu-only
                  nixos-hardware.nixosModules.common-gpu-intel
                  nixos-hardware.nixosModules.common-pc
                  nixos-hardware.nixosModules.common-pc-laptop
                  nixos-hardware.nixosModules.common-pc-laptop-ssd
                  #srvos.nixosModules.server
                  {
                    services = {
                      nvidia.enable = true;
                      desktop.enable = false;
                      kernel.enable = true;
                      intel.enable = true;
                      impermanence = {
                        enable = true;
                        rootVolume = "nvme0n1p11";
                      };
                      elegantBoot.enable = false;
                      vpn.enable = true;
                      laptopServer.enable = true;
                    };
                    home-manager.extraSpecialArgs = {
                      graphical = "no-de";
                      apps = "personal";
                    };
                  }
                ]);
            };

            "nixos" = nixpkgs.lib.nixosSystem {
              system = "aarch64-linux";
              specialArgs = specialArgsFor "aarch64-linux" "volodia" "nixos";
              modules =
                outputs.nixosModules."aarch64-linux".default
                ++ [
                  ./machines/nixos/configuration.nix
                  ./machines/nixos/hardware-configuration.nix
                ]
                ++ [
                  (
                    { lib, ... }:
                    {
                      system.stateVersion = "25.05";
                      services = {
                        desktop.enable = true;
                        kernel.enable = true;
                        intel.enable = false;
                        impermanence.enable = false;
                        elegantBoot.enable = false;
                        vpn.enable = true;
                        laptopServer.enable = false;
                        thermald.enable = lib.mkForce false;
                      };
                      home-manager = {
                        sharedModules = [
                          ./secrets/home-manager.nix
                          agenix.homeManagerModules.default
                        ];
                        users.volodia.catppuccin.starship.enable = lib.mkForce false;
                        extraSpecialArgs = {
                          graphical = "gnome";
                          apps = "personal";
                        };
                      };
                    }
                  )
                ];
            };
          };
      }
      (flake-utils.lib.eachSystem [ "aarch64-darwin" ] (
        system:
        let
          inherit (darwin.lib) darwinSystem;
        in
        {
          packages.darwinConfigurationsFunctions."Volodias-MacBook-Pro" =
            {
              symlinkPath ? null,
            }:
            darwinSystem {
              inherit system;
              specialArgs = specialArgsFor "${system}" "volodia" "Volodias-MacBook-Pro";
              modules = outputs.nixosModules.${system}.default ++ [
                (
                  {
                    pkgs,
                    pkgs-unstable,
                    ...
                  }:
                  {
                    system = {
                      stateVersion = 5;
                      primaryUser = "volodia";
                    };
                    nixpkgs.hostPlatform = system;

                    home-manager.extraSpecialArgs = {
                      graphical = "no-de";
                      apps = "personal";
                      inherit symlinkPath;
                    };

                    users.users.volodia = {
                      name = "volodia";
                      home = "/Users/volodia";
                    };

                    programs = {
                      zsh.enable = true;
                    };

                    environment.systemPackages = with pkgs; [
                      terminal-notifier
                    ];

                    nix = {
                      settings = {
                        substituters = [
                          "https://cache.nixos.org/"
                        ];
                        trusted-public-keys = [
                          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                        ];
                      };
                      extraOptions = ''
                        extra-platforms = x86_64-darwin
                      '';

                      linux-builder = {
                        enable = true;
                        ephemeral = true;
                        maxJobs = 8;
                        supportedFeatures = [
                          "kvm"
                          "benchmark"
                          "big-parallel"
                        ];
                        systems = [
                          "aarch64-linux"
                          "x86_64-linux"
                        ];
                        config = {
                          # This can't include aarch64-linux when building on aarch64,
                          # for reasons I don't fully understand
                          boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
                          virtualisation = {
                            darwin-builder.diskSize = 60 * 1024;
                          };
                          nix.settings = {
                            substituters = [
                              "https://nix-community.cachix.org"
                            ];
                            trusted-public-keys = [
                              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                            ];
                          };
                        };
                      };
                    };

                    launchd.daemons.linux-builder.serviceConfig = {
                      StandardOutPath = "/var/log/linux-builder.log";
                      StandardErrorPath = "/var/log/linux-builder.log";
                    };

                    system.activationScripts.extraActivation.text = ''
                      /usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license
                    '';

                    services = {
                      yabai = {
                        enable = true;
                        package = pkgs-unstable.yabai;
                        # package = pkgs.yabai.overrideAttrs (_: {
                        #   version = "7.1.14";
                        #   src = inputs.yabai;
                        # });
                        # symlinked out of tree
                        # extraConfig = builtins.readFile ./users/volodia/packages/.yabairc;
                        enableScriptingAddition = true;
                      };
                      skhd = {
                        enable = true;
                        # symlinked out of tree
                        # skhdConfig = builtins.readFile ./users/volodia/packages/.skhdrc;
                      };
                    };

                    # Add ability to used TouchID for sudo authentication
                    security.pam.services.sudo_local = {
                      touchIdAuth = true;
                      reattach = true;
                    };
                  }
                )
              ];
            };
        }
      ))
      (flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = pkgsFor nixpkgs system;
        in
        {
          formatter = pkgs.nixfmt-tree;

          checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
              statix.enable = true;
              deadnix.enable = true;
              commitizen.enable = true;
              actionlint.enable = true;
            };
          };

          packages = {
            inherit (pkgs) mosh;
          };

          devShells.default = pkgs.mkShell {
            inherit (outputs.checks.${system}.pre-commit-check)
              shellHook
              ;
            packages =
              (with pkgs; [
                just
                alejandra
                git
                git-crypt
                age
                ssh-to-age
                home-manager
                deploy-rs
              ])
              ++ [ inputs.agenix.packages.${system}.agenix ]
              ++ (nixpkgs.lib.lists.optional pkgs.stdenv.isDarwin [ darwin.packages.${system}.darwin-rebuild ]);
          };
        }
      ))
      {
        inherit (inputs.deploy-rs) apps;
        deploy.nodes = {
          dell = {
            hostname = "dell";
            profiles.system = {
              user = "root";
              sshUser = "volodia";
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.dell;
            };
          };
          home-server = {
            hostname = "home-server";
            profiles.system = {
              user = "root";
              sshUser = "volodia";
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.home-server;
            };
          };
        };

        checks = builtins.mapAttrs (_system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      }
    ];
}
