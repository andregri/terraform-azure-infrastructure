module "simple" {
  source = "git::https://github.com/andregri/terraform-module-azure-vm.git?ref=v1.1.1"

  prefix              = "simple"
  resource_group_name = var.resource_group_name
}