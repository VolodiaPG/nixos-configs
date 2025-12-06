{
  description = "Volodia P.-G'.s system config";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixpkgs-unstable.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vim = {
      url = "github:volodiapg/vim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mosh = {
      url = "github:zhaofengli/mosh/fish-wcwidth";
      flake = false;
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hosts = {
      url = "github:StevenBlack/hosts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixos-apple-silicon = {
    #   url = "github:nix-community/nixos-apple-silicon";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    llm-agents.url = "github:numtide/llm-agents.nix";

    laputil = {
      url = "github:volodiapg/laputil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  nixConfig = {
    extra-substituters = [
      "https://volodiapg.cachix.org"
      "https://giraff.cachix.org"
      "https://vim.cachix.org"
      "https://install.determinate.systems"
      "https://nixos-apple-silicon.cachix.org"
      "https://numtide.cachix.org"
    ];
    extra-trusted-public-keys = [
      "volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI="
      "giraff.cachix.org-1:3sol29PSsWCh/7bAiRze+5Zq6OML02FDRH13K5i3qF4="
      "vim.cachix.org-1:csyY4pnUgltVSD3alxSV6zZG/lRD7FQBfl4K4RNBgXA="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };

  outputs =
    inputs@{ self, ... }:
    let
      inherit (self) outputs;

      # Overlays
      mosh-overlay = _final: prev: {
        mosh = prev.mosh.overrideAttrs (
          old:
          let
            patches = inputs.nixpkgs.lib.lists.remove (prev.fetchpatch {
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

      overlays = [
        mosh-overlay
        inputs.vim.overlay
        inputs.nur.overlays.default
        # inputs.nixos-apple-silicon.overlays.default
      ];

      # User data
      specialArgs = {
        inherit inputs outputs;
        user = {
          name = "Volodia P.G.";
          username = "volodia";
          homeDirectory = "/home/volodia";
          macosHomeDirectory = "/Users/volodia";
          tailname = "goblin-alewife.ts.net";
          email = "volodia.parol-guarino@proton.me";
          signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT";
          keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpDmkY5OctLdxrPUcnRafndhDvvgw/GNYvgo4I9LrPJ341vGzwgqSi90YRvn725DkYHmEi1bN7i3W2x1AQbuvEBzxMG3BlwtEGtz+/5rIMY+5LRzB4ppN+Ju/ySbPKSD2XpVgVOCegc7ZtZ4XpAevVsi/kyg35RPNGmljEyuN1wIxBVARZXZezsGf1MHzxEqiNogeAEncPCk/P44B6xBRt9qSxshIT/23Cq3M/CpFyvbI0vtdLaVFIPox6ACwlmTgdReC7p05EefKEXaxVe61yhBquzRwLZWf6Y8VESLFFPZ+lEF0Shffk15k97zJICVUmNPF0Wfx1Fn5tQyDeGe2nA5d2aAxHqvl2mJk/fccljzi5K6j6nWNf16pcjWjPqCCOTs8oTo1f7gVXQFCzslPnuPIVUbJItE3Ui+mSTv9KF/Q9oH02FF40mSuKtq5WmntV0kACfokRJLZ6slLabo0LgVzGoixdiGwsuJbWAsNNHURoi3lYb8fMOxZ/2o4GZik= volodia@volodia-msi"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT volodia.parol-guarino@proton.me"
          ];
          hashedPassword = "$6$bK0PDtsca0mKnwX9$uZ2p6ovO9qyTI9vuutKS.X93zHYK.yp2Iw658CkWsBCBHqG4Eq9AUZlVQ4GG1d02D9Sw7i0VdqGxJDFWUS82O1";
        };
      };

      # Helper function to create pkgs with overlays
      pkgsFor =
        system:
        import inputs.nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

      flakeModule = {
        nixpkgs = {
          inherit overlays;
          config.allowUnfree = true;
        };
        environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
        environment.etc."nix/inputs/self".source = "${self}";
        nix.registry.nixpkgs.flake = inputs.nixpkgs;
        system.configurationRevision = inputs.nixpkgs.lib.mkIf (self ? rev) self.rev;
      };
    in
    {
      # Module registries
      nixosModules = import ./nix-modules;
      darwinModules = import ./darwin-modules;
      homeModules = import ./home-modules;

      # NixOS configurations
      nixosConfigurations = {
        msi = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [
            ./hosts/msi/configuration.nix
            flakeModule
            inputs.determinate.nixosModules.default
            inputs.agenix.nixosModules.default
            inputs.laputil.nixosModules.default
            inputs.impermanence.nixosModules.impermanence
            inputs.catppuccin.nixosModules.catppuccin
            ./secrets/nixos.nix
          ];
        };

        dell = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [
            ./hosts/dell/configuration.nix
            flakeModule
            ./secrets/nixos.nix
          ];
        };

        home-server = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [
            ./hosts/home-server/configuration.nix
            flakeModule
            inputs.determinate.nixosModules.default
            inputs.agenix.nixosModules.default
            inputs.laputil.nixosModules.default
            inputs.impermanence.nixosModules.impermanence
            inputs.catppuccin.nixosModules.catppuccin
            ./secrets/nixos.nix
          ];
        };
      };

      # Darwin configurations
      darwinConfigurations."Volodias-MacBook-Pro" =
        let
          specialArgs' = specialArgs // {
            user = specialArgs.user // {
              homeDirectory = specialArgs.user.macosHomeDirectory;
            };
          };
        in
        inputs.darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = specialArgs';
          modules = [
            {
              system = {
                stateVersion = 5;
                primaryUser = specialArgs'.user.username;
              };
              nixpkgs = {
                hostPlatform = "aarch64-darwin";
                inherit overlays;
                config.allowUnfree = true;
              };
            }
            outputs.darwinModules.common-darwin
            inputs.determinate.darwinModules.default
            inputs.home-manager.darwinModules.home-manager
            inputs.agenix.darwinModules.default
            {
              home-manager = {
                users."${specialArgs'.user.username}" =
                  {
                    lib,
                    config,
                    pkgs,
                    ...
                  }:
                  {
                    imports = lib.flatten [
                      (with outputs.homeModules; [
                        (common-home {
                          inherit pkgs lib;
                          inherit (specialArgs') user;
                        })
                        (git {
                          inherit pkgs;
                          inherit (specialArgs') user;
                        })
                        (zsh {
                          inherit
                            pkgs
                            lib
                            config
                            inputs
                            ;
                        })
                        (ssh {
                          inherit pkgs;
                          inherit (specialArgs') user;
                        })
                        syncthing
                        mail
                        packages-personal
                      ])
                    ];
                  };
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = specialArgs';
                sharedModules = [
                  ./secrets/home-manager.nix
                  inputs.agenix.homeManagerModules.default
                  inputs.catppuccin.homeModules.catppuccin
                  inputs.nix-index-database.homeModules.nix-index
                  { nix.registry.nixpkgs.flake = inputs.nixpkgs; }
                ];
              };
            }
            ./secrets/nixos.nix
          ];
        };
    }
    // (inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = pkgsFor system;
      in
      {

        # Development tools
        formatter = pkgs.nixfmt-tree;

        checks = {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
              statix.enable = true;
              deadnix.enable = true;
              commitizen.enable = true;
              actionlint.enable = true;
            };
          };
        };

        devShells = {
          default = pkgs.mkShell {
            inherit (outputs.checks.${system}.pre-commit-check) shellHook;
            packages =
              (with pkgs; [
                just
                git
                git-crypt
                age
                ssh-to-age
                home-manager
              ])
              ++ [ inputs.deploy-rs.packages.${system}.default ]
              ++ [ inputs.agenix.packages.${system}.agenix ]
              ++ (inputs.nixpkgs.lib.lists.optional pkgs.stdenv.isDarwin
                inputs.darwin.packages.${system}.darwin-rebuild
              );
          };
        };

        apps = {
          deploy-rs = {
            type = "app";
            program = "${inputs.deploy-rs.packages.${system}.default}/bin/deploy";
            meta = {
              description = "Deploy NixOS configurations using deploy-rs";
              mainProgram = "deploy";
            };
          };
          default = {
            type = "app";
            program = "${inputs.deploy-rs.packages.${system}.default}/bin/deploy";
            meta = {
              description = "Deploy NixOS configurations using deploy-rs";
              mainProgram = "deploy";
            };
          };
        };
      }
    ))
    // {
      # Deploy-rs configuration
      deploy.nodes = {
        msi = {
          hostname = "msi";
          profiles.system = {
            user = "root";
            sshUser = "volodia";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.msi;
          };
        };
        dell = {
          hostname = "dell";
          profiles.system = {
            user = "root";
            sshUser = "volodia";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.dell;
          };
        };
        home-server = {
          hostname = "home-server";
          profiles.system = {
            user = "root";
            sshUser = "volodia";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.home-server;
          };
        };
      };
    };
}
