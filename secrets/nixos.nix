{ ... }: {
  imports = [
    ./common.nix
    ./agenix.nix # Import the agenix configuration for NixOS
  ];

  # The sops block is removed. Secrets are defined in secrets/agenix.nix
  # and accessed via config.age.secrets.<name>.path
}
