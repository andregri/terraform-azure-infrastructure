.PHONY: tf-init-backend
tf-init-backend:
	@echo "Initializing Terraform backend..."
	terraform init \
		-backend-config="resource_group_name=${TF_VAR_resource_group_name}" \
		-backend-config="storage_account_name=tfstatestorageacc4562" \
		-backend-config="container_name=tfstate" \
		-backend-config="key=terraform.tfstate"