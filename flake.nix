{
  description = "NixOS, nix-darwin, and Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    srvos = {
      url = "github:nix-community/srvos/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org?priority=10"
      "https://nix-community.cachix.org?priority=15"
      "https://volodiapg.cachix.org?priority=30"
      "https://cache.numtide.com?priority=20"
      "https://cache.flakehub.com?priority=20"
      "https://cache.nixos-cuda.org?priority=10"
      "https://attic.xuyh0120.win/lantian"
      "https://install.determinate.systems"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI="
      #"niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      #"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
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
      forAllSystems = lib.genAttrs systems;

      # Unoverlaid nixpkgs per system — for self.packages only.
      # Repo nixpkgs.config/overlays are applied by the module system, NOT here.
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = system == "x86_64-linux";
            allowInsecurePredicate = pkg: lib.getName pkg == "tensorrt";
          };
        };

      pkgsUnstableFor =
        system:
        import nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = system == "x86_64-linux";
            allowInsecurePredicate = pkg: lib.getName pkg == "tensorrt";
          };
        };

      pkgsUnstableBySystem = forAllSystems pkgsUnstableFor;
      # x86_64-linux unstable pkgs — default for nixos hosts msi/home-server
      pkgs-unstable = pkgsUnstableBySystem.x86_64-linux;
      # aarch64-linux unstable pkgs for M1
      pkgs-unstable-aarch64 = pkgsUnstableBySystem.aarch64-linux;

      # Carried-over attr from nixos-unified's shape so repo modules stay unmodified.
      # flake.self+"/x" works via self.outPath; flake.inputs.self = self; flake.config.me from config.nix.
      flake = self // {
        inherit self;
        inputs = inputs // {
          inherit self;
        };
        config = import ./config.nix;
      };

      overlays-default = (import ./overlays/default.nix) { inherit flake; };

      packagesFor =
        system:
        let
          pkgs = pkgsFor system;
          base = import ./packages/default.nix { inherit pkgs; };
          high-tide = lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
            high-tide = pkgsUnstableBySystem.${system}.callPackage ./packages/high-tide/default.nix {
              src = inputs.high-tide;
            };
          };
        in
        base // high-tide;

      mkNixos =
        name: system: extraModules:
        let
          pkgs-unstable = pkgsUnstableBySystem.${system};
        in
        nixpkgs.lib.nixosSystem {
          modules = [
            ./configurations/nixos/${name}/default.nix
            { nixpkgs.hostPlatform = lib.mkDefault system; }
          ]
          ++ extraModules;
          specialArgs = {
            inherit flake pkgs-unstable;
          };
        };

      mkDarwin =
        name: extraModules:
        let
          system = "aarch64-darwin";
          darwinPkgs = import nixpkgs {
            inherit system;
            overlays = [
              overlays-default
            ];
            config.allowUnfree = true;
          };
          pkgs-unstable = pkgsUnstableBySystem.${system};
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
          };
        };

      nixosConfigurations = {
        msi = mkNixos "msi" "x86_64-linux" [
          {
            home-manager.extraSpecialArgs = {
              inherit flake pkgs-unstable;
            };
          }
        ];
        home-server = mkNixos "home-server" "x86_64-linux" [
          {
            home-manager.extraSpecialArgs = {
              inherit flake pkgs-unstable;
            };
          }
        ];
        installer = mkNixos "installer" "x86_64-linux" [ ];
        m1 = mkNixos "m1" "aarch64-linux" [
          {
            home-manager.extraSpecialArgs = {
              inherit flake;
              pkgs-unstable = pkgs-unstable-aarch64;
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
          };
        }
      );
    in
    {
      nixosModules.default = ./modules/nixos/default.nix;
      homeModules.default = ./modules/home/default.nix;
      darwinModules.default = ./modules/darwin/default.nix;

      overlays.default = overlays-default;

      packages = forAllSystems packagesFor;

      inherit nixosConfigurations darwinConfigurations;

      deploy.nodes.home-server = {
        hostname = "home-server";
        profiles.system = {
          user = "root";
          sshUser = "volodia";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.home-server;
          fastConnection = true;
        };
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          check = pre-commit-check.${system};
        in
        {
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
              ]
              ++ check.enabledPackages;
            inherit (check) shellHook;
          };
        }
      );
    };
}
