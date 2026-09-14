module "kubeadm-cluster" {
  source = "git::https://github.com/andregri/terraform-module-azure-vm.git?ref=feat/multi-vm"

  enable_bastion      = true
  prefix              = "node"
  vm_count            = 4
}