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
          commitizen.enable = true;
          actionlint.enable = true;
        };
      };

      # Development shell
      devShells.default = pkgs.mkShell {
        name = "nixos-config";
        packages = with pkgs; [
          just
          inputs.agenix.packages.${system}.default
          nix-output-monitor
          deploy-rs
        ];
        inherit (config.pre-commit) shellHook;
      };
    };
}
