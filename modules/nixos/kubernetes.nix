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
      extraFlags = [
        "--kubelet-arg=fail-swap-on=false"
        # Optional: Enable native K8s swap handling (K8s 1.28+)
        "--kubelet-arg=feature-gates=NodeSwap=true"
      ];
      manifests.tailscale-secret = {
        source = config.age.secrets.tailscale-k8s-operator.path;
      };
      autoDeployCharts = {
        tailscale-operator = {
          name = "tailscale-operator";
          repo = "https://pkgs.tailscale.com/helmcharts";
          version = "1.102.3";
          hash = "sha256-wkQAFN8E/fG2e1PapCkNe4eFhM9HAvmxtQ9RumRJmmo=";
          targetNamespace = "tailscale-operator";
          createNamespace = true;
        };
        immich = {
          name = "immich";
          repo = "oci://ghcr.io/immich-app/immich-charts/immich";
          version = "0.13.2";
          hash = "sha256-tSi6ESKCJ6Anhg+fwLJHf3LsHfuQjcEnoFLOruHiOh4=";
          targetNamespace = "immich";
          createNamespace = true;
          values = {
            immich.persistence.library.existingClaim = "immich-pvc";
            machine-learning.enabled = false;
            valkey.enabled = true; # REDIS_HOSTNAME defaults to <release>-valkey, so enable it
            controllers.main.containers.main.env = {
              DB_HOSTNAME.value = "database-rw.immich.svc.cluster.local";
              DB_DATABASE_NAME.value = "immich";
              DB_USERNAME.value = "immich";
              DB_PASSWORD.valueFrom.secretKeyRef = {
                name = "database-app";
                key = "password";
              };
            };
          };
        };
        postgresql-pg = {
          name = "cloudnative-pg";
          repo = "https://cloudnative-pg.github.io/charts";
          hash = "sha256-Zo4GX/U1CNWCOHiP01s1WpJQYIQ2KalR3w5qk2Lm0y8=";
          version = "0.29.0";
          targetNamespace = "cnpg-system";
          createNamespace = true;
        };
      };
    };
  };
}
