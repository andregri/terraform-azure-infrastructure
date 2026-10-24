# Rancher cluster on Azure

Create infrastructure with terraform:
```bash
export TF_VAR_resource_group_name=1-a22a3ad2-playground-sandbox

az login

make tf-cleanup FOLDER=bootstrap
make tf-init-backend FOLDER=bootstrap
make tf-apply FOLDER=bootstrap

make tf-cleanup FOLDER=rancher
make tf-init-backend FOLDER=rancher
cd rancher && terraform apply -replace="terraform_data.appgw_pfx" -auto-approve && cd ..
make tf-apply FOLDER=rancher
```

## Ansible: install rke2 + rancher prime

Post configuration with ansible:
```bash
cd rancher
source env

az network bastion tunnel --name "${BASTION_HOST_NAME}" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_0} --resource-port "22" --port "${VM_0_PORT}" &
az network bastion tunnel --name "${BASTION_HOST_NAME}" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_1} --resource-port "22" --port "${VM_1_PORT}" &
az network bastion tunnel --name "${BASTION_HOST_NAME}" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_2} --resource-port "22" --port "${VM_2_PORT}" &
az network bastion tunnel --name "${BASTION_HOST_NAME}" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_3} --resource-port "22" --port "${VM_3_PORT}" &

ansible-playbook -i inventory.yaml rke2-playbook.yaml -u testadmin -k
ansible-playbook -i inventory.yaml rancher-playbook.yaml -u testadmin -k
```

Or run a more complete playbook:
```bash
ansible-playbook -i inventory.yaml /Users/andreagrillo/Downloads/github-personal/ansible-playbook-rke2-rancher/install-rke2-rancher-private-ca.yaml  -u testadmin -k
```

or download playbooks from: https://github.com/andregri/ansible-roles.git

## Set etc/hosts with app gateway public ip
```bash
sudo $app_gw_public_ip rancher.company.internal
```

## Run kubectl commands
Login to the first VM:
```bash
ssh testadmin@127.0.0.1 -p ${VM_0_PORT} -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null
```

Inside the VM:
```bash
sudo su -
alias kubectl="/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
```

## Test

```bash
curl -vk --resolve rancher.company.internal:443:10.0.2.5 https://rancher.company.internal/
curl -vk --cacert /etc/rancher/rke2/cacerts.pem --resolve rancher.company.internal:443:10.0.2.5 https://rancher.company.internal/
```

show certificate served by traaefik:
```bash
openssl s_client \
  -connect 10.0.2.5:443 \
  -servername rancher.company.internal \
  -showcerts </dev/null
```

verify cert chain:
```bash
openssl s_client \
  -connect 10.0.2.5:443 \
  -servername rancher.company.internal \
  -CAfile /etc/rancher/rke2/cacerts.pem \
  -verify_return_error </dev/null
```

Test app gw connectivity:
```bash
nc -vz -w 5 168.61.42.77 80
nc -vz -w 5 168.61.42.77 443

curl -v --connect-timeout 5 \
  --resolve rancher.company.internal:80:168.61.42.77 \
  http://rancher.company.internal/

curl -vk --connect-timeout 5 \
  --resolve rancher.company.internal:443:168.61.42.77 \
  https://rancher.company.internal/
```