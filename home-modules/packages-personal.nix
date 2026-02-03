{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs.opencode = {
    enable = true;
    settings = {
      "plugin" = [
        # "@plannotator/opencode@latest"
        "@simonwjackson/opencode-direnv@latest"
        "@tarquinen/opencode-dcp@latest"
        "@knikolov/opencode-plugin-simple-memory@latest"
      ];

    };
  };

  home.activation.opencode-delete-plugin-cache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -rf ${config.xdg.configHome}/opencode/node_modules
  '';

  home.packages = [
    pkgs.cachix
    pkgs.nvim
    pkgs.devenv
  ];
}
