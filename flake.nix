{
  description = "Volodia P.-G'.s system config";

  inputs = {
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.follows = "srvos/nixpkgs";
    nixpkgs-darwin.follows = "srvos/nixpkgs";
    #nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    srvos = {
      url = "github:nix-community/srvos";
      # Use the version of nixpkgs that has been tested to work with SrvOS
      # Alternatively we also support the latest nixos release and unstable
      #inputs.nixpkgs.follows = "nixpkgs";
    };
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
    vim.url = "github:volodiapg/vim";
    impermanence.url = "github:nix-community/impermanence";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";
    mosh.url = "github:zhaofengli/mosh/fish-wcwidth";
    mosh.flake = false;
    yabai = {
      flake = false;
      url = "github:koekeishiya/yabai";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  nixConfig = {
    extra-substituters = [
      "https://volodiapg.cachix.org"
    ];
    extra-trusted-public-keys = [
      "volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI="
      "giraff.cachix.org-1:3sol29PSsWCh/7bAiRze+5Zq6OML02FDRH13K5i3qF4="
      "vim.cachix.org-1:csyY4pnUgltVSD3alxSV6zZG/lRD7FQBfl4K4RNBgXA="
    ];
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
        vim.overlay
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
                # Inherit everything we can from the flake
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
            ++ (nixpkgs.lib.optional (nixpkgs.lib.strings.hasSuffix "linux" system) catppuccin.nixosModules.catppuccin)
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
                  catppuccin.homeManagerModules.catppuccin
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
          packages.yabai = let
            pkgs = nixpkgs.legacyPackages.${system};
          in
            pkgs.callPackage ./yabai.nix {src = yabai;};
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
                        catppuccin.homeManagerModules.catppuccin
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
                  nixos-hardware.nixosModules.common-cpu-intel-cpu-only
                  nixos-hardware.nixosModules.common-gpu-intel
                  nixos-hardware.nixosModules.common-pc
                  nixos-hardware.nixosModules.common-pc-laptop
                  nixos-hardware.nixosModules.common-pc-laptop-acpi_call
                  nixos-hardware.nixosModules.common-pc-laptop-ssd
                  srvos.nixosModules.server
                  microvm.nixosModules.host
                  vscode-server.nixosModules.default
                  ({config, ...}: {
                    services.vscode-server.enable = true;
                    networking = {
                      useDHCP = false;
                      nat = {
                        enable = true;
                        enableIPv6 = true;
                        internalInterfaces = ["vbr0"];
                        externalInterface = "enp0s31f6";
                      };
                      useNetworkd = true;
                    };
                    systemd.network = {
                      enable = true;
                      wait-online.anyInterface = true;
                      netdevs = {
                        "10-microvm".netdevConfig = {
                          Kind = "bridge";
                          Name = "vbr0";
                        };
                      };
                      networks = {
                        "10-lan" = {
                          matchConfig.Name = ["enp*" "wlp*"];
                          networkConfig.DHCP = true;
                        };
                        "10-microvm" = {
                          matchConfig.Name = "vbr0";
                          networkConfig = {
                            DHCPServer = true;
                            IPv6SendRA = true;
                          };
                          addresses = [
                            {
                              addressConfig.Address = "10.0.0.1/24";
                            }
                            {
                              addressConfig.Address = "fd12:3456:789a::1/64";
                            }
                          ];
                          ipv6Prefixes = [
                            {
                              ipv6PrefixConfig.Prefix = "fd12:3456:789a::/64";
                            }
                          ];
                        };
                        "11-microvm" = {
                          matchConfig.Name = "vm-*";
                          networkConfig.Bridge = "vbr0";
                        };
                      };
                    };
                    networking.firewall.allowedUDPPorts = [67];

                    networking.firewall.trustedInterfaces = ["tailscale0" "vbr0"];
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
                    system.stateVersion = 5;
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
                      extraOptions = ''
                        extra-platforms = x86_64-darwin aarch64-darwin
                      '';

                      configureBuildUsers = true;

                      linux-builder = {
                        enable = true;
                        ephemeral = true;
                        maxJobs = 8;
                        supportedFeatures = ["kvm" "benchmark" "big-parallel"];
                        systems = ["aarch64-linux" "x86_64-linux"];
                        config = {
                          # This can't include aarch64-linux when building on aarch64,
                          # for reasons I don't fully understand
                          boot.binfmt.emulatedSystems = ["x86_64-linux"];
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
                            extra-platforms = ["aarch64-linux" "x86_64-linux"];
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
                      nix-daemon.enable = true;
                      yabai = {
                        enable = true;
                        package = outputs.packages.${system}.yabai;
                        extraConfig = builtins.readFile ./users/volodia/packages/.yabairc;
                        enableScriptingAddition = true;
                      };
                      skhd = {
                        enable = true;
                        skhdConfig = builtins.readFile ./users/volodia/packages/.skhdrc;
                      };
                    };

                    # Add ability to used TouchID for sudo authentication
                    security.pam.enableSudoTouchIdAuth = true;
                  }
                ];
            };
          }
        ))
        (flake-utils.lib.eachDefaultSystem (
          system: let
            pkgs = pkgsFor nixpkgs system;
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

            packages.mosh = pkgs.mosh;

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
