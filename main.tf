module "simple" {
  source = "git::https://github.com/andregri/terraform-module-azure-vm.git"

  prefix              = "simple"
  resource_group_name = var.resource_group_name
}