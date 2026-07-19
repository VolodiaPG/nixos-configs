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
      formatter = pkgs.nixfmt;

      # Pre-commit hooks
      pre-commit.settings = {
        package = pkgs.prek;
        hooks = {
          nixfmt.enable = true;
          statix.enable = true;
          deadnix.enable = true;
          commitizen.enable = false;
          actionlint.enable = true;
        };
      };

      # Development shell
      devShells = {
        default = pkgs.mkShell {
          packages = [
            pkgs.just
            inputs.agenix.packages.${system}.default
            pkgs.deploy-rs
            pkgs.nvfetcher
            pkgs.git
            pkgs.nh
            pkgs.nixd
            pkgs.nixfmt
          ];
          inherit (config.pre-commit) shellHook;
        };
        ci = pkgs.mkShell {
          packages = [
            pkgs.deploy-rs
            pkgs.nvfetcher
          ];
        };
      };

    };
}
