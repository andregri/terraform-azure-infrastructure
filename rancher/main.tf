locals {
  prefix = "rancher"
}

module "rancher-cluster" {
  source = "git::https://github.com/andregri/terraform-module-azure-vm.git?ref=feat/outputs"

  enable_bastion      = true
  prefix              = local.prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  vm_count            = 4
  vm_size             = "Standard_D2s_v3"

  cloud_init = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    apt update && \
    apt install -y ansible && \
    git clone https://github.com/andregri/ansible-roles.git && \
    cd ansible-roles
  EOF
}

resource "local_file" "env" {
  filename = "${path.module}/env"
  content = join("\n", concat(
    [
      for i, id in module.rancher-cluster.vm_ids :
      "export VM_HOST_ID_${i}=\"${id}\""
    ],
    [
      "export BASTION_HOST_NAME=${module.rancher-cluster.bastion_host_name}"
    ],
    [
      for i, _ in module.rancher-cluster.vm_hostnames :
      "export VM_${i}_PORT=${10022 + i}"
    ]
  ))
}

resource "local_file" "inventory" {
  filename = "${path.module}/inventory.yaml"
  content = yamlencode({
    all : {
      vars : {
        kube_vip : azurerm_lb.kube-vip.private_ip_address
      },
      children : {
        control_plane : {
          hosts : {
            for i, host in module.rancher-cluster.vm_hostnames :
            host => {
              private_ip : module.rancher-cluster.vm_private_ips[i],
              ansible_user : "testadmin",
              ansible_host : "127.0.0.1",
              ansible_port : 10022 + i
            } if i < 3
          }
        },
        workers : {
          hosts : {
            for i, host in module.rancher-cluster.vm_hostnames :
            host => {
              private_ip : module.rancher-cluster.vm_private_ips[i],
              ansible_user : "testadmin",
              ansible_host : "127.0.0.1",
              ansible_port : 10022 + i
            } if i >= 3
          }
        }
      }
    }
  })
}