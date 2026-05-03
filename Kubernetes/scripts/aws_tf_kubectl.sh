#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y

echo "📦 Installing dependencies..."
sudo apt install -y curl unzip gnupg software-properties-common ca-certificates

# =========================================================
# ☁️ AWS CLI v2
# =========================================================
echo "☁️ Installing AWS CLI..."

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update

echo "✅ AWS CLI Installed:"
aws --version

# =========================================================
# ☸️ kubectl
# =========================================================
echo "☸️ Installing kubectl..."

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "✅ kubectl Installed:"
kubectl version --client

# =========================================================
# 🏗 Terraform (FIXED)
# =========================================================
echo "🏗 Installing Terraform..."

# Remove broken repo (your error fix)
sudo rm -f /etc/apt/sources.list.d/hashicorp.list

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# FIX: use jammy instead of resolute
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com jammy main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y terraform

echo "✅ Terraform Installed:"
terraform version

# =========================================================
# ☁️ eksctl
# =========================================================
echo "☁️ Installing eksctl..."

curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin

echo "✅ eksctl Installed:"
eksctl version

# =========================================================
# 🎉 FINAL STATUS
# =========================================================
echo "🎉 ALL TOOLS INSTALLED SUCCESSFULLY!"

echo "-----------------------------------"
echo "AWS CLI:"
aws --version

echo "kubectl:"
kubectl version --client

echo "Terraform:"
terraform version

echo "eksctl:"
eksctl version

echo "-----------------------------------"