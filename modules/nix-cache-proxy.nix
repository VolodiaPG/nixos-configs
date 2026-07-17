_: {
  config.nixos.nix-cache-proxy = _: {
    # nixos side: all commented out in original
  };

  # ponytail: nix-cache-proxy input is commented out in flake.nix, disable darwin side too
  config.darwin.mac = _: { };
}
