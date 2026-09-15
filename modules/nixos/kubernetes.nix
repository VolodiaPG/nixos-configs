{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.mykubernetes;
in
{
  options = {
    services.mykubernetes = {
      enable = mkEnableOption "K8S";
    };
  };

  config = mkIf cfg.enable {
    services.k3s = {
      enable = true;
      nodeName = config.networking.hostName;
      manifests.tailscale-secret = {
        source = config.age.secrets.tailscale-k8s-operator.path;
      };
      autoDeployCharts.tailscale-operator = {
        name = "tailscale-operator";
        repo = "https://pkgs.tailscale.com/helmcharts";
        version = "1.102.3";
        hash = "sha256-wkQAFN8E/fG2e1PapCkNe4eFhM9HAvmxtQ9RumRJmmo=";
        targetNamespace = "tailscale-operator";
        createNamespace = true;
      };
    };
  };
}
