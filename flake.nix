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

  # NOTE: Nix requires `nixConfig` values to be literals (it refuses thunks), so
  # this list cannot be imported from config.nix. It must stay in sync with
  # `me.extra-substituters` / `me.trusted-public-keys` there, which is what the
  # hosts themselves use (modules/nixos/common-nix-settings.nix).
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

      # ---------------------------------------------------------------------
      # Machine inventory
      # ---------------------------------------------------------------------
      # The single place a machine is declared. Everything else about a host
      # lives in configurations/<class>/<name>/default.nix.
      #
      #   system : the platform it is built for.
      #   cuda   : build against the CUDA-enabled nixpkgs variant (see below).
      #   modules: extra modules injected from the flake (rarely needed).

      nixosHosts = {
        msi = {
          system = "x86_64-linux";
          cuda = true;
        };
        home-server.system = "x86_64-linux";
        m1.system = "aarch64-linux";
        installer.system = "x86_64-linux";
      };

      darwinHosts = {
        "Volodias-MacBook-Pro".system = "aarch64-darwin";
      };

      # Systems we publish per-system outputs (packages, devShells, checks) for:
      # exactly the ones some machine is built for.
      systems = lib.unique (lib.mapAttrsToList (_: host: host.system) (nixosHosts // darwinHosts));
      forAllSystems = lib.genAttrs systems;

      # ---------------------------------------------------------------------
      # nixpkgs instances
      # ---------------------------------------------------------------------
      # Shared with the NixOS/darwin modules so that `nixpkgs.config` and the
      # hand-built instances below cannot drift apart.
      nixpkgsConfig = import ./lib/nixpkgs-config.nix { inherit lib; };

      # CUDA is a *variant* of nixpkgs rather than a platform: flipping it
      # rebuilds a large part of the tree, so each (system, variant) pair gets
      # its own instance. They are memoised here so that N hosts on the same
      # pair share one nixpkgs evaluation instead of importing it N times.
      cudaVariants = [
        "cuda"
        "no-cuda"
      ];

      pkgsUnstableBySystem = forAllSystems (
        system:
        lib.genAttrs cudaVariants (
          variant:
          import nixpkgs-unstable {
            inherit system;
            config = nixpkgsConfig // {
              cudaSupport = variant == "cuda";
            };
          }
        )
      );

      pkgsUnstableFor =
        system: cuda: pkgsUnstableBySystem.${system}.${if cuda then "cuda" else "no-cuda"};

      # The repo's own overlay: in-repo packages (packages/), plus selected
      # attributes pulled forward from nixpkgs-unstable. See overlays/default.nix.
      mkOverlay =
        system: cuda:
        import ./overlays/default.nix {
          inherit flake;
          pkgs-unstable = pkgsUnstableFor system cuda;
        };

      # Stable nixpkgs with the repo overlay applied, used for the `packages`
      # output and as the darwin `pkgs`.
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = nixpkgsConfig;
          overlays = [ (mkOverlay system false) ];
        };

      # ---------------------------------------------------------------------
      # The `flake` argument every module in this repo receives
      # ---------------------------------------------------------------------
      # Carried-over attr from nixos-unified's shape so repo modules stay
      # unmodified: `flake.self + "/x"` works via self.outPath,
      # `flake.inputs.self` is self, and `flake.config.me` comes from config.nix.
      flake = self // {
        inherit self;
        inputs = inputs // {
          inherit self;
        };
        config = import ./config.nix;
      };

      # ---------------------------------------------------------------------
      # Builders
      # ---------------------------------------------------------------------
      # Both pass the same three specialArgs to every module:
      #   flake         : the attrset above (inputs, self, config.me);
      #   pkgs-unstable : nixpkgs-unstable for this host's (system, cuda) pair;
      #   overlay       : the repo overlay, applied by common-overlays.nix.

      mkNixos =
        name:
        {
          system,
          cuda ? false,
          modules ? [ ],
        }:
        lib.nixosSystem {
          modules = [
            ./configurations/nixos/${name}/default.nix
            { nixpkgs.hostPlatform = lib.mkDefault system; }
          ]
          ++ modules;
          specialArgs = {
            inherit flake;
            pkgs-unstable = pkgsUnstableFor system cuda;
            overlay = mkOverlay system cuda;
          };
        };

      mkDarwin =
        name:
        {
          system,
          modules ? [ ],
        }:
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          pkgs = pkgsFor system;
          modules = [
            ./configurations/darwin/${name}/default.nix
          ]
          ++ modules;
          specialArgs = {
            inherit flake;
            pkgs-unstable = pkgsUnstableFor system false;
            overlay = mkOverlay system false;
          };
        };

      # ---------------------------------------------------------------------
      # Lint / format hooks, shared by `nix flake check` and the dev shell
      # ---------------------------------------------------------------------
      # Hooks that are pure linters/formatters: they run anywhere, including
      # inside the sandbox `nix flake check` builds them in.
      lintHooks = {
        nixfmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        actionlint.enable = true;
        shellcheck.enable = true;
        luacheck.enable = true;
        stylua.enable = true;
      };

      mkPreCommit =
        system: hooks:
        inputs.git-hooks.lib.${system}.run {
          src = ./.;
          inherit hooks;
        };

      # What `nix flake check` runs.
      preCommitCheck = forAllSystems (system: mkPreCommit system lintHooks);

      # What the dev shell installs as the actual git hook. `transcrypt` shells
      # out to .git/crypt/transcrypt, which only exists in a real checkout, so it
      # cannot be part of `checks` above.
      preCommitShell = forAllSystems (
        system:
        mkPreCommit system (
          lintHooks
          // {
            transcrypt = {
              enable = true;
              entry = "./transcrypt-hook.sh";
            };
          }
        )
      );
    in
    {
      # --- Module sets ------------------------------------------------------
      nixosModules = {
        default = ./modules/nixos/default.nix;
        # Home Manager wiring; imported by the hosts that have a user.
        home-manager = ./modules/nixos/home-manager.nix;
      };
      darwinModules = {
        default = ./modules/darwin/default.nix;
        home-manager = ./modules/darwin/home-manager.nix;
      };
      homeModules.default = ./modules/home/default.nix;

      # --- Machines ---------------------------------------------------------
      nixosConfigurations = lib.mapAttrs mkNixos nixosHosts;
      darwinConfigurations = lib.mapAttrs mkDarwin darwinHosts;

      # --- In-repo packages -------------------------------------------------
      # Exposed so `nix run .#xinstall` works (the installer ISO relies on it,
      # see configurations/nixos/installer/default.nix) and so CI can build them.
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        # Not every in-repo package can be built everywhere — mpv-rife pulls in
        # Linux-only vapoursynth plugins. Drop the ones that do not even
        # evaluate on this system so `nix flake show`/`check` stay green.
        lib.filterAttrs (_: pkg: (builtins.tryEval (builtins.seq pkg.drvPath true)).success) (
          import ./packages/default.nix { inherit pkgs; }
        )
      );

      # `nix fmt` — same formatter the nixfmt pre-commit hook uses.
      formatter = forAllSystems (system: pkgsUnstableBySystem.${system}.no-cuda.nixfmt-tree);

      # `nix flake check` — runs the hooks and evaluates every configuration.
      checks = forAllSystems (system: {
        pre-commit = preCommitCheck.${system};
      });

      # --- Remote deployment ------------------------------------------------
      deploy.nodes.home-server =
        let
          system = "x86_64-linux";
          # deploy-rs' own overlay pulls in a source build of deploy-rs; swap in
          # the cached binary from unmodified nixpkgs while keeping its lib.
          pkgs = import nixpkgs { inherit system; };
          deployPkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.deploy-rs.overlays.default
              (_self: super: {
                deploy-rs = {
                  inherit (pkgs) deploy-rs;
                  inherit (super.deploy-rs) lib;
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
            path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.home-server;
            fastConnection = true;
          };
        };

      # --- Dev shells -------------------------------------------------------
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsUnstableBySystem.${system}.no-cuda;
          check = preCommitShell.${system};
        in
        {
          # Minimal shell for CI: everything `just deploy` needs, nothing else.
          ci = pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.deploy-rs
              pkgs.nix-fast-build
            ];
          };

          default = pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.nix-fast-build
              pkgs.git
              pkgs.ragenix
              pkgs.deploy-rs
              pkgs.nh
              pkgs.nix-output-monitor
              pkgs.prek
              pkgs.nvd
              pkgs.gum
              pkgs.transcrypt
              pkgs.rsync
              pkgs.openssl
              pkgs.kubectl
              pkgs.k9s
            ]
            ++ check.enabledPackages;
            inherit (check) shellHook;
          };
        }
      );
    };
}
