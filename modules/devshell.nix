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
      formatter = pkgs.nixfmt;

      pre-commit.settings = {
        package = pkgs.prek;
        hooks = {
          nixfmt = {
            enable = true;
            excludes = [ "_sources/generated.nix" ];
          };
          statix.enable = true;
          deadnix = {
            enable = true;
            excludes = [ "_sources/generated.nix" ];
          };
          commitizen.enable = true;
          actionlint.enable = true;
        };
      };

      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            just
            inputs.agenix.packages.${system}.default
            deploy-rs
            nvfetcher
            git
            nh
            nixd
            nixfmt
          ];
          inherit (config.pre-commit) shellHook;
        };
        ci = pkgs.mkShell {
          packages = with pkgs; [
            deploy-rs
            nvfetcher
          ];
        };
      };

    };
}
