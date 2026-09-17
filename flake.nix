{
  description = "NixOS, nix-darwin, and Home Manager configurations";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "https://flakehub.com/f/ryantm/agenix/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "https://flakehub.com/f/nix-community/disko/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "https://flakehub.com/f/nix-community/impermanence/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    srvos = {
      url = "github:nix-community/srvos/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "https://flakehub.com/f/nixos/nixos-hardware/*";
    };

    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/main";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixarr = {
      url = "github:rasmus-kirk/nixarr/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew/main";

    # ponytail: own nixpkgs (nixos-unstable-small) — do NOT follow, preserves lantian binary cache hits
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/master";

    git-hooks = {
      url = "github:cachix/git-hooks.nix/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    deploy-rs.url = "github:serokell/deploy-rs/master";

    # ponytail: Determinate nix — own nixpkgs (no follow) preserves FlakeHub cache hits
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    # flake=false raw sources
    high-tide = {
      url = "github:Nokse22/high-tide/master";
      flake = false;
    };

    mosh = {
      url = "github:jdrouhard/mosh/patched";
      flake = false;
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org?priority=10"
      "https://nix-community.cachix.org?priority=15"
      "https://volodiapg.cachix.org?priority=30"
      "https://cache.numtide.com?priority=20"
      # "https://cache.flakehub.com?priority=20"
      "https://cache.nixos-cuda.org?priority=10"
      "https://attic.xuyh0120.win/lantian"
      "https://install.determinate.systems"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "determinate.systems:2f5mBvfSEjPpdnsbvY+JnsrWvSAUVM+HxFpYr0WXB44="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      cuda = [
        "cuda"
        "no-cuda"
      ];
      forAllSystems = lib.genAttrs systems;
      forAllSystemsCuda = lib.genAttrs cuda;

      pkgsUnstableFor =
        system: cuda:
        let
          cudaSupport = cuda == "cuda";
        in
        import nixpkgs-unstable {
          inherit system;
          config = {
            inherit cudaSupport;
            allowUnfree = true;
            allowInsecurePredicate = pkg: lib.getName pkg == "tensorrt";
          };
        };

      # pkgsUnstableBySystem = forAllSystems pkgsUnstableFor;
      pkgsUnstableBySystemAndCuda = forAllSystems (
        system: forAllSystemsCuda (cuda: pkgsUnstableFor system cuda)
      );

      overlays-default =
        system: cuda:
        (import ./overlays/default.nix) {
          inherit flake;
          pkgs-unstable = pkgsUnstableBySystemAndCuda.${system}.${cuda};
        };
      # Carried-over attr from nixos-unified's shape so repo modules stay unmodified.
      # flake.self+"/x" works via self.outPath; flake.inputs.self = self; flake.config.me from config.nix.
      flake = self // {
        inherit self;
        inputs = inputs // {
          inherit self;
        };
        config = import ./config.nix;
      };

      mkNixos =
        name: system: cuda: extraModules:
        let
          pkgs-unstable = pkgsUnstableBySystemAndCuda.${system}.${cuda};
        in
        nixpkgs.lib.nixosSystem {
          modules = [
            ./configurations/nixos/${name}/default.nix
            { nixpkgs.hostPlatform = lib.mkDefault system; }
          ]
          ++ extraModules;
          specialArgs = {
            inherit flake pkgs-unstable;
            overlays = overlays-default system cuda;
          };
        };

      mkDarwin =
        name: extraModules:
        let
          system = "aarch64-darwin";
          darwinPkgs = import nixpkgs {
            inherit system;
            overlays = [
              (overlays-default system "no-cuda")
            ];
            config.allowUnfree = true;
          };
          pkgs-unstable = pkgsUnstableBySystemAndCuda.${system}.no-cuda;
        in
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          pkgs = darwinPkgs;
          modules = [
            ./configurations/darwin/${name}/default.nix
            {
              home-manager.extraSpecialArgs = {
                inherit flake pkgs-unstable;
              };
            }
          ]
          ++ extraModules;
          specialArgs = {
            inherit flake pkgs-unstable;
            overlays = overlays-default system "no-cuda";
          };
        };

      nixosConfigurations = {
        msi = mkNixos "msi" "x86_64-linux" "cuda" [
          {
            home-manager.extraSpecialArgs = {
              inherit flake;
              pkgs-unstable = pkgsUnstableBySystemAndCuda.x86_64-linux.cuda;
            };
          }
        ];
        home-server = mkNixos "home-server" "x86_64-linux" "no-cuda" [
          {
            home-manager.extraSpecialArgs = {
              inherit flake;
              pkgs-unstable = pkgsUnstableBySystemAndCuda.x86_64-linux.no-cuda;
            };
          }
        ];
        installer = mkNixos "installer" "x86_64-linux" "no-cuda" [ ];
        m1 = mkNixos "m1" "aarch64-linux" [
          {
            home-manager.extraSpecialArgs = {
              inherit flake;
              pkgs-unstable = pkgsUnstableBySystemAndCuda.aarch64-linux.no-cuda;
            };
          }
        ];
      };

      darwinConfigurations = {
        "Volodias-MacBook-Pro" = mkDarwin "Volodias-MacBook-Pro" [ ];
      };

      pre-commit-check = forAllSystems (
        system:
        inputs.git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            actionlint.enable = true;
            shellcheck.enable = true;
            luacheck.enable = true;
            stylua.enable = true;
            transcrypt = {
              enable = true;
              entry = "./transcrypt-hook.sh";
            };
          };
        }
      );
    in
    {
      nixosModules.default = ./modules/nixos/default.nix;
      homeModules.default = ./modules/home/default.nix;
      darwinModules.default = ./modules/darwin/default.nix;

      inherit nixosConfigurations darwinConfigurations;

      deploy.nodes.home-server =
        let
          system = "x86_64-linux";
          # Unmodified nixpkgs
          pkgs = import nixpkgs { inherit system; };
          deployPkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.deploy-rs.overlays.default
              (_self: super: {
                deploy-rs = {
                  inherit (pkgs) deploy-rs;
                  lib = super.deploy-rs.lib;
                };
              })
            ];
          };
        in
        {
          hostname = "home-server";
          profiles.system = {
            user = "root";
            sshUser = "volodia";
            path = deployPkgs.deploy-rs.lib.activate.nixos nixosConfigurations.home-server;
            fastConnection = true;
          };
        };

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsUnstableBySystemAndCuda.${system}.no-cuda;
          check = pre-commit-check.${system};
        in
        {
          ci = pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.deploy-rs
            ];
          };
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                just
                git
                ragenix
                deploy-rs
                nh
                nix-output-monitor
                prek
                nvd
                gum
                transcrypt
                rsync
                openssl
                kubectl
                k9s
              ]
              ++ check.enabledPackages;
            inherit (check) shellHook;
          };
        }
      );
    };
}
