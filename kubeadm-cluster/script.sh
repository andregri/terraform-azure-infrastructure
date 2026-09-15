# control plane 1
sudo apt update
sudo apt install -y ansible
git clone https://github.com/andregri/ansible-roles.git
cd ansible-roles
wget https://raw.githubusercontent.com/andregri/terraform-azure-infrastructure/refs/heads/main/kubeadm-cluster/kubeadm-init-azure-vm.yaml
ansible-playbook kubeadm-init-azure-vm.yaml

# kubeadm init
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --kubernetes-version v1.33.12 --control-plane-endpoint 10.0.2.4
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# kubeadm join
sudo kubeadm token create --print-join-command
sudo kubeadm init phase upload-certs --upload-certs

kubeadm join 10.0.2.4:6443 --token 8ep1qy.49dsa5ygocs2ix7l \
--discovery-token-ca-cert-hash sha256:8c30c6f4adfe5f8be996706ab700a1dd9d9aeb970a3b2ae03d4a986b2f37f0bc \
--control-plane --certificate-key f1e854e2d9826570de335c94032546f88459cc19ae3649746c396ecd3aabc821