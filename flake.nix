{
  description = "Volodia P.-G'.s system config";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixpkgs-unstable.follows = "nixpkgs";
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "https://flakehub.com/f/nixos/nixos-hardware/0";
    };

    srvos = {
      url = "github:volodiapg/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "https://flakehub.com/f/cachix/git-hooks.nix/0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
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
      url = "https://flakehub.com/f/nix-community/impermanence/0";
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
      };
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    disko = {
      # url = "https://flakeh  url = "https://github.com/NixOS/nixpkgs/pull/410328.diff";
      url = "github:nix-community/disko?ref=pull/1277/merge";
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

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
      };
    };

    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    flake-utils = {
      url = "https://flakehub.com/f/numtide/flake-utils/0";
    };

    nixos-unified.url = "github:srid/nixos-unified";

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
      };
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };

    bbr_classic = {
      url = "github:cmspam/bbr_classic";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    high-tide = {
      url = "github:volodiapg/high-tide";
      inputs.nixpkgs.follows = "nixpkgs";
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
      "https://attic.xuyh0120.win/lantian"
      "https://cache.nixos-cuda.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
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
      imports = builtins.map (fn: ./modules/flake-parts/${fn}) (
        builtins.attrNames (builtins.readDir ./modules/flake-parts)
      );

      perSystem =
        { system, ... }:
        {
          # Make our overlay available to the devShell
          # "Flake parts does not yet come with an endorsed module that initializes the pkgs argument.""
          # So we must do this manually; https://flake.parts/overlays#consuming-an-overlay
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ]; # ponytail: was lib.attrValues self.overlays — explicit single overlay avoids forcing all keys
            config = {
              cudaSupport = true;
              allowUnfree = true;
              # ponytail: mirror of common-nix-settings.nix predicate — nixpkgs.config in the
              # NixOS module only configures the system pkgs; the flake's perSystem pkgs is a
              # separate instance and needs its own predicate or mpv-rife eval fails on tensorrt.
              allowInsecurePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "tensorrt" ];
            };
          };

        };
    };
}
