# Rancher cluster on Azure

Create infrastructure with terraform:
```bash
export TF_VAR_resource_group_name=1-50f3ee82-playground-sandbox

az login

make tf-cleanup FOLDER=bootstrap
make tf-init-backend FOLDER=bootstrap
make tf-apply FOLDER=bootstrap

make tf-cleanup FOLDER=rancher
make tf-init-backend FOLDER=rancher
make tf-apply FOLDER=rancher
```

Post configuration with ansible:
```bash
cd rancher
source env

az network bastion tunnel --name "${BASTION_HOST_NAME}" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_0} --resource-port "22" --port "${VM_0_PORT}" &
az network bastion tunnel --name "${BASTION_HOST_NAME}" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_1} --resource-port "22" --port "${VM_1_PORT}" &
az network bastion tunnel --name "${BASTION_HOST_NAME}" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_2} --resource-port "22" --port "${VM_2_PORT}" &
az network bastion tunnel --name "${BASTION_HOST_NAME}" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_3} --resource-port "22" --port "${VM_3_PORT}" &

# register host key
ssh -o StrictHostKeyChecking=accept-new -p ${VM_0_PORT} testadmin@127.0.0.1
ssh -o StrictHostKeyChecking=accept-new -p ${VM_1_PORT} testadmin@127.0.0.1
ssh -o StrictHostKeyChecking=accept-new -p ${VM_2_PORT} testadmin@127.0.0.1
ssh -o StrictHostKeyChecking=accept-new -p ${VM_3_PORT} testadmin@127.0.0.1

ansible-playbook -i inventory.yaml rke2-playbook.yaml -u testadmin -k
ansible-playbook -i inventory.yaml rancher-playbook.yaml -u testadmin -k
```