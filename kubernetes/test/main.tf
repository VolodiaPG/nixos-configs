terraform {
  required_providers {
    multipass = { source = "larstobi/multipass", version = "~> 1.4" }
    local     = { source = "hashicorp/local" }
  }
}

resource "multipass_instance" "k3s" {
  name   = "k3s-test"
  cpus   = 4
  memory = "6GiB"
  disk   = "25GiB"
  image  = "26.04"

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

output "multipass" {
  value = multipass_instance.k3s.name
}
