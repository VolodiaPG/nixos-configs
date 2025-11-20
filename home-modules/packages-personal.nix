{
  pkgs,
  inputs,
  ...
}:
{
  home.packages = [
    pkgs.nvim
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.opencode
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.devenv
  ];
}
