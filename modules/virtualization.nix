_: {
  config.nixos.virt = _: {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
  };
}
