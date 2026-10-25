# Rancher cluster on Azure

Create infrastructure with terraform:
```bash
export TF_VAR_resource_group_name=1-219fc98c-playground-sandbox

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
```

Git clone and run rancher playbook:
```bash
git clone https://github.com/andregri/ansible-playbook-rke2-rancher.git /tmp/ansible-playbook-rke2-rancher
ansible-playbook -i inventory.yaml /tmp/ansible-playbook-rke2-rancher/install-rke2-rancher-private-ca.yaml  -u testadmin -k
```

## Set etc/hosts with app gateway public ip
Add racher hostname to /etc/hosts:
```bash
APPGW_PUBLIC_IP=$(terraform output -raw app_gateway_public_ip)
echo "${APPGW_PUBLIC_IP} rancher.company.internal" | sudo tee -a /etc/hosts
```

Test connectivity towards app gateway:
```bash
nc -vz -w 5 ${APPGW_PUBLIC_IP} 80
nc -vz -w 5 ${APPGW_PUBLIC_IP} 443

curl -v --connect-timeout 5 \
  --resolve rancher.company.internal:80:${APPGW_PUBLIC_IP} \
  http://rancher.company.internal/

curl -vk --connect-timeout 5 \
  --resolve rancher.company.internal:443:${APPGW_PUBLIC_IP} \
  https://rancher.company.internal/
```

## SSH into vm0 and use kubectl
Login into vm0:
```bash
ssh testadmin@127.0.0.1 -p ${VM_0_PORT} -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null
```

Alias kubectl:
```bash
sudo su -
alias kubectl="/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
```

Test connectivity:
```bash
LB_PRIVATE_IP=$(terraform output -raw load_balancer_internal_ip_addr)
curl -vk --resolve rancher.company.internal:443:${LB_PRIVATE_IP} https://rancher.company.internal/
curl -vk --cacert /etc/rancher/rke2/cacerts.pem --resolve rancher.company.internal:443:${LB_PRIVATE_IP} https://rancher.company.internal/
```

show certificate served by traaefik:
```bash
openssl s_client \
  -connect ${LB_PRIVATE_IP}:443 \
  -servername rancher.company.internal \
  -showcerts </dev/null
```

verify cert chain:
```bash
openssl s_client \
  -connect ${LB_PRIVATE_IP}:443 \
  -servername rancher.company.internal \
  -CAfile /etc/rancher/rke2/cacerts.pem \
  -verify_return_error </dev/null
```