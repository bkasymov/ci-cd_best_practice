#!/bin/bash


set -e

apt update && apt upgrade -y

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install containerd
apt install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Load necessary modules
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set up required sysctl params
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Install kubeadm, kubelet, and kubectl
apt-get update
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Initialize the Kubernetes cluster
kubeadm init --pod-network-cidr=10.244.0.0/16

# Set up kubectl for the root user
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico network plugin
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Allow scheduling on the control-plane node
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Wait for the cluster to be ready
echo "Waiting for the cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# TODO add install ingress controller nginx
# TODO convert to ansible playbook

kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec": {"externalIPs":["YOUR_SERVER_IP"]}}'

echo "Kubernetes single-node cluster is now set up!"
