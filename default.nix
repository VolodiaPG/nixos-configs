# ponytail: "flake" is just a carried-over attr/param name from nixos-unified's shape so
# repo modules stay unmodified. No flake.nix, no flake evaluator, no fetchTree — plain
# import + lib.nixosSystem / darwin.lib.darwinSystem over npins-fetched tarballs.
let
  sources = import ./npins;
  # ponytail: import only nixpkgs/lib, not the full package set — far cheaper.
  lib = import (sources.nixpkgs + "/lib");
  libUnstable = import (sources.nixpkgs-unstable + "/lib");

  # Unoverlaid nixpkgs per system. Repo nixpkgs.config/overlays are applied by the NixOS
  # module system (defaultPkgs), NOT here — avoids the `nixpkgs.pkgs -> cfg.config == {}`
  # assertion. Used for inputs.nixpkgs.legacyPackages/lib and building self.packages.
  pkgsFor =
    system:
    import sources.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        # ponytail: matches flake perSystem; mpv-rife (msi) needs cuda + tensorrt.
        cudaSupport = system == "x86_64-linux";
        # ponytail: getName checks pname — the tensorrt drv name is `cuda12.9-tensorrt-<ver>`,
        # so `p.name == "tensorrt"` misses it. Mirrors the original flake predicate exactly.
        allowInsecurePredicate = pkg: lib.getName pkg == "tensorrt";
      };
    };

  # ponytail: unstable nixpkgs for fast-moving tools (opencode, nvim, lsps). Same config as stable.
  pkgsUnstableFor =
    system:
    import sources.nixpkgs-unstable {
      inherit system;
      config = {
        allowUnfree = true;
        cudaSupport = system == "x86_64-linux";
        allowInsecurePredicate = pkg: lib.getName pkg == "tensorrt";
      };
    };

  # ponytail: bind each package set once — Nix's import cache is keyed by argument
  # pointer identity, not structural equality, so repeated pkgsFor/pkgsUnstableFor
  # calls with identical args each build a fresh full nixpkgs evaluation.
  pkgs-x86_64-linux = pkgsFor "x86_64-linux";
  pkgs-aarch64-linux = pkgsFor "aarch64-linux";
  pkgs-aarch64-darwin = pkgsFor "aarch64-darwin";
  pkgs-unstable-x86_64-linux = pkgsUnstableFor "x86_64-linux";
  pkgs-unstable-aarch64-linux = pkgsUnstableFor "aarch64-linux";
  pkgs-unstable-aarch64-darwin = pkgsUnstableFor "aarch64-darwin";

  pkgsUnstableBySystem = {
    x86_64-linux = pkgs-unstable-x86_64-linux;
    aarch64-linux = pkgs-unstable-aarch64-linux;
    aarch64-darwin = pkgs-unstable-aarch64-darwin;
  };

  # x86_64-linux unstable pkgs — exposed as a module arg so nixos/home modules can pull
  # arbitrary unstable packages (e.g. gaming.nix steam). darwin gets its own in mkDarwin.
  pkgs-unstable = pkgs-unstable-x86_64-linux;
  # aarch64-linux unstable pkgs for M1
  pkgs-unstable-aarch64 = pkgs-unstable-aarch64-linux;

  # Recursive self so self.inputs.self = self (matches flake semantics).
  self = {
    outPath = ./.;
    inherit self;
    inherit sources;
    inputs = inputs // {
      inherit self;
    };
    config = {
      inherit (import ./config.nix) me;
    };
    nixosModules.default = ./modules/nixos/default.nix;
    homeModules.default = ./modules/home/default.nix;
    darwinModules.default = ./modules/darwin/default.nix;
    # overlay is curried {flake,...}: _final: prev: …; apply flake=self
    overlays.default = (import ./overlays/default.nix) { flake = self; };
    packages = {
      x86_64-linux = import ./packages/default.nix {
        pkgs = pkgs-x86_64-linux;
        inherit inputs;
        system = "x86_64-linux";
      };
      aarch64-linux = import ./packages/default.nix {
        pkgs = pkgs-aarch64-linux;
        inherit inputs;
        system = "aarch64-linux";
      };
      aarch64-darwin = import ./packages/default.nix {
        pkgs = pkgs-aarch64-darwin;
        inherit inputs;
        system = "aarch64-darwin";
      };
    };
  };

  inputs = {
    nixpkgs = {
      outPath = sources.nixpkgs;
      inherit lib;
      legacyPackages = {
        x86_64-linux = pkgs-x86_64-linux;
        aarch64-linux = pkgs-aarch64-linux;
        aarch64-darwin = pkgs-aarch64-darwin;
      };
    };
    # ponytail: unstable nixpkgs input — overlay pulls fast-moving tools from here.
    nixpkgs-unstable = {
      outPath = sources.nixpkgs-unstable;
      lib = libUnstable;
      legacyPackages = {
        x86_64-linux = pkgs-unstable-x86_64-linux;
        aarch64-linux = pkgs-unstable-aarch64-linux;
        aarch64-darwin = pkgs-unstable-aarch64-darwin;
      };
    };
    home-manager = {
      outPath = sources.home-manager;
      nixosModules.home-manager = sources.home-manager + "/nixos";
      darwinModules.home-manager = sources.home-manager + "/nix-darwin";
    };
    nixos-hardware.nixosModules = {
      common-cpu-intel = sources.nixos-hardware + "/common/cpu/intel";
      common-cpu-intel-cpu-only = sources.nixos-hardware + "/common/cpu/intel/cpu-only.nix";
      common-gpu-nvidia = sources.nixos-hardware + "/common/gpu/nvidia/prime.nix";
      common-pc = sources.nixos-hardware + "/common/pc";
      common-pc-ssd = sources.nixos-hardware + "/common/pc/ssd";
    };
    impermanence.nixosModules.impermanence = sources.impermanence + "/nixos.nix";
    agenix = {
      nixosModules.default = sources.agenix + "/modules/age.nix";
      darwinModules.age = sources.agenix + "/modules/age.nix";
      homeManagerModules.default = sources.agenix + "/modules/age-home.nix";
    };
    disko.nixosModules.disko = sources.disko + "/module.nix";
    nixarr.nixosModules.default = {
      imports = [
        (sources.nixarr + "/nixarr")
        (sources.vpnconfinement + "/modules/vpn-netns.nix")
      ];
    };
    srvos.nixosModules.server = sources.srvos + "/nixos/server";
    catppuccin.homeModules.catppuccin = sources.catppuccin + "/modules/home-manager";
    nix-index-database.homeModules.nix-index = sources.nix-index-database + "/home-manager-module.nix";
    inherit (sources) mosh; # flake=false, used as src by overlay mosh override
    # ponytail: high-tide fork — upstream buildPythonApplication, only src swapped to the npins pin.
    # Built from unstable: its Python deps (python-mpd2, tidalapi) aren't in stable 26.05.
    high-tide.packages = {
      x86_64-linux.high-tide =
        pkgs-unstable-x86_64-linux.callPackage ./packages/high-tide/default.nix
          { };
      aarch64-linux.high-tide =
        pkgs-unstable-aarch64-linux.callPackage ./packages/high-tide/default.nix
          { };
    };
    # ponytail: darwin-only — vendored 5-line nix-homebrew wrapper (avoids evaluating its flake.nix).
    nix-homebrew.darwinModules.nix-homebrew =
      { lib, ... }:
      {
        imports = [ (sources.nix-homebrew + "/modules") ];
        nix-homebrew.package = lib.mkOptionDefault (
          sources.brew
          // {
            name = "brew";
            version = sources.brew.version or "0";
          }
        );
      };

    nixos-apple-silicon.nixosModules.default = sources.nixos-apple-silicon + "/apple-silicon-support";

    # ponytail: direct loadPackages.nix import — bypasses flake.nix + flake-compat.
    # Reads cachy's flake.lock to fetch the exact nixpkgs rev (nixos-unstable-small)
    # the flake uses, so drv hashes match the lantian binary cache (no kernel recompiles).
    # The flake's perSystem overrides pkgs with allowUnfree + allowInsecurePredicate = _: true;
    # replicated here so loadPackages.nix sees identical pkgs.
    nix-cachyos-kernel.packages.x86_64-linux =
      let
        cachySrc = sources.nix-cachyos-kernel;
        cachyLock = builtins.fromJSON (builtins.readFile (cachySrc + "/flake.lock"));
        cachyNixpkgsLock = cachyLock.nodes.nixpkgs.locked;
        cachyNixpkgs = fetchTarball {
          url = "https://github.com/${cachyNixpkgsLock.owner}/${cachyNixpkgsLock.repo}/archive/${cachyNixpkgsLock.rev}.tar.gz";
          sha256 = cachyNixpkgsLock.narHash;
        };
        cachyPkgs = import cachyNixpkgs {
          system = "x86_64-linux";
          config = {
            allowUnfree = true;
            allowInsecurePredicate = _: true;
          };
        };
      in
      import (cachySrc + "/loadPackages.nix") { nixpkgs.outPath = cachyNixpkgs; } cachyPkgs;
  };

  # ponytail: direct eval-config.nix import — bypasses nix-darwin's flake.nix.
  # Replicates flake.lib.darwinSystem: wraps eval-config.nix with pkgs-override,
  # system, and nixpkgs.source/darwinVersionSuffix modules. Identical behavior
  # (self has no shortRev/rev → suffix resolves to "dirty", same as before).
  darwinEvalConfig = import (sources.nix-darwin + "/eval-config.nix");

  darwinSystem =
    args@{
      modules,
      ...
    }:
    darwinEvalConfig (
      {
        inherit lib;
      }
      // lib.optionalAttrs (args ? pkgs) { inherit (args.pkgs) lib; }
      // builtins.removeAttrs args [
        "system"
        "pkgs"
        "inputs"
      ]
      // {
        modules =
          modules
          ++ lib.optional (args ? pkgs) (
            { lib, ... }:
            {
              _module.args.pkgs = lib.mkForce args.pkgs;
            }
          )
          ++ lib.optional (args ? system) (
            { lib, ... }:
            {
              nixpkgs.system = lib.mkDefault args.system;
            }
          )
          ++ lib.optional (args ? inputs) {
            _module.args.inputs = args.inputs;
          }
          ++ [
            (
              { lib, ... }:
              {
                nixpkgs.source = lib.mkDefault sources.nixpkgs;
                nixpkgs.flake.source = lib.mkDefault sources.nixpkgs;
                system.checks.verifyNixPath = lib.mkDefault false;
                system.darwinVersionSuffix = ".dirty";
              }
            )
          ];
      }
    );

  mkNixos =
    name: system: extraModules:
    let
      # ponytail: use top-level lib (import nixpkgs/lib) — avoids re-importing the full
      # package set just for lib. Same pure lib as pkgsFor system .lib.
      evalConfig = import (sources.nixpkgs + "/nixos/lib/eval-config.nix");
      pkgs-unstable = pkgsUnstableBySystem.${system};
    in
    evalConfig {
      inherit lib;
      system = null;
      modules = [
        ./configurations/nixos/${name}/default.nix
        {
          nixpkgs.hostPlatform = lib.mkDefault system;
        }
      ]
      ++ extraModules;
      specialArgs = {
        flake = self;
        inherit pkgs-unstable;
      };
      # ponytail: NO pkgs arg — passing it sets nixpkgs.pkgs and the assertion
      # `opt.pkgs.isDefined -> cfg.config == {}` fails (repo sets nixpkgs.config).
      # defaultPkgs imports sources.nixpkgs WITH repo config + [self.overlays.default].
      # ponytail: NO nixpkgs.flake.source injection — repo's common-nix-settings.nix
      # already sets nix.registry/nixPath; setting flake.source makes nixpkgs-flake.nix
      # also set nix.registry.nixpkgs.to.path, conflicting with the repo's definition.
    };

  mkDarwin =
    name: extraModules:
    let
      # darwinSystem forces _module.args.pkgs and ignores repo nixpkgs.config/overlays,
      # so pre-apply the overlay + minimal config here (assertion still passes: nixpkgs.pkgs
      # option itself is not set, only _module.args.pkgs).
      darwinPkgs = import sources.nixpkgs {
        system = "aarch64-darwin";
        overlays = [ self.overlays.default ];
        config = {
          allowUnfree = true;
        };
      };
      pkgs-unstable = pkgs-unstable-aarch64-darwin;
    in
    darwinSystem {
      system = "aarch64-darwin";
      pkgs = darwinPkgs;
      modules = [
        ./configurations/darwin/${name}/default.nix
        {
          home-manager.extraSpecialArgs = {
            flake = self;
            inherit pkgs-unstable;
          };
        }
      ]
      ++ extraModules;
      specialArgs = {
        flake = self;
        inherit pkgs-unstable;
      };
    };

  # ponytail: inline replica of deploy-rs's lib.activate.nixos. Reuses the nixpkgs
  # deploy-rs package's `activate` binary (already in shell.nix) for magic-rollback,
  # so no deploy-rs npins pin / flake.nix import (the repo's usual anti-flake-eval
  # stance). Contract is stable: profile `path` must expose /deploy-rs-activate
  # (activation script) and /activate-rs (rollback watcher shim -> activate binary).
  activateNixos =
    nixosConfig:
    let
      pkgs = pkgs-x86_64-linux;
      toplevel = nixosConfig.config.system.build.toplevel;
    in
    pkgs.buildEnv {
      name = "activatable-${toplevel.name}";
      paths = [
        toplevel
        (pkgs.writeTextFile {
          name = "${toplevel.name}-deploy-rs-activate";
          text = ''
            #!${pkgs.runtimeShell}
            set -euo pipefail
            if ''${DRY_ACTIVATE:-0} == 1; then
              $PROFILE/bin/switch-to-configuration dry-activate
            elif ''${BOOT:-0} == 1; then
              $PROFILE/bin/switch-to-configuration boot
            else
              cd /tmp
              $PROFILE/bin/switch-to-configuration switch
              ${pkgs.lib.optionalString nixosConfig.config.boot.loader.systemd-boot.enable "sed -i '/^default /d' ${nixosConfig.config.boot.loader.efi.efiSysMountPoint}/loader/loader.conf"}
            fi
          '';
          executable = true;
          destination = "/deploy-rs-activate";
        })
        (pkgs.writeTextFile {
          name = "${toplevel.name}-activate-rs";
          text = ''
            #!${pkgs.runtimeShell}
            exec ${pkgs.deploy-rs}/bin/activate "$@"
          '';
          executable = true;
          destination = "/activate-rs";
        })
      ];
    };
