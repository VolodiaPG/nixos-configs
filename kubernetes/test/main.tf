terraform {
  required_providers {
    multipass = { source = "larstobi/multipass", version = "~> 1.4" }
    local     = { source = "hashicorp/local" }
  }
}

resource "multipass_instance" "k3s" {
  name   = "k3s-test"
  cpus   = 2
  memory = "2GiB"
  disk   = "15GiB"
  image  = "24.04"

  cloudinit_file = local_file.cloud_init.filename
}

resource "local_file" "inventory" {
  filename = "${path.module}/inventory.yml"
  content  = <<-EOT
    k3s_cluster:
      children:
        server:
          hosts:
            ${multipass_instance.k3s.ipv4}:
        agent:
          hosts: {}
      vars:
        ansible_user: ubuntu
        ansible_ssh_private_key_file: ~/.ssh/id_ed25519
        ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
        k3s_version: v1.37.1+k3s1
        token: test-cluster-token
        api_endpoint: ${multipass_instance.k3s.ipv4}
        kubeconfig: ./kubeconfig
        server_config_yaml: |
          disable:
            - traefik
            - servicelb
          flannel-backend: none
          disable-network-policy: true
  EOT
}

resource "local_file" "cloud_init" {
  filename = "${path.module}/cloud-init.yml"
  content  = <<-EOT
    #cloud-config
    ssh_authorized_keys:
      - ${trimspace(file("~/.ssh/id_ed25519.pub"))}
  EOT
}

output "ip" {
  value = multipass_instance.k3s.ipv4
}
