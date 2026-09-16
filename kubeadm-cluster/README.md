## Fine tuning of Azure environment

### VM size

Check available vm-sizes per region:
```bash
az vm list-sizes --location "southcentralus" -o table |less
```

Check available skus and policies:
```bash
az vm list-skus --location "southcentralus" -o table |grep -Ei "Standard" |grep -Ei "None" |grep -Ei "D2" |less
```

or check the available vms directly on Azure Portal.

### Debug cloud-init script

Check cloud-init logs:
```bash
sudo cloud-init status --long
sudo cat /var/log/cloud-init-output.log
```

## Kubeadm commands

Common env vars:
```bash
export CONTROL_PLANE_ENDPOINT="10.0.2.7" # private ip of first vm
export KUBE_VERSION="v1.33.12"
export KUBEADM_TOKEN=
export KUBEADM_CERT_KEY=
export KUBEADM_CERT_CA_HASH=
export WORKER_NODE_HOSTNAME="multinode-vm-3"
```

### Init first control plane node

```bash
# kubeadm init on first control plane node
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --kubernetes-version ${KUBE_VERSION} --control-plane-endpoint ${CONTROL_PLANE_ENDPOINT}
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Join other control plane nodes

```bash
# print join command (contains token and )
sudo kubeadm token create --print-join-command

# print certificate key
sudo kubeadm init phase upload-certs --upload-certs

sudo kubeadm join ${CONTROL_PLANE_ENDPOINT}:6443 \
    --token ${KUBEADM_TOKEN} \
    --discovery-token-ca-cert-hash ${KUBEADM_CERT_CA_HASH} \
    --control-plane \
    --certificate-key ${KUBEADM_CERT_KEY}
```

### Join worker nodes

```bash
# kubeadm join worker node
sudo kubeadm join ${CONTROL_PLANE_ENDPOINT}:6443 \
    --token ${KUBEADM_TOKEN} \
    --discovery-token-ca-cert-hash ${KUBEADM_CERT_CA_HASH}

# relabel worker node
kubectl label node ${WORKER_NODE_HOSTNAME} node-role.kubernetes.io/worker=worker
```

## Use Ansible with Azure Bastion
```bash
az login

source env

az network bastion tunnel --name "multinode-network-bastion" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_0} --resource-port "22" --port "10022" &
az network bastion tunnel --name "multinode-network-bastion" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_1} --resource-port "22" --port "10023" &
az network bastion tunnel --name "multinode-network-bastion" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_2} --resource-port "22" --port "10024" &
az network bastion tunnel --name "multinode-network-bastion" --resource-group ${TF_VAR_resource_group_name} --target-resource-id ${VM_HOST_ID_3} --resource-port "22" --port "10025" &

ssh -o StrictHostKeyChecking=accept-new -p 10022 testadmin@127.0.0.1 # ask for vm password
exit

ssh -o StrictHostKeyChecking=accept-new -p 10023 testadmin@127.0.0.1 # ask for vm password
exit

ssh -o StrictHostKeyChecking=accept-new -p 10024 testadmin@127.0.0.1 # ask for vm password
exit

ssh -o StrictHostKeyChecking=accept-new -p 10025 testadmin@127.0.0.1 # ask for vm password
exit

cd kubeadm-cluster

ansible-playbook -i inventory.yaml kubeadm-playbook.yaml -u testadmin -k

```
