{ pkgs, lib, ... }: {
  imports = [
    ./common.nix
    # If secrets/agenix.nix defines Home Manager specific configurations
    # beyond just age.secrets and age.identityPaths, it might be imported here.
    # However, typically, age.secrets are defined once and used by both NixOS and HM.
    # The agenix.homeManagerModules.default in flake.nix should handle HM integration.
  ];

  # The sops block is removed. Secrets are defined in a central agenix configuration
  # (e.g., secrets/agenix.nix, imported by the flake)
  # and accessed via config.age.secrets.<name>.path

  # sops-nix specific services and activation scripts are removed.
  # Agenix decrypts files at build time and places them in a store path,
  # or in /run/agenix/* if specified.
  # No separate user service like sops-nix is typically needed for agenix.

  # Example of how you might ensure secrets are available for a user service,
  # though agenix usually makes them available before user session starts.
  # systemd.user.services.my-user-service = {
  #   after = [ "agenix.target" ]; # Or specific agenix secret targets if granular control is needed
  #   wants = [ "agenix.target" ];
  # };
}
