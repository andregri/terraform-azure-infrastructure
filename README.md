# Terraform Azure Infrastructure

## Get Azure parameters
Login to Azure using cli:
```bash
az login
```

Get azure parameters:
```bash
export AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
export AZURE_CLIENT_ID="get from acloudguru"
export AZURE_CLIENT_SECRET="get from acloudguru"
```

## Create storage account for tfstate
```bash
cd bootstrap
terraform init
source ../.env
terraform apply
cd ..
```

If you want to run terraform locally, first you need to setup the terraform backend:
```bash
source .env
make tf-init-backend
```

## Setup CICD variables
Create the following variables or secrets on the CICD page of Gitlab or Github:
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_TENANT_ID
- ARM_SUBSCRIPTION_ID
- TF_RESOURCE_GROUP_NAME
