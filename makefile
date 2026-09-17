.PHONY: bootstrap

bootstrap/terraform.tfstate:
	@echo "Bootstrapping Terraform backend..."
	cd bootstrap && terraform apply -auto-approve

bootstrap: bootstrap/terraform.tfstate

# USAGE: e.g. make tf-init-backend FOLDER=bootstrap
.PHONY: tf-init-backend
tf-init-backend:
	@echo "Initializing Terraform backend of $(FOLDER)..."
	cd $(FOLDER) && terraform init \
		-backend-config="resource_group_name=${TF_VAR_resource_group_name}" \
		-backend-config="storage_account_name=tfstatestorageacc4562" \
		-backend-config="container_name=tfstate" \
		-backend-config="key=terraform.tfstate" \
		-backend-config="use_azuread_auth=true" \
		-backend-config="use_oidc=false"

.PHONY: kubeadm-cluster
kubeadm-cluster:
	@echo "Creating Kubernetes cluster using kubeadm..."
	cd kubeadm-cluster && terraform apply -auto-approve

.PHONY: tf-apply
tf-apply:
	@echo "Apply terraform configuration in $(FOLDER)/..."
	cd $(FOLDER) && terraform apply -auto-approve

.PHONY: tf-cleanup
tf-cleanup:
	@echo "Removing .terraform folder and tfstate in $(FOLDER)/..."
	cd $(FOLDER) && rm -rf .terraform && rm terraform.tfstate*
