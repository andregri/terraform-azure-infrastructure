module "kubeadm-cluster" {
  source = "git::https://github.com/andregri/terraform-module-azure-vm.git?ref=feat/multi-vm"

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