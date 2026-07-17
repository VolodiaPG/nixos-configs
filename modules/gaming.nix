_: {
  config.nixos.gaming =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
      # ponytail: steam + 32bit graphics only on x86_64, ARM doesn't support it
      programs.steam.enable = pkgs.stdenv.hostPlatform.isx86_64;
      environment.systemPackages = lib.optionals pkgs.stdenv.hostPlatform.isx86_64 (
        with pkgs;
        [
          (steam.override {
            extraPkgs = _: [
              mono
              gtk3
              gtk3-x11
              libgdiplus
              zlib
            ];
          }).run
          popcorntime
          qbittorrent
        ]
      );
    };
}
