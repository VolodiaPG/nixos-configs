{ inputs, ... }:
{
  imports = [
    inputs.git-hooks.flakeModule
  ];

  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      # Formatter
      formatter = pkgs.nixfmt-rfc-style;

      # Pre-commit hooks
      pre-commit.settings.hooks = {
        nixfmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        commitizen.enable = true;
        actionlint.enable = true;
      };

      # Development shell
      devShells.default = pkgs.mkShell {
        name = "nixos-config";
        packages = with pkgs; [
          git
          nixfmt-rfc-style
          just
          inputs.agenix.packages.${system}.default
        ];
        inherit (config.pre-commit) shellHook;
      };

      # Packages
      packages = {
        inherit (pkgs) lix;
      };

      # Apps
      apps = {
        neovim = {
          type = "app";
          program = "${inputs.vim.packages.${system}.default}/bin/nvim";
        };
      };
    };
}
