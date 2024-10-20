{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    discord
    insomnia
    inputs.zen-browser.packages.${pkgs.stdenv.system}.specific
    (steam.override {extraPkgs = _: [mono gtk3 gtk3-x11 libgdiplus zlib];}).run
    popcorntime
  ];
}
