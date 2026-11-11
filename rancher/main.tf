locals {
  prefix = "rancher"
  start_port = "50022"
  rancher_hostname = "rancher.company.internal"
}

module "rancher-cluster" {
  source = "git::https://github.com/andregri/terraform-module-azure-vm.git?ref=v1.2.3"

  enable_bastion      = true
  prefix              = local.prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  vm_count            = 3
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
      "export VM_${i}_PORT=${local.start_port + i}"
    ]
  ))
}

resource "local_file" "inventory" {
  filename = "${path.module}/inventory.yaml"
  content = yamlencode({
    all : {
      vars : {
        # rke2
        kube_vip : azurerm_lb.kube-vip.private_ip_address
        rke2_version: "v1.36.6+rke2r1"
        rke2_shared_token: "my_shared_token"
        # cert
        intermediate_ca_chain: abspath("${path.module}/cert/cacerts.pem")
        intermediate_ca_key: abspath("${path.module}/${local_sensitive_file.intermediate_key.filename}")
        # registry credentials
        registry_url: azurerm_container_registry.acr.login_server
        registry_name: azurerm_container_registry.acr.name
        # cert manager
        cert_manager_version: "v1.21.3"
        # rancher
        rancher_version: "2.15.3"
        rancher_hostname: local.rancher_hostname
        rancher_bootstrap_password: "admin"
        # flux
        flux_repo_url: "https://github.com/andregri/kubernetes-pod-example.git"
        flux_repo_branch: "main"
        flux_repo_path: "manifests"
        # keyvault
        keyvault_name: azurerm_key_vault.kv.name
        tenant_id: var.tenant_id
        client_id: var.client_id
        client_secret: var.client_secret
      },
      children : {
        localhost : {
          hosts : {
            localhost : {
              ansible_connection : "local"
            }
          }
        },
        control_plane : {
          hosts : {
            for i, host in module.rancher-cluster.vm_hostnames :
            host => {
              private_ip : module.rancher-cluster.vm_private_ips[i]
              ansible_user : "testadmin"
              ansible_host : "127.0.0.1"
              ansible_port : local.start_port + i
              ansible_ssh_common_args : "-o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null"
            } if i < 3
          }
        },
        workers : {
          hosts : {
            for i, host in module.rancher-cluster.vm_hostnames :
            host => {
              private_ip : module.rancher-cluster.vm_private_ips[i]
              ansible_user : "testadmin"
              ansible_host : "127.0.0.1"
              ansible_port : local.start_port + i
              ansible_ssh_common_args : "-o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null"
            } if i >= 3
          }
        }
      }
    }
  })
}