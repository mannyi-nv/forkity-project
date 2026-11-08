# Set the hostname for master and worker nodes
- sudo hostnamectl set-hostname k8s-master
- sudo hostnamectl set-hostname k8s-worker

# Set k8s and kubedm version variables
- export K8S_VER="1.33.5-00"
- export KUBEADM_K8S_VERSION="v1.33.5"

# Disable Swap
- sudo swapoff -a
- sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load Kernel Modules
- cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
- sudo modprobe overlay
- sudo modprobe br_netfilter

# Configure Sysctl Networking
- cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
- sudo sysctl --system

# Install prerequisites ???????
- sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https

# Add Docker/Containerd repo (using official Docker repo for containerd) ???????
- sudo mkdir -p /etc/apt/keyrings
- curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
- sudo apt update
- sudo apt install -y containerd.io

# Generate default configuration and enforce SystemdCgroup ???????
- sudo mkdir -p /etc/containerd
- containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
- sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart and verify containerd ???????
- sudo systemctl restart containerd
- sudo systemctl enable containerd
- sudo systemctl status containerd --no-pager

# Install Kubernetes Packages (Execute on ALL Nodes)
- sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl gpg

# Download the public signing key
- sudo mkdir -p -m 755 /etc/apt/keyrings
- curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the apt repository source
- echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install packages and pin versions to prevent unintended auto-upgrades
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# On the Master node only
- kubeadm init --pod-network-cidr=10.244.0.0/16
- mkdir -p $HOME/.kube
- sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
- sudo chown $(id -u):$(id -g) $HOME/.kube/config
- kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
- kubectl get pods -A
- kubectl get nodes

# On the Worker node only
kubeadm join 10.0.35.70:6443 --token 8paztu.<token> \
        --discovery-token-ca-cert-hash sha256:<digest>


