{
  description = "Volodia P.-G'.s system config";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore";
      };
    };

    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    beam-flakes = {
      url = "github:elixir-tools/nix-beam-flakes";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };

    elixir-expert = {
      url = "github:elixir-lang/expert";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        beam-flakes.follows = "beam-flakes";
      };
    };

    plugins-treesitter-textobjects = {
      url = "github:nvim-treesitter/nvim-treesitter-textobjects/main";
      flake = false;
    };

    plugins-inlay-hints = {
      url = "github:MysticalDevil/inlay-hints.nvim";
      flake = false;
    };

    plugins-catppuccin = {
      url = "github:catppuccin/nvim";
      flake = false;
    };

    plugins-vimtex = {
      url = "github:lervag/vimtex";
      flake = false;
    };

    plugins-opencode-nvim = {
      url = "github:NickvanDyke/opencode.nvim";
      flake = false;
    };

    vim = {
      url = "github:volodiapg/vim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixCats.follows = "nixCats";
        elixir-expert.follows = "elixir-expert";
        plugins-catppuccin.follows = "plugins-catppuccin";
        plugins-inlay-hints.follows = "plugins-inlay-hints";
        plugins-opencode-nvim.follows = "plugins-opencode-nvim";
        plugins-treesitter-textobjects.follows = "plugins-treesitter-textobjects";
        plugins-vimtex.follows = "plugins-vimtex";
      };
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
        systems.follows = "flake-utils/systems";
      };
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mosh = {
      # url = "github:zhaofengli/mosh/fish-wcwidth";
      url = "github:jdrouhard/mosh";
      flake = false;
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-cache-proxy = {
    #   url = "github:volodiapg/nix-cache-proxy";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     flake-parts.follows = "flake-parts";
    #   };
    # };

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        treefmt-nix.follows = "treefmt-nix";
        flake-parts.follows = "flake-parts";
        import-tree.follows = "import-tree";
      };
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        blueprint.follows = "blueprint";
        bun2nix.follows = "bun2nix";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    vpnconfinement = {
      url = "github:Maroka-chan/VPN-Confinement";
    };

    website-builder = {
      url = "github:rasmus-kirk/website-builder";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        vpnconfinement.follows = "vpnconfinement";
        website-builder.follows = "website-builder";
      };
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    systems.url = "github:nix-systems/default";

    nixos-unified.url = "github:srid/nixos-unified";
    # nixos-unified.url = "path:/home/volodia/Documents/nixos-unified";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # nix-rosetta-builder = {
    #   url = "github:cpick/nix-rosetta-builder";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    nixos-apple-silicon = {
      # url = "github:nix-community/nixos-apple-silicon/release-25.11";
      url = "github:nix-community/nixos-apple-silicon";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        noctalia-qs.follows = "noctalia-qs";
      };
    };

    tidal-to-strawberry = {
      url = "github:volodiapg/tidal-to-strawberry";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    crane.url = "github:ipetkov/crane";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flat-flake = {
      url = "github:linyinfeng/flat-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        treefmt-nix.follows = "treefmt-nix";
        crane.follows = "crane";
        rust-overlay.follows = "rust-overlay";
      };
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org?priority=10"
      "https://volodiapg.cachix.org?priority=20"
      "https://install.determinate.systems?priority=50"
      "https://cache.numtide.com?priority=50"
      "https://nixos-apple-silicon.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Wired using https://nixos-unified.org/autowiring.html
  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [
        inputs.flat-flake.flakeModules.flatFlake
      ]
      ++ (
        with builtins; map (fn: ./modules/flake-parts/${fn}) (attrNames (readDir ./modules/flake-parts))
      );

      flatFlake.config.allowed = [ ];

      perSystem =
        { lib, system, ... }:
        {
          # Make our overlay available to the devShell
          # "Flake parts does not yet come with an endorsed module that initializes the pkgs argument.""
          # So we must do this manually; https://flake.parts/overlays#consuming-an-overlay
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = lib.attrValues self.overlays;
            config.allowUnfree = true;
          };

        };
    };
}
