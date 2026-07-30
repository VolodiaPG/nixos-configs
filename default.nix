# ponytail: "flake" is just a carried-over attr/param name from nixos-unified's shape so
# repo modules stay unmodified. No flake.nix, no flake evaluator, no fetchTree — plain
# import + lib.nixosSystem / darwin.lib.darwinSystem over npins-fetched tarballs.
let
  sources = import ./npins;
  inherit (import sources.nixpkgs { }) lib;

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

  # Recursive self so self.inputs.self = self (matches flake semantics).
  self = {
    outPath = ./.;
    inherit self;
    inputs = inputs // {
      inherit self;
    };
    config = {
      inherit (import ./config.nix) me;
    };
    nixosModules.all-modules = ./modules/nixos/all-modules.nix;
    homeModules.all-modules = ./modules/home/all-modules.nix;
    darwinModules.all-modules = ./modules/darwin/all-modules.nix;
    # overlay is curried {flake,...}: _final: prev: …; apply flake=self
    overlays.default = (import ./overlays/default.nix) { flake = self; };
    packages = {
      x86_64-linux = import ./packages/default.nix {
        pkgs = pkgsFor "x86_64-linux";
        inherit inputs;
        system = "x86_64-linux";
      };
      aarch64-darwin = import ./packages/default.nix {
        pkgs = pkgsFor "aarch64-darwin";
        inherit inputs;
        system = "aarch64-darwin";
      };
    };
  };

  inputs = {
    nixpkgs = {
      outPath = sources.nixpkgs;
      inherit (import sources.nixpkgs { }) lib;
      legacyPackages = {
        x86_64-linux = pkgsFor "x86_64-linux";
        aarch64-darwin = pkgsFor "aarch64-darwin";
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
    # bbr_classic module is inline in its flake.nix; extract without vendoring.
    # ponytail: parens around `outputs {…}` — `.` binds tighter than application,
    # so `outputs {…}.nixosModules` would otherwise select `.nixosModules` from the argument.
    bbr_classic.nixosModules.default =
      ((import (sources.bbr_classic + "/flake.nix")).outputs {
        self = null;
        nixpkgs = null;
      }).nixosModules.default;
    srvos.nixosModules.server = sources.srvos + "/nixos/server";
    catppuccin.homeModules.catppuccin = sources.catppuccin + "/modules/home-manager";
    nix-index-database.homeModules.nix-index = sources.nix-index-database + "/home-manager-module.nix";
    # ponytail: determinate DROPPED. Its module is curried on Determinate's custom nix fork
    # (flakehub → flake-compat → defeats the speed goal). Empty stub so nix.nix's import
    # resolves; nix.nix has no top-level config access. Darwin's common-nix-settings.nix is
    # edited to drop determinate too. System uses nixpkgs nix.
    determinate = {
      nixosModules.default = { };
      darwinModules.default = { };
    };
    inherit (sources) mosh; # flake=false, used as src by overlay mosh override
    noctalia = {
      outPath = sources.noctalia;
      # Replicate noctalia's wrapper homeModule (injects package via mkDefault).
      homeModules.default =
        { pkgs, lib, ... }:
        {
          imports = [ (sources.noctalia + "/nix/home-module.nix") ];
          programs.noctalia.package =
            lib.mkDefault
              inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
      packages = {
        x86_64-linux.default = (pkgsFor "x86_64-linux").callPackage (
          sources.noctalia + "/nix/package.nix"
        ) { };
        # ponytail: aarch64-darwin.default intentionally absent — noctalia is disabled on
        # darwin (hyprland linux-only), so the mkDefault thunk above is never forced.
      };
    };
    # ponytail: high-tide fork — upstream buildPythonApplication, only src swapped to the npins pin.
    high-tide.packages.x86_64-linux.high-tide =
      (pkgsFor "x86_64-linux").callPackage ./packages/high-tide/default.nix
        { };
    # ponytail: opencode via nixpkgs (llm-agents package.nix needs llm-agents-internal helpers).
    llm-agents.packages = {
      x86_64-linux.opencode = (pkgsFor "x86_64-linux").opencode;
      aarch64-darwin.opencode = (pkgsFor "aarch64-darwin").opencode;
    };
    # ponytail: nvim placeholder — user will wire real nixCats config later.
    vim.packages = {
      x86_64-linux.nvim = (pkgsFor "x86_64-linux").neovim;
      aarch64-darwin.nvim = (pkgsFor "aarch64-darwin").neovim;
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
  };

  # nix-darwin ships no default.nix; evaluate its flake.nix outputs for lib.darwinSystem.
  # outputs = { self, nixpkgs }: … uses self.{shortRev,rev,…} via `or` fallbacks and
  # nixpkgs.{lib,outPath} — both satisfied. `lib` doesn't force `jobs`, so this is cheap.
  # ponytail: parens around `outputs {…}` then `.lib` — darwinSystem is at outputs.lib, not outputs top-level.
  darwin = {
    outPath = sources.nix-darwin;
    inherit
      ((import (sources.nix-darwin + "/flake.nix")).outputs {
        self = darwin;
        inherit (inputs) nixpkgs;
      })
      lib
      ;
  };

  mkNixos =
    name: extraModules:
    let
      inherit (pkgsFor "x86_64-linux") lib;
      # ponytail: nixosSystem lives only in nixpkgs' flake-extended lib, not in
      # `import nixpkgs {}.lib` (pure lib). Call eval-config.nix directly — that's
      # exactly what nixosSystem wraps, minus a flake.source injection we re-add below.
      evalConfig = import (sources.nixpkgs + "/nixos/lib/eval-config.nix");
    in
    evalConfig {
      inherit lib;
      system = null;
      modules = [
        ./configurations/nixos/${name}/default.nix
        {
          nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        }
      ]
      ++ extraModules;
      specialArgs = {
        flake = self;
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
    in
    darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = darwinPkgs;
      modules = [
        ./configurations/darwin/${name}/default.nix
        {
          home-manager.extraSpecialArgs = {
            flake = self;
          };
        }
      ]
      ++ extraModules;
      specialArgs = {
        flake = self;
      };
    };
in
{
  nixosConfigurations = {
    msi = mkNixos "msi" [
      {
        home-manager.extraSpecialArgs = {
          flake = self;
        };
      }
    ];
    home-server = mkNixos "home-server" [
      {
        home-manager.extraSpecialArgs = {
          flake = self;
        };
      }
    ];
    installer = mkNixos "installer" [ ];
  };
  darwinConfigurations = {
    "Volodias-MacBook-Pro" = mkDarwin "Volodias-MacBook-Pro" [ ];
  };
  shell = import ./shell.nix;
}
