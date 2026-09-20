{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.my.kubernetes;
in
{
  options = {
    my.kubernetes = {
      enable = mkEnableOption "K8S";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."kubelet/10-swap.conf".text = ''
      apiVersion: kubelet.config.k8s.io/v1beta1
      kind: KubeletConfiguration
      memorySwap:
        swapBehavior: LimitedSwap
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/rancher/k3s/agent/etc/kubelet.conf.d 0755 root root -"
      "L+ /var/lib/rancher/k3s/agent/etc/kubelet.conf.d/10-swap.conf - - - - /etc/kubelet/10-swap.conf"
    ];

    services.k3s = {
      enable = true;
      nodeName = config.networking.hostName;
      extraFlags = [
        "--disable=traefik"
        "--disable=servicelb"
        "--kubelet-arg=fail-swap-on=false"
        # Optional: Enable native K8s swap handling (K8s 1.28+)
        "--kubelet-arg=feature-gates=NodeSwap=true"
        # 4GiB box: reserve headroom so kubelet evicts gracefully before kernel OOM
        "--kubelet-arg=kube-reserved=memory=300Mi"
        "--kubelet-arg=system-reserved=memory=400Mi"
        "--kubelet-arg=eviction-hard=memory.available<300Mi"
      ];
      manifests.tailscale-secret = {
        source = config.age.secrets.tailscale-k8s-operator.path;
      };
      manifests.fizzy-secret = {
        source = config.age.secrets.fizzy-env.path;
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
            controllers.main.containers.main.resources = {
              requests = {
                memory = "512Mi";
                cpu = "100m";
              };
              limits.memory = "2Gi";
            };
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
