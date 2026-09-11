# Terraform Azure Infrastructure

## Setup Azure credentials
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

Create the json file:
```bash
cat <<EOF
{
    "clientSecret": "${AZURE_CLIENT_SECRET}",
    "subscriptionId": "${AZURE_SUBSCRIPTION_ID}",
    "tenantId": "${AZURE_TENANT_ID}",
    "clientId": "${AZURE_CLIENT_ID}"
}
EOF
```