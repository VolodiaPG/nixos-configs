# https://www.tweag.io/blog/2020-07-31-nixos-flakes/

# To switch from channels to flakes execute:
# cd /etc/nixos
# sudo wget -O flake.nix https://gist.githubusercontent.com/misuzu/80af74212ba76d03f6a7a6f2e8ae1620/raw/flake.nix
# sudo git init
# sudo git add . # won't work without this
# nix-shell -p nixFlakes --run "sudo nix --experimental-features 'flakes nix-command' build .#nixosConfigurations.$(hostname).config.system.build.toplevel"
# sudo ./result/bin/switch-to-configuration switch

# Now nixos-rebuild can use flakes:
# sudo nixos-rebuild switch --flake /etc/nixos

# To update flake.lock run:
# sudo nix flake update --commit-lock-file /etc/nixos

{
  description = "lun's system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nuxpkgs.url = "github:nix-community/NUR";
    home-manager.url = "github:nix-community/home-manager/release-21.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {}:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      lib = nixpkgs.lib;
    in
    {
      homeManagerConfigurations = {
        lun = home-manager.lib.homeManagerConfiguration {
          inherit system pkgs;
          username = "lun";
          homeDirectory = "/home/lun";
          stateVersion = "21.05";
          configuration = {
            imports = [ ./lun-home.nix ];
          };
        };
      };
      nixosConfigurations = {
        ux430ua = lib.nixosSystem {
          inherit system;
          modules = [ ./machines/ux430ua/configuration.nix ];
        };
      };
    };
}


{
  description = "Volodia P.-G'.s system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nurpkgs.url = github:nix-community/NUR;
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      lib = nixpkgs.lib;
    in
    {
      homeManagerConfigurations = {
        nix.settings.experimental-features = "nix-command flakes";

        volodia = home-manager.lib.homeManagerConfiguration {
          inherit system pkgs;
          username = "volodia";
          homeDirectory = "/home/volodia";
          stateVersion = "22.05";
          configuration = {
            imports = [ ./users/volodia.home.nix ];
          };
        };
      };
      nixosConfigurations = {
        ux430ua = lib.nixosSystem {
          inherit system;
          modules = [ ./machines/ux430ua/configuration.nix ];
        };
      };
    };
}

#   nixosConfigurations = builtins.listToAttrs (builtins.map
#     (system: {
#       name = system.config.networking.hostName;
#       value = system;
#     })
#     [
#       (inputs.nixpkgs.lib.nixosSystem {
#         system = "x86_64-linux";
#         # Things in this set are passed to modules and accessible
#         # in the top-level arguments (e.g. `{ pkgs, lib, inputs, ... }:`).
#         specialArgs = {
#           inherit inputs;
#         };
#         modules = [
#           inputs.home-manager.nixosModules.home-manager
#           inputs.nur.nixosModules.nur

#           ({ pkgs, ... }: {
#             environment.etc =
#               {
#                 "nix/channels/nixpkgs".source = inputs.nixpkgs.outPath;
#                 "nix/channels/home-manager".source = inputs.home-manager.outPath;
#                 "nix/channels/nurpkgs".source = inputs.nurpkgs.outPath;
#               };

#             nix.nixPath =
#               [
#                 "nixpkgs=/etc/nix/channels/nixpkgs"
#                 "home-manager=/etc/nix/channels/home-manager"
#                 "nurpkgs=/etc/nix/channels/nurpkgs"
#               ];

#             nix.settings.experimental-features = "nix-command flakes";

#             home-manager.useGlobalPkgs = true;
#           })
#         ];
#       })
#     ]
#   );
# };
# }
