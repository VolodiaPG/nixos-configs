# Top-level configuration for everything in this repo.
#
# Values are set in 'config.nix' in repo root.
{ lib, ... }:
let
  userSubmodule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
      };
      username = lib.mkOption {
        type = lib.types.str;
      };
      email = lib.mkOption {
        type = lib.types.str;
      };
      sshKey = lib.mkOption {
        type = lib.types.str;
        description = ''
          SSH public key
        '';
      };
      signingKey = lib.mkOption {
        type = lib.types.str;
      };
      keys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
      hashedPassword = lib.mkOption {
        type = lib.types.str;
      };
      homeDirectory = lib.mkOption {
        type = lib.types.functionTo lib.types.path;
      };
      tailname = lib.mkOption {
        type = lib.types.str;
      };
      cachixName = lib.mkOption {
        type = lib.types.str;
      };
      trusted-substituters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
      trusted-public-keys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
    };
  };
in
{
  imports = [
    ../../config.nix
  ];
  options = {
    me = lib.mkOption {
      type = userSubmodule;
    };
  };
}
