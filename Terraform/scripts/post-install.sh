#!/bin/bash
set -euo pipefail

# start sonarqube container image
docker run -d --name sonarqube -p 9000:9000 sonarqube:community

# Install trivy

apt-get install wget gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install trivy
trivy --version


# Install kubectl

curl -LO https://dl.k8s.io/release/v1.36.5/bin/linux/amd64/kubectl
curl -LO https://dl.k8s.io/release/v1.36.5/bin/linux/amd64/kubectl.sha256
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client