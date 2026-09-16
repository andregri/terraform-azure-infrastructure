module "kubeadm-cluster" {
  source = "git::https://github.com/andregri/terraform-module-azure-vm.git?ref=v1.2.0"

  enable_bastion      = true
  prefix              = "multinode"  
  location            = "eastus"
  resource_group_name = var.resource_group_name
  vm_count            = 4
  vm_size             = "Standard_D2s_v3"

  cloud_init = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    apt update && \
    apt install -y ansible && \
    git clone https://github.com/andregri/ansible-roles.git && \
    cd ansible-roles && \
    ansible-playbook --inventory localhost, --connection local --user testadmin --extra-vars "target_hosts=localhost" containerd-kubeadm.yaml
  EOF
}

resource "local_file" "env" {
  filename = "${path.module}/env"
  content  = join("\n", [
    for i, id in module.kubeadm-cluster.vm_ids : "export VM_HOST_ID_${i}=\"${id}\""
  ])
}

resource "local_file" "inventory" {
  filename = "${path.module}/inventory.yaml"
  content = yamlencode({
    all : {
      children: {
        control_plane: {
          hosts: {
            for i, host in module.kubeadm-cluster.vm_hostnames :
              host => {
                private_ip : module.kubeadm-cluster.vm_private_ips[i],
                ansible_user: "testadmin",
                ansible_host: "127.0.0.1",
                ansible_port: 10022 + i
              } if i < 3
          }
        },
        workers: {
          hosts: {
            for i, host in module.kubeadm-cluster.vm_hostnames :
              host => {
                private_ip : module.kubeadm-cluster.vm_private_ips[i],
                ansible_user: "testadmin",
                ansible_host: "127.0.0.1",
                ansible_port: 10022 + i
              }  if i >= 3
          }
        } 
      }
    }
  })
}