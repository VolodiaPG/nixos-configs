# Bootstrapping

Add bw-auth-token with datastring token with the machine token from bitwarden
Do that in tailscale-operator and production namespaces

To force kyverno to create the netpol and DNS for tailnet:
k annotate ns production refresh=$(date +%s) --overwrite
kubectl annotate dnsconfig ts-dns refresh=$(date +%s) --overwrite