in
rec {
  nixosConfigurations = {
    msi = mkNixos "msi" "x86_64-linux" [
      {
        home-manager.extraSpecialArgs = {
          flake = self;
          inherit pkgs-unstable;
        };
      }
    ];
    home-server = mkNixos "home-server" "x86_64-linux" [
      {
        home-manager.extraSpecialArgs = {
          flake = self;
          inherit pkgs-unstable;
        };
      }
    ];
    installer = mkNixos "installer" "x86_64-linux" [ ];
    m1 = mkNixos "m1" "aarch64-linux" [
      {
        home-manager.extraSpecialArgs = {
          flake = self;
          pkgs-unstable = pkgs-unstable-aarch64;
        };
      }
    ];
  };
  darwinConfigurations = {
    "Volodias-MacBook-Pro" = mkDarwin "Volodias-MacBook-Pro" [ ];
  };
  # ponytail: expose self.packages so standalone `nix-build . -A packages.<system>.<name>` works.
  inherit (self) packages;
  shell = import ./shell.nix;
  # ponytail: deploy-rs file-mode target. `deploy -f . home-server --skip-checks`
  # evaluates (import ./.).deploy — no flake needed. --skip-checks mirrors the old
  # workflow (no `checks` attr defined); deploy-rs's own pre-build check is kept.
  deploy.nodes.home-server = {
    hostname = "home-server";
    profiles.system = {
      user = "root";
      sshUser = "volodia";
      path = activateNixos nixosConfigurations.home-server;
      fastConnection = true;
    };
  };
}
